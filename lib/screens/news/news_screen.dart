import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../database/database_helper.dart';
import '../../models/character/character.dart';
import '../../models/character/start_scenario.dart';
import '../../models/chat/chat_room.dart';
import '../../models/chat/chat_summary.dart';
import '../../models/chat/agent_entry.dart';
import '../../models/news/news_article.dart';
import '../../models/chat/model_preset.dart';
import '../../models/chat/unified_model.dart';
import '../../providers/chat_model_provider.dart';
import '../../providers/community_model_provider.dart';
import '../../providers/localization_provider.dart';
import '../../services/ai_service.dart';
import '../../utils/date_formatter.dart';
import '../../utils/news_parser.dart';

class NewsScreen extends StatefulWidget {
  final int characterId;
  final int chatRoomId;

  const NewsScreen({
    super.key,
    required this.characterId,
    required this.chatRoomId,
  });

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final AiService _aiService = AiService();

  Character? _character;
  ChatRoom? _chatRoom;
  StartScenario? _selectedScenario;
  List<ChatSummary> _chatSummaries = [];
  List<NewsArticle> _articles = [];
  bool _isLoading = true;
  bool _isGenerating = false;

  final Set<int> _newArticleIds = {};

  static const _allTopics = ['politics', 'society', 'entertainment', 'economy', 'culture'];
  static const _allTones = ['positive', 'negative', 'neutral'];

  static const _topicColors = {
    'politics': Colors.red,
    'society': Colors.blue,
    'entertainment': Colors.pink,
    'economy': Colors.green,
    'culture': Colors.purple,
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool showLoading = true}) async {
    if (showLoading) setState(() => _isLoading = true);
    final results = await Future.wait([
      _db.readCharacter(widget.characterId),
      _db.readChatRoom(widget.chatRoomId),
      _db.getChatSummaries(widget.chatRoomId),
      _db.readNewsArticles(widget.chatRoomId),
    ]);
    if (!mounted) return;
    final chatRoom = results[1] as ChatRoom?;
    StartScenario? scenario;
    if (chatRoom?.selectedStartScenarioId != null) {
      scenario = await _db.readStartScenario(chatRoom!.selectedStartScenarioId!);
    }
    if (!mounted) return;
    setState(() {
      _character = results[0] as Character?;
      _chatRoom = chatRoom;
      _selectedScenario = scenario;
      final allSummaries = results[2] as List<ChatSummary>;
      _chatSummaries = allSummaries.length > 5 ? allSummaries.sublist(allSummaries.length - 5) : allSummaries;
      _articles = results[3] as List<NewsArticle>;
      _isLoading = false;
    });
  }

  Future<UnifiedModel> _getModel() async {
    final communityProvider = context.read<CommunityModelProvider>();
    final chatProvider = context.read<ChatModelSettingsProvider>();
    return ModelPreset.resolveModel(
      featureInitialized: communityProvider.initialized,
      preset: communityProvider.modelPreset,
      customModel: communityProvider.selectedModel,
      chatProvider: chatProvider,
    );
  }

  String _buildWorldviewText() {
    final parts = <String>[];

    if (_character?.description?.isNotEmpty == true) {
      parts.add('## Worldview Description\n${_character!.description}');
    }

    if (_selectedScenario?.startSetting?.isNotEmpty == true) {
      parts.add('## Scenario: ${_selectedScenario!.name}\n${_selectedScenario!.startSetting}');
    }

    if (_chatRoom?.summary.isNotEmpty == true) {
      parts.add('## Chat Summary\n${_chatRoom!.summary}');
    }

    if (_chatSummaries.isNotEmpty) {
      final summaryText = _chatSummaries.map((s) => s.summaryContent).join('\n\n');
      parts.add('## Detailed Summaries\n$summaryText');
    }

    return parts.join('\n\n');
  }

  Future<void> _regenerate() async {
    final worldview = _buildWorldviewText();
    if (worldview.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).communityNeedDescription)),
      );
      return;
    }

    final outputLanguage = context.read<LocalizationProvider>().effectiveAiLanguageName;
    _newArticleIds.clear();
    setState(() => _isGenerating = true);

    try {
      final model = await _getModel();
      final nowStr = DateFormatter.formatPromptDateTime(DateTime.now());

      // Step 1: Generate general articles for 2 random topics
      final topics = List<String>.from(_allTopics)..shuffle();
      final selectedTopics = topics.take(2).toList();

      var systemPrompt = (await rootBundle.loadString(
        'assets/defaults/news_prompts/news_generate.txt',
      )).replaceAll('{{output_language}}', outputLanguage);

      String latestArticleInfo = '';
      if (_articles.isNotEmpty) {
        final latestStr = DateFormatter.formatPromptDateTime(_articles.first.time);
        latestArticleInfo = '\nBase time (generate only after this time): $latestStr\n';
      }

      String previousNews = '';
      if (_articles.isNotEmpty) {
        final recent = _articles.take(10).map((a) => '- [${a.topic}] ${a.title}').join('\n');
        previousNews = '\n## Previously Published Articles (DO NOT repeat these topics or similar angles)\n$recent\n';
      }

      final userMessage =
          'Current time: $nowStr\n$latestArticleInfo\n'
          'Topics: ${selectedTopics.join(', ')}\n\n'
          '$previousNews\n'
          'Based on the worldview and chat summary below, generate newspaper articles.\n\n'
          '$worldview';

      final response = await _aiService.sendMessage(
        systemPrompt: systemPrompt,
        contents: [
          {
            'role': 'user',
            'parts': [{'text': userMessage}],
          }
        ],
        model: model,
        characterId: widget.characterId,
        chatRoomId: widget.chatRoomId,
        logType: 'news',
      );

      final parsed = NewsParser.parse(response.text, chatRoomId: widget.chatRoomId);
      for (final article in parsed) {
        final articleId = await _db.createNewsArticle(article);
        _newArticleIds.add(articleId);
      }

      // Step 2: Generate event-based articles
      await _generateEventArticles(model, nowStr, latestArticleInfo, worldview, outputLanguage);

      await _load(showLoading: false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).communityGenerateFailed(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _generateEventArticles(
    UnifiedModel model,
    String nowStr,
    String latestArticleInfo,
    String worldview,
    String outputLanguage,
  ) async {
    final events = await _db.getAgentEntries(
      widget.chatRoomId,
      type: AgentEntryType.event,
    );
    if (events.isEmpty) return;

    final coveredIds = await _db.getNewsArticleAgentEntryIds(widget.chatRoomId);
    final uncovered = events.where((e) => e.id != null && !coveredIds.contains(e.id)).toList();
    if (uncovered.isEmpty) return;

    // Limit to 3 most recent uncovered events
    final toProcess = uncovered.length > 3 ? uncovered.sublist(uncovered.length - 3) : uncovered;

    final eventSystemPrompt = (await rootBundle.loadString(
      'assets/defaults/news_prompts/news_event_generate.txt',
    )).replaceAll('{{output_language}}', outputLanguage);

    for (final event in toProcess) {
      final tones = List<String>.from(_allTones)..shuffle();
      final selectedTones = tones.take(2).toList();

      final eventMessage =
          'Current time: $nowStr\n$latestArticleInfo\n'
          'Tones: ${selectedTones.join(', ')}\n\n'
          '## Event\n${event.toReadableText()}\n\n'
          '$worldview';

      final eventResponse = await _aiService.sendMessage(
        systemPrompt: eventSystemPrompt,
        contents: [
          {
            'role': 'user',
            'parts': [{'text': eventMessage}],
          }
        ],
        model: model,
        characterId: widget.characterId,
        chatRoomId: widget.chatRoomId,
        logType: 'news',
      );

      final eventArticles = NewsParser.parse(
        eventResponse.text,
        chatRoomId: widget.chatRoomId,
        agentEntryId: event.id,
      );
      for (final article in eventArticles) {
        final articleId = await _db.createNewsArticle(article);
        _newArticleIds.add(articleId);
      }
    }
  }

  Future<void> _deleteArticle(NewsArticle article) async {
    if (article.id == null) return;
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.newsArticleDeleteTitle),
        content: Text(l10n.newsArticleDeleteContent),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.commonCancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.commonDelete)),
        ],
      ),
    );
    if (confirmed == true) {
      await _db.deleteNewsArticle(article.id!);
      await _load(showLoading: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final secondary = Theme.of(context).colorScheme.secondary;
    final onSecondary = Theme.of(context).colorScheme.onSecondary;

    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: secondary,
        foregroundColor: onSecondary,
        iconTheme: IconThemeData(color: onSecondary),
        title: Text(
          'News',
          style: TextStyle(color: onSecondary),
        ),
        actions: [
          if (kIsWeb)
            IconButton(
              icon: Icon(Icons.refresh, color: onSecondary),
              tooltip: l10n.newsRefreshTooltip,
              onPressed: _isGenerating ? null : _regenerate,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_isGenerating)
                  const LinearProgressIndicator(),
                Expanded(
                  child: _webScrollWrapper(
                    RefreshIndicator(
                      onRefresh: _regenerate,
                      child: _articles.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemCount: _articles.length,
                              itemBuilder: (context, i) => _buildArticleCard(_articles[i]),
                            ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  /// On web, wraps the scrollable in a ScrollConfiguration that treats mouse
  /// pointers as drag devices, so desktop users can trigger the pull-to-refresh
  /// gesture by click-dragging. On native platforms this is a no-op passthrough
  /// to keep the existing touch UX untouched.
  Widget _webScrollWrapper(Widget child) {
    if (!kIsWeb) return child;
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.trackpad,
          PointerDeviceKind.stylus,
        },
      ),
      child: child,
    );
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.3),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.newspaper_outlined,
                  size: 64, color: Theme.of(context).colorScheme.outlineVariant),
              const SizedBox(height: 16),
              Text(l10n.newsEmptyTitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      )),
              const SizedBox(height: 8),
              Text(l10n.newsEmptySubtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildArticleCard(NewsArticle article) {
    final l10n = AppLocalizations.of(context);
    final isNew = article.id != null && _newArticleIds.contains(article.id);
    final topicColor = _topicColors[article.topic] ?? Colors.grey;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Card(
        color: isNew
            ? Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.1)
            : Theme.of(context).colorScheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isNew
                ? Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.5)
                : Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: topicColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _topicDisplayName(article.topic, l10n),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: topicColor,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    DateFormatter.formatDateTime(article.time),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => _deleteArticle(article),
                    borderRadius: BorderRadius.circular(4),
                    child: Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                article.title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                article.content,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  article.author,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _topicDisplayName(String topic, AppLocalizations l10n) {
    switch (topic) {
      case 'politics': return l10n.newsTopicPolitics;
      case 'society': return l10n.newsTopicSociety;
      case 'entertainment': return l10n.newsTopicEntertainment;
      case 'economy': return l10n.newsTopicEconomy;
      case 'culture': return l10n.newsTopicCulture;
      default: return topic;
    }
  }

}
