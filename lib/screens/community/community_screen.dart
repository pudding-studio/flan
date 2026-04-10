import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../database/database_helper.dart';
import '../../models/character/character.dart';
import '../../models/character/start_scenario.dart';
import '../../models/chat/agent_entry.dart';
import '../../models/chat/chat_message.dart';
import '../../models/chat/chat_room.dart';
import '../../models/chat/chat_summary.dart';
import '../../models/community/community_post.dart';
import '../../models/news/news_article.dart';
import '../../models/community/community_comment.dart';
import '../../models/chat/chat_model.dart';
import '../../models/chat/model_preset.dart';
import '../../models/chat/unified_model.dart';
import '../../providers/chat_model_provider.dart';
import '../../providers/community_model_provider.dart';
import '../../providers/localization_provider.dart';
import '../../services/ai_service.dart';
import '../../utils/community_parser.dart';
import '../../widgets/common/common_dropdown_button.dart';

class CommunityScreen extends StatefulWidget {
  final int characterId;
  final int chatRoomId;

  const CommunityScreen({
    super.key,
    required this.characterId,
    required this.chatRoomId,
  });

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final AiService _aiService = AiService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Character? _character;
  ChatRoom? _chatRoom;
  StartScenario? _selectedScenario;
  List<ChatSummary> _chatSummaries = [];
  List<ChatMessage> _recentMessages = [];
  List<AgentEntry> _agentEntries = [];
  List<NewsArticle> _newsArticles = [];
  List<CommunityPost> _posts = [];
  bool _isLoading = true;
  bool _isGenerating = false;
  bool _isSubmitting = false;

  // Track newly created items for highlighting
  final Set<int> _newPostIds = {};
  final Set<int> _newCommentIds = {};

  // Draft state for retry on failure
  String _draftPostAuthor = '';
  String _draftPostTitle = '';
  String _draftPostContent = '';
  final Map<int, String> _draftCommentAuthor = {};
  final Map<int, String> _draftCommentContent = {};

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
      _db.readRecentAssistantMessages(widget.chatRoomId, 3),
      _db.readCommunityPosts(widget.chatRoomId),
      _db.getAgentEntries(widget.chatRoomId),
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
      _recentMessages = results[3] as List<ChatMessage>;
      _posts = results[4] as List<CommunityPost>;
      _agentEntries = results[5] as List<AgentEntry>;
      _newsArticles = results[6] as List<NewsArticle>;
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

  String _appendCommunitySettings(String systemPrompt, String outputLanguage) {
    if (_character?.communityMood?.isNotEmpty == true) {
      systemPrompt += '\n- Community mood: ${_character!.communityMood}';
    }
    // Use communityLanguage if explicitly set for this world, otherwise use app output language
    final language = (_character?.communityLanguage?.isNotEmpty == true)
        ? _character!.communityLanguage!
        : outputLanguage;
    return systemPrompt.replaceAll('{{output_language}}', language);
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

    if (_agentEntries.isNotEmpty) {
      final entryText = _agentEntries.map((e) => '### ${e.entryType.displayName}: ${e.name}\n${e.toReadableText()}').join('\n\n');
      parts.add('## Agent Entries\n$entryText');
    }

    if (_recentMessages.isNotEmpty) {
      final recentText = _recentMessages.map((m) => m.content).join('\n\n---\n\n');
      parts.add('## Recent Chat Messages (ONLY reference events that occurred in PUBLIC spaces — streets, parks, shops, public buildings, etc. Do NOT reference private or intimate moments.)\n$recentText');
    }

    if (_newsArticles.isNotEmpty) {
      final newsText = _newsArticles.take(10).map((a) => '### [${a.topic}] ${a.title}\n${a.content}').join('\n\n');
      parts.add('## Recent News\n$newsText');
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
    _newPostIds.clear();
    _newCommentIds.clear();
    setState(() => _isGenerating = true);

    try {
      final model = await _getModel();
      final now = DateTime.now();
      final nowStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      var systemPrompt = await rootBundle.loadString(
        'assets/defaults/community_prompts/community_generate.txt',
      );
      systemPrompt = _appendCommunitySettings(systemPrompt, outputLanguage);

      String latestPostInfo = '';
      if (_posts.isNotEmpty) {
        final latestTime = _posts.first.time;
        final latestStr = '${latestTime.year}-${latestTime.month.toString().padLeft(2, '0')}-${latestTime.day.toString().padLeft(2, '0')} ${latestTime.hour.toString().padLeft(2, '0')}:${latestTime.minute.toString().padLeft(2, '0')}';
        latestPostInfo = '\nBase time (generate only after this time): $latestStr\n';
      }

      String previousPosts = '';
      if (_posts.isNotEmpty) {
        final recent = _posts.take(10).map((p) {
          final comments = p.comments.map((c) => '  - ${c.author}: ${c.content}').join('\n');
          return '- [${p.author}] ${p.title}: ${p.content}${comments.isNotEmpty ? '\n$comments' : ''}';
        }).join('\n');
        previousPosts = '\n## Previously Published Posts (DO NOT repeat similar topics or content)\n$recent\n';
      }

      final userMessage =
          'Current time: $nowStr\n$latestPostInfo\n'
          '$previousPosts\n'
          'Based on the worldview and chat summary below, generate community posts.\n\n'
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
        logType: 'community',
      );

      final parsed = CommunityParser.parse(response.text, chatRoomId: widget.chatRoomId);
      for (final post in parsed) {
        final postId = await _db.createCommunityPost(post);
        _newPostIds.add(postId);
        for (final comment in post.comments) {
          final commentId = await _db.createCommunityComment(CommunityComment(
            postId: postId,
            author: comment.author,
            time: comment.time,
            content: comment.content,
          ));
          _newCommentIds.add(commentId);
        }
      }

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

  void _showWritePost() {
    final l10n = AppLocalizations.of(context);
    final authorCtrl = TextEditingController(
        text: _draftPostAuthor.isEmpty ? l10n.communityAnonymous : _draftPostAuthor);
    final titleCtrl = TextEditingController(text: _draftPostTitle);
    final contentCtrl = TextEditingController(text: _draftPostContent);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16, right: 16, top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.communityWritePost,
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: authorCtrl,
              decoration: InputDecoration(
                hintText: l10n.communityNickname,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: titleCtrl,
              decoration: InputDecoration(
                hintText: l10n.communityTitle,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: contentCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: l10n.communityContent,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  final author = authorCtrl.text.trim();
                  final title = titleCtrl.text.trim();
                  final content = contentCtrl.text.trim();
                  if (author.isEmpty || title.isEmpty || content.isEmpty) return;
                  _draftPostAuthor = author;
                  _draftPostTitle = title;
                  _draftPostContent = content;
                  Navigator.pop(ctx);
                  await _submitPost(author: author, title: title, content: content);
                },
                child: Text(l10n.communityRegister),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitPost({required String author, required String title, required String content}) async {
    _newPostIds.clear();
    _newCommentIds.clear();
    setState(() => _isSubmitting = true);
    try {
      final replies = await _generatePostReplies(title: title, content: content);

      final now = DateTime.now();
      final post = CommunityPost(
        chatRoomId: widget.chatRoomId,
        author: author,
        title: title,
        time: now,
        content: content,
      );
      final postId = await _db.createCommunityPost(post);
      _newPostIds.add(postId);
      for (final c in replies) {
        final commentId = await _db.createCommunityComment(CommunityComment(
          postId: postId,
          author: c.author,
          time: c.time,
          content: c.content,
        ));
        _newCommentIds.add(commentId);
      }

      _draftPostAuthor = '';
      _draftPostTitle = '';
      _draftPostContent = '';
      await _load(showLoading: false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).communityRegisterFailed(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showWriteComment(CommunityPost post) {
    final l10n = AppLocalizations.of(context);
    final postId = post.id!;
    final nicknameCtrl = TextEditingController(
        text: _draftCommentAuthor[postId] ?? l10n.communityAnonymous);
    final contentCtrl = TextEditingController(text: _draftCommentContent[postId] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16, right: 16, top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.communityWriteComment,
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(
              post.title,
              style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                    color: Theme.of(ctx).colorScheme.outline,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nicknameCtrl,
              decoration: InputDecoration(
                hintText: l10n.communityNickname,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: contentCtrl,
              maxLines: 3,
              autofocus: true,
              decoration: InputDecoration(
                hintText: l10n.communityCommentContent,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  final nickname = nicknameCtrl.text.trim();
                  final content = contentCtrl.text.trim();
                  if (nickname.isEmpty || content.isEmpty) return;
                  _draftCommentAuthor[postId] = nickname;
                  _draftCommentContent[postId] = content;
                  Navigator.pop(ctx);
                  await _submitComment(post: post, author: nickname, content: content);
                },
                child: Text(l10n.communityRegister),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitComment({required CommunityPost post, required String author, required String content}) async {
    _newPostIds.clear();
    _newCommentIds.clear();
    setState(() => _isSubmitting = true);
    try {
      // Add user comment to post context for AI without saving to DB yet
      final now = DateTime.now();
      final postWithUserComment = CommunityPost(
        id: post.id,
        chatRoomId: post.chatRoomId,
        author: post.author,
        title: post.title,
        time: post.time,
        content: post.content,
        createdAt: post.createdAt,
        comments: [
          ...post.comments,
          CommunityComment(postId: post.id!, author: author, time: now, content: content),
        ],
      );

      final aiReplies = await _generateCommentReplies(post: postWithUserComment);

      // AI succeeded — now save user comment + AI replies to DB
      final userComment = CommunityComment(
        postId: post.id!,
        author: author,
        time: now,
        content: content,
      );
      final userCommentId = await _db.createCommunityComment(userComment);
      _newCommentIds.add(userCommentId);
      for (final c in aiReplies) {
        final commentId = await _db.createCommunityComment(c);
        _newCommentIds.add(commentId);
      }

      _draftCommentAuthor.remove(post.id!);
      _draftCommentContent.remove(post.id!);
      await _load(showLoading: false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).communityRegisterFailed(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<List<CommunityComment>> _generatePostReplies({
    required String title,
    required String content,
  }) async {
    final outputLanguage = context.read<LocalizationProvider>().effectiveAiLanguageName;
    final model = await _getModel();
    var systemPrompt = await rootBundle.loadString(
      'assets/defaults/community_prompts/post_replies.txt',
    );
    systemPrompt = _appendCommunitySettings(systemPrompt, outputLanguage);
    final now = DateTime.now();
    final nowStr = _nowString(now);
    final worldview = _buildWorldviewText();

    final userMessage =
        'Current time: $nowStr\nBase time (generate only after this time): $nowStr\n\n'
        '${worldview.isNotEmpty ? '## Worldview\n$worldview\n\n' : ''}'
        '## Post\nTitle: $title\nContent: $content';

    final response = await _aiService.sendMessage(
      systemPrompt: systemPrompt,
      contents: [
        {'role': 'user', 'parts': [{'text': userMessage}]}
      ],
      model: model,
      characterId: widget.characterId,
      chatRoomId: widget.chatRoomId,
      logType: 'community',
    );

    return CommunityParser.parseComments(response.text, postId: 0);
  }

  Future<List<CommunityComment>> _generateCommentReplies({required CommunityPost post}) async {
    final outputLanguage = context.read<LocalizationProvider>().effectiveAiLanguageName;
    final model = await _getModel();
    var systemPrompt = await rootBundle.loadString(
      'assets/defaults/community_prompts/comment_replies.txt',
    );
    systemPrompt = _appendCommunitySettings(systemPrompt, outputLanguage);
    final now = DateTime.now();
    final nowStr = _nowString(now);
    final worldview = _buildWorldviewText();

    final existingComments = post.comments.map((c) {
      return '  - ${c.author} (${_formatDate(c.time)}): ${c.content}';
    }).join('\n');

    String baseTimeStr = nowStr;
    if (post.comments.isNotEmpty) {
      final latestComment = post.comments.last;
      baseTimeStr = _nowString(latestComment.time);
    }

    final userMessage =
        'Current time: $nowStr\nBase time (generate only after this time): $baseTimeStr\n\n'
        '${worldview.isNotEmpty ? '## Worldview\n$worldview\n\n' : ''}'
        '## Post\nTitle: ${post.title}\nContent: ${post.content}\n\n'
        '## Existing Comments\n$existingComments';

    final response = await _aiService.sendMessage(
      systemPrompt: systemPrompt,
      contents: [
        {'role': 'user', 'parts': [{'text': userMessage}]}
      ],
      model: model,
      characterId: widget.characterId,
      chatRoomId: widget.chatRoomId,
      logType: 'community',
    );

    return CommunityParser.parseComments(response.text, postId: post.id!);
  }

  Future<void> _deleteComment(CommunityComment comment) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.communityCommentDeleteTitle),
        content: Text(l10n.communityCommentDeleteContent),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.commonCancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.commonDelete)),
        ],
      ),
    );
    if (confirmed != true) return;
    await _db.deleteCommunityComment(comment.id!);
    await _load(showLoading: false);
  }

  Future<void> _deletePost(CommunityPost post) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.communityPostDeleteTitle),
        content: Text(l10n.communityPostDeleteContent),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.commonCancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.commonDelete)),
        ],
      ),
    );
    if (confirmed != true) return;
    await _db.deleteCommunityPost(post.id!);
    await _load(showLoading: false);
  }

  Future<void> _toggleFavorite(CommunityPost post) async {
    final newValue = !post.isFavorited;
    await _db.togglePostFavorite(post.id!, newValue);
    await _load(showLoading: false);
  }

  String _nowString(DateTime now) =>
      '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
      '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final secondary = Theme.of(context).colorScheme.secondary;
    final onSecondary = Theme.of(context).colorScheme.onSecondary;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: secondary,
        foregroundColor: onSecondary,
        iconTheme: IconThemeData(color: onSecondary),
        title: Text(
          _character?.communityName?.isNotEmpty == true
              ? _character!.communityName!
              : l10n.communityDefaultName,
          style: TextStyle(color: onSecondary),
        ),
        actions: [
          Transform.translate(
              offset: const Offset(6, 0),
              child: _isSubmitting
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: onSecondary,
                        ),
                      ),
                    )
                  : OutlinedButton(
                onPressed: _isGenerating ? null : _showWritePost,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: _isGenerating ? onSecondary.withValues(alpha: 0.4) : onSecondary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  l10n.communityWritePost,
                  style: TextStyle(
                    color: _isGenerating ? onSecondary.withValues(alpha: 0.4) : onSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          IconButton(
            icon: Icon(Icons.menu, color: onSecondary),
            tooltip: l10n.communitySettingsTooltip,
            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
          ),
        ],
      ),
      endDrawer: _buildModelDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_isGenerating)
                  const LinearProgressIndicator(),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _regenerate,
                    child: _posts.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: _posts.length,
                            itemBuilder: (context, i) => _buildPostCard(_posts[i]),
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
              Icon(Icons.forum_outlined,
                  size: 64, color: Theme.of(context).colorScheme.outlineVariant),
              const SizedBox(height: 16),
              Text(l10n.communityNoPostsTitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      )),
              const SizedBox(height: 8),
              Text(l10n.communityNoPostsSubtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPostCard(CommunityPost post) {
    final secondaryContainer = Theme.of(context).colorScheme.secondaryContainer;
    final onSecondaryContainer = Theme.of(context).colorScheme.onSecondaryContainer;
    final isNewPost = post.id != null && _newPostIds.contains(post.id);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Card(
        color: isNewPost
            ? Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.1)
            : Theme.of(context).colorScheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isNewPost
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
                  InkWell(
                    onTap: () => _toggleFavorite(post),
                    borderRadius: BorderRadius.circular(4),
                    child: Icon(
                      post.isFavorited ? Icons.star : Icons.star_border,
                      size: 18,
                      color: post.favoriteUsed
                          ? Theme.of(context).colorScheme.tertiary
                          : post.isFavorited
                              ? Colors.amber
                              : Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      post.author,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: onSecondaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(post.time),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => _deletePost(post),
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
                post.title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                post.content,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              if (post.comments.isNotEmpty) ...[
                const SizedBox(height: 10),
                Divider(
                  height: 1,
                  color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4),
                ),
                const SizedBox(height: 8),
                ...post.comments.map((c) => _buildComment(c)),
              ],
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: Icon(Icons.comment_outlined,
                      size: 14,
                      color: Theme.of(context).colorScheme.secondary),
                  label: Text(
                    AppLocalizations.of(context).communityCommentLabel,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () => _showWriteComment(post),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComment(CommunityComment comment) {
    final isNewComment = comment.id != null && _newCommentIds.contains(comment.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: isNewComment ? const EdgeInsets.all(6) : EdgeInsets.zero,
      decoration: isNewComment
          ? BoxDecoration(
              color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            )
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.subdirectory_arrow_right,
            size: 14,
            color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.author,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatDate(comment.time),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () => _deleteComment(comment),
                      borderRadius: BorderRadius.circular(4),
                      child: Icon(
                        Icons.delete_outline,
                        size: 14,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ],
                ),
                Text(comment.content, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModelDrawer() {
    final l10n = AppLocalizations.of(context);
    return Drawer(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Consumer<CommunityModelProvider>(
            builder: (context, provider, _) {
              final providerOptions = ProviderOption.buildOptions(provider.customProviders);

              ProviderOption? currentProviderOption;
              if (provider.modelPreset == ModelPreset.custom) {
                currentProviderOption = providerOptions.where(
                  (o) => o.builtInProvider == provider.selectedProvider,
                ).firstOrNull;
                currentProviderOption ??= providerOptions.firstOrNull;
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.communityUsedModelSection,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  _buildSettingRow(
                    label: l10n.communityModelPreset,
                    child: CommonDropdownButton<ModelPreset>(
                      value: provider.modelPreset,
                      items: ModelPreset.values,
                      onChanged: (p) { if (p != null) provider.setModelPreset(p); },
                      labelBuilder: (p) => switch (p) {
                        ModelPreset.primary => l10n.modelPresetPrimary,
                        ModelPreset.secondary => l10n.modelPresetSecondary,
                        ModelPreset.custom => l10n.modelPresetCustom,
                      },
                      size: CommonDropdownButtonSize.xsmall,
                    ),
                  ),
                  if (provider.modelPreset != ModelPreset.custom) ...[
                    const SizedBox(height: 4),
                    Consumer<ChatModelSettingsProvider>(
                      builder: (context, chatProvider, _) => Text(
                        provider.modelPreset == ModelPreset.primary
                            ? chatProvider.primaryModelLabel
                            : chatProvider.subModelLabel,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
                            ),
                      ),
                    ),
                  ],
                  if (provider.modelPreset == ModelPreset.custom) ...[
                    const SizedBox(height: 8),
                    _buildSettingRow(
                      label: l10n.communityProvider,
                      child: CommonDropdownButton<ProviderOption>(
                        value: currentProviderOption,
                        items: providerOptions,
                        onChanged: (option) {
                          if (option == null) return;
                          if (option.isCustom) {
                            // CommunityModelProvider doesn't support custom provider selection yet,
                            // fall back to setting the built-in provider
                            provider.setProvider(ChatModelProvider.custom);
                          } else {
                            provider.setProvider(option.builtInProvider!);
                          }
                        },
                        labelBuilder: (o) => o.displayName,
                        size: CommonDropdownButtonSize.xsmall,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildSettingRow(
                      label: l10n.communityChatModel,
                      child: CommonDropdownButton<UnifiedModel>(
                        value: provider.selectedModel,
                        items: provider.availableModels,
                        onChanged: (m) { if (m != null) provider.setModel(m); },
                        labelBuilder: (m) => m.displayName,
                        size: CommonDropdownButtonSize.xsmall,
                      ),
                    ),
                  ],
                if (_character != null) ...[
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  Text(
                    l10n.communitySettingsSection,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  _buildSettingRow(
                    label: l10n.communityNameLabel,
                    child: Text(
                      _character!.communityName?.isNotEmpty == true
                          ? _character!.communityName!
                          : l10n.communityDefaultName,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  if (_character!.communityMood?.isNotEmpty == true) ...[
                    const SizedBox(height: 8),
                    _buildSettingRow(
                      label: l10n.communityToneLabel,
                      child: Text(
                        _character!.communityMood!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                  if (_character!.communityLanguage?.isNotEmpty == true) ...[
                    const SizedBox(height: 8),
                    _buildSettingRow(
                      label: l10n.communityLanguageLabel,
                      child: Text(
                        _character!.communityLanguage!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ],
              ],
            );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSettingRow({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
        ),
        const SizedBox(height: 4),
        child,
      ],
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
