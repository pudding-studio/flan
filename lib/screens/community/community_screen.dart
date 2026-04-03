import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../database/database_helper.dart';
import '../../models/character/character.dart';
import '../../models/character/start_scenario.dart';
import '../../models/chat/chat_message.dart';
import '../../models/chat/chat_room.dart';
import '../../models/chat/chat_summary.dart';
import '../../models/community/community_post.dart';
import '../../models/community/community_comment.dart';
import '../../models/chat/chat_model.dart';
import '../../models/chat/unified_model.dart';
import '../../providers/community_model_provider.dart';
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
  List<StartScenario> _startScenarios = [];
  List<ChatSummary> _chatSummaries = [];
  List<ChatMessage> _recentMessages = [];
  List<CommunityPost> _posts = [];
  bool _isLoading = true;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      _db.readCharacter(widget.characterId),
      _db.readChatRoom(widget.chatRoomId),
      _db.readStartScenarios(widget.characterId),
      _db.getChatSummaries(widget.chatRoomId),
      _db.readRecentAssistantMessages(widget.chatRoomId, 3),
      _db.readCommunityPosts(widget.characterId),
    ]);
    if (!mounted) return;
    setState(() {
      _character = results[0] as Character?;
      _chatRoom = results[1] as ChatRoom?;
      _startScenarios = results[2] as List<StartScenario>;
      final allSummaries = results[3] as List<ChatSummary>;
      _chatSummaries = allSummaries.length > 5 ? allSummaries.sublist(allSummaries.length - 5) : allSummaries;
      _recentMessages = results[4] as List<ChatMessage>;
      _posts = results[5] as List<CommunityPost>;
      _isLoading = false;
    });
  }

  String _buildWorldviewText() {
    final parts = <String>[];

    if (_character?.description?.isNotEmpty == true) {
      parts.add('## 세계관 설명\n${_character!.description}');
    }

    for (final s in _startScenarios) {
      if (s.startSetting?.isNotEmpty == true) {
        parts.add('## 시나리오: ${s.name}\n${s.startSetting}');
      }
    }

    if (_chatRoom?.summary.isNotEmpty == true) {
      parts.add('## 채팅 요약\n${_chatRoom!.summary}');
    }

    if (_chatSummaries.isNotEmpty) {
      final summaryText = _chatSummaries.map((s) => s.summaryContent).join('\n\n');
      parts.add('## 세부 요약\n$summaryText');
    }

    if (_recentMessages.isNotEmpty) {
      final recentText = _recentMessages.map((m) => m.content).join('\n\n---\n\n');
      parts.add('## 최근 대화 내용\n$recentText');
    }

    return parts.join('\n\n');
  }

  Future<void> _regenerate() async {
    final worldview = _buildWorldviewText();
    if (worldview.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('캐릭터 설명 또는 요약 내용을 먼저 작성해주세요.')),
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      final model = context.read<CommunityModelProvider>().selectedModel;
      final now = DateTime.now();
      final nowStr =
          '${now.year}년 ${now.month}월 ${now.day}일 ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      final systemPrompt = await rootBundle.loadString(
        'assets/defaults/community_prompts/community_generate.txt',
      );

      final userMessage =
          '현재 시각: $nowStr\n\n'
          '아래 세계관과 채팅 요약을 바탕으로 커뮤니티 게시글을 생성해주세요.\n\n'
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

      final parsed = CommunityParser.parse(response.text, characterId: widget.characterId);
      for (final post in parsed) {
        final postId = await _db.createCommunityPost(post);
        for (final comment in post.comments) {
          await _db.createCommunityComment(CommunityComment(
            postId: postId,
            author: comment.author,
            time: comment.time,
            content: comment.content,
          ));
        }
      }

      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('생성 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  void _showWritePost() {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();

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
            Text('게시글 작성',
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(
                hintText: '제목',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: contentCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: '내용',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  final title = titleCtrl.text.trim();
                  final content = contentCtrl.text.trim();
                  if (title.isEmpty || content.isEmpty) return;
                  Navigator.pop(ctx);
                  await _submitPost(title: title, content: content);
                },
                child: const Text('등록'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitPost({required String title, required String content}) async {
    setState(() => _isGenerating = true);
    try {
      final now = DateTime.now();
      final post = CommunityPost(
        characterId: widget.characterId,
        author: '나',
        title: title,
        time: now,
        content: content,
      );
      final postId = await _db.createCommunityPost(post);
      await _generatePostReplies(postId: postId, title: title, content: content);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('등록 실패: $e')));
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  void _showWriteComment(CommunityPost post) {
    final contentCtrl = TextEditingController();

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
            Text('댓글 작성',
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
              controller: contentCtrl,
              maxLines: 3,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: '댓글 내용',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  final content = contentCtrl.text.trim();
                  if (content.isEmpty) return;
                  Navigator.pop(ctx);
                  await _submitComment(post: post, content: content);
                },
                child: const Text('등록'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitComment({required CommunityPost post, required String content}) async {
    setState(() => _isGenerating = true);
    try {
      final now = DateTime.now();
      final userComment = CommunityComment(
        postId: post.id!,
        author: '나',
        time: now,
        content: content,
      );
      await _db.createCommunityComment(userComment);

      // Reload current comments to pass as context to AI
      final updatedPost = (await _db.readCommunityPosts(widget.characterId))
          .firstWhere((p) => p.id == post.id);
      await _generateCommentReplies(post: updatedPost);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('등록 실패: $e')));
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _generatePostReplies({
    required int postId,
    required String title,
    required String content,
  }) async {
    final model = context.read<CommunityModelProvider>().selectedModel;
    final systemPrompt = await rootBundle.loadString(
      'assets/defaults/community_prompts/post_replies.txt',
    );
    final now = DateTime.now();
    final nowStr = _nowString(now);
    final worldview = _buildWorldviewText();

    final userMessage =
        '현재 시각: $nowStr\n\n'
        '${worldview.isNotEmpty ? '## 세계관\n$worldview\n\n' : ''}'
        '## 게시글\n제목: $title\n내용: $content';

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

    final comments = CommunityParser.parseComments(response.text, postId: postId);
    for (final c in comments) {
      await _db.createCommunityComment(c);
    }
  }

  Future<void> _generateCommentReplies({required CommunityPost post}) async {
    final model = context.read<CommunityModelProvider>().selectedModel;
    final systemPrompt = await rootBundle.loadString(
      'assets/defaults/community_prompts/comment_replies.txt',
    );
    final now = DateTime.now();
    final nowStr = _nowString(now);
    final worldview = _buildWorldviewText();

    final existingComments = post.comments.map((c) {
      return '  - ${c.author} (${_formatDate(c.time)}): ${c.content}';
    }).join('\n');

    final userMessage =
        '현재 시각: $nowStr\n\n'
        '${worldview.isNotEmpty ? '## 세계관\n$worldview\n\n' : ''}'
        '## 게시글\n제목: ${post.title}\n내용: ${post.content}\n\n'
        '## 기존 댓글\n$existingComments';

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

    final comments = CommunityParser.parseComments(response.text, postId: post.id!);
    for (final c in comments) {
      await _db.createCommunityComment(c);
    }
  }

  String _nowString(DateTime now) =>
      '${now.year}년 ${now.month}월 ${now.day}일 '
      '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final secondary = Theme.of(context).colorScheme.secondary;
    final onSecondary = Theme.of(context).colorScheme.onSecondary;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: secondary,
        foregroundColor: onSecondary,
        iconTheme: IconThemeData(color: onSecondary),
        title: Text('커뮤니티', style: TextStyle(color: onSecondary)),
        actions: [
          if (_isGenerating)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: onSecondary),
              ),
            )
          else
            IconButton(
              icon: Icon(Icons.refresh, color: onSecondary),
              tooltip: '커뮤니티 글 생성',
              onPressed: _regenerate,
            ),
          IconButton(
            icon: Icon(Icons.menu, color: onSecondary),
            tooltip: '설정',
            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
          ),
        ],
      ),
      endDrawer: _buildModelDrawer(),
      floatingActionButton: _isGenerating
          ? null
          : FloatingActionButton(
              backgroundColor: Theme.of(context).colorScheme.secondary,
              foregroundColor: Theme.of(context).colorScheme.onSecondary,
              onPressed: _showWritePost,
              child: const Icon(Icons.edit),
            ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _posts.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _posts.length,
                  itemBuilder: (context, i) => _buildPostCard(_posts[i]),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.forum_outlined,
              size: 64, color: Theme.of(context).colorScheme.outlineVariant),
          const SizedBox(height: 16),
          Text('아직 게시글이 없습니다',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  )),
          const SizedBox(height: 8),
          Text('재생성 버튼을 눌러 커뮤니티를 생성해보세요',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  )),
        ],
      ),
    );
  }

  Widget _buildPostCard(CommunityPost post) {
    final secondaryContainer = Theme.of(context).colorScheme.secondaryContainer;
    final onSecondaryContainer = Theme.of(context).colorScheme.onSecondaryContainer;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Card(
        color: Theme.of(context).colorScheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
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
                    '댓글 달기',
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
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
    final selectableProviders = ChatModelProvider.values
        .where((p) => p != ChatModelProvider.all)
        .toList();

    return Drawer(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Consumer<CommunityModelProvider>(
            builder: (context, provider, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '사용 모델',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 16),
                _buildSettingRow(
                  label: '제조사',
                  child: CommonDropdownButton<ChatModelProvider>(
                    value: provider.selectedProvider,
                    items: selectableProviders,
                    onChanged: (p) { if (p != null) provider.setProvider(p); },
                    labelBuilder: (p) => p.displayName,
                    size: CommonDropdownButtonSize.xsmall,
                  ),
                ),
                const SizedBox(height: 8),
                _buildSettingRow(
                  label: '모델',
                  child: CommonDropdownButton<UnifiedModel>(
                    value: provider.selectedModel,
                    items: provider.availableModels,
                    onChanged: (m) { if (m != null) provider.setModel(m); },
                    labelBuilder: (m) => m.displayName,
                    size: CommonDropdownButtonSize.xsmall,
                  ),
                ),
              ],
            ),
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
    return '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';
  }
}
