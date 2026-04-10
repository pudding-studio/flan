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
import '../../services/ai_service.dart';
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

  static const _allTopics = ['정치', '사회', '연예', '경제', '문화'];
  static const _allTones = ['positive', 'negative', 'neutral'];

  static const _topicColors = {
    '정치': Colors.red,
    '사회': Colors.blue,
    '연예': Colors.pink,
    '경제': Colors.green,
    '문화': Colors.purple,
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
    await communityProvider.initialized;
    await chatProvider.initialized;
    switch (communityProvider.modelPreset) {
      case ModelPreset.primary:
        return chatProvider.selectedModel;
      case ModelPreset.secondary:
        return chatProvider.subModel;
      case ModelPreset.custom:
        return communityProvider.selectedModel;
    }
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

    _newArticleIds.clear();
    setState(() => _isGenerating = true);

    try {
      final model = await _getModel();
      final now = DateTime.now();
      final nowStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      // Step 1: Generate general articles for 2 random topics
      final topics = List<String>.from(_allTopics)..shuffle();
      final selectedTopics = topics.take(2).toList();

      var systemPrompt = await rootBundle.loadString(
        'assets/defaults/news_prompts/news_generate.txt',
      );

      String latestArticleInfo = '';
      if (_articles.isNotEmpty) {
        final latestTime = _articles.first.time;
        final latestStr = '${latestTime.year}-${latestTime.month.toString().padLeft(2, '0')}-${latestTime.day.toString().padLeft(2, '0')} ${latestTime.hour.toString().padLeft(2, '0')}:${latestTime.minute.toString().padLeft(2, '0')}';
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
      await _generateEventArticles(model, nowStr, latestArticleInfo, worldview);

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

    final eventSystemPrompt = await rootBundle.loadString(
      'assets/defaults/news_prompts/news_event_generate.txt',
    );

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

    return Scaffold(
      appBar: AppBar(
        backgroundColor: secondary,
        foregroundColor: onSecondary,
        iconTheme: IconThemeData(color: onSecondary),
        title: Text(
          'News',
          style: TextStyle(color: onSecondary),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_isGenerating)
                  const LinearProgressIndicator(),
                Expanded(
                  child: RefreshIndicator(
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
              ],
            ),
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
                    _formatDate(article.time),
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
      case '정치': return l10n.newsTopicPolitics;
      case '사회': return l10n.newsTopicSociety;
      case '연예': return l10n.newsTopicEntertainment;
      case '경제': return l10n.newsTopicEconomy;
      case '문화': return l10n.newsTopicCulture;
      default: return topic;
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
