import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/character/character.dart';
import '../../models/character/cover_image.dart';
import '../../models/character/persona.dart';
import '../../models/character/start_scenario.dart';
import '../../database/database_helper.dart';
import '../../models/chat/chat_room.dart';
import '../../models/chat/chat_room_summary.dart';
import '../chat/chat_room_screen.dart';
import 'character_edit_screen.dart';
import '../../widgets/character/character_tag_chip.dart';
import '../../widgets/common/common_button.dart';
import '../../widgets/common/common_title_medium.dart';
import '../../widgets/common/common_appbar.dart';
import '../../widgets/chat/chat_room_card.dart';
import '../../utils/common_dialog.dart';
import '../../widgets/common/common_dropdown_button.dart';
import '../../widgets/common/common_edit_text.dart';
import '../../utils/metadata_parser.dart';

class CharacterViewScreen extends StatefulWidget {
  final int characterId;

  const CharacterViewScreen({
    super.key,
    required this.characterId,
  });

  @override
  State<CharacterViewScreen> createState() => _CharacterViewScreenState();
}

class _CharacterViewScreenState extends State<CharacterViewScreen> with SingleTickerProviderStateMixin {
  final DatabaseHelper _db = DatabaseHelper.instance;
  late TabController _tabController;

  Character? _character;
  List<CoverImage> _coverImages = [];
  List<Persona> _personas = [];
  List<StartScenario> _startScenarios = [];
  List<ChatRoomSummary> _chatRooms = [];
  bool _isLoading = true;
  bool _hasChanges = false;

  int? _selectedPersonaIndex;
  int? _selectedScenarioIndex;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCharacterData();
    _loadChatRooms();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCharacterData() async {
    setState(() => _isLoading = true);

    try {
      final character = await _db.readCharacter(widget.characterId);
      final coverImages = await _db.readCoverImages(widget.characterId);
      final personas = await _db.readPersonas(widget.characterId);
      final startScenarios = await _db.readStartScenarios(widget.characterId);

      setState(() {
        _character = character;
        _coverImages = coverImages;
        _personas = personas;
        _startScenarios = startScenarios;
        // 페르소나가 있으면 첫 번째를 기본 선택
        _selectedPersonaIndex = personas.isNotEmpty ? 0 : null;
        // 시작 설정이 있으면 첫 번째를 기본 선택
        _selectedScenarioIndex = startScenarios.isNotEmpty ? 0 : null;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading character data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadChatRooms() async {
    try {
      final summaries = await _db.readChatRoomSummaries(characterId: widget.characterId);

      setState(() {
        _chatRooms = summaries;
      });
    } catch (e) {
      debugPrint('Error loading chat rooms: $e');
    }
  }

  Future<void> _navigateToEdit() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => CharacterEditScreen(
          characterId: widget.characterId,
        ),
      ),
    );

    if (result == true) {
      _hasChanges = true;
      _loadCharacterData();
    }
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return '오늘';
    } else if (difference.inDays == 1) {
      return '어제';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks주 전';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months개월 전';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years년 전';
    }
  }

  Future<void> _showRenameChatRoomDialog(ChatRoom chatRoom) async {
    final controller = TextEditingController(text: chatRoom.name);

    try {
      final result = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('채팅방 이름 수정'),
          content: CommonEditText(
            controller: controller,
            hintText: '채팅방 이름',
            size: CommonEditTextSize.medium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                final newName = controller.text.trim();
                if (newName.isEmpty) {
                  Navigator.pop(context, null);
                } else {
                  Navigator.pop(context, newName);
                }
              },
              child: const Text('확인'),
            ),
          ],
        ),
      );

      if (result != null && result.isNotEmpty && result != chatRoom.name) {
        final updatedChatRoom = chatRoom.copyWith(
          name: result,
        );
        await _db.updateChatRoom(updatedChatRoom);
        _loadChatRooms();
      }
    } catch (e) {
      debugPrint('Error renaming chat room: $e');
      if (!mounted) return;
      CommonDialog.showSnackBar(
        context: context,
        message: '채팅방 이름 수정 중 오류가 발생했습니다',
      );
    } finally {
      controller.dispose();
    }
  }

  Future<void> _showDeleteChatRoomDialog(ChatRoom chatRoom) async {
    final confirmed = await CommonDialog.showConfirmation(
      context: context,
      title: '채팅방 삭제',
      content: '\'${chatRoom.name}\' 채팅방을 삭제하시겠습니까?\n모든 메시지가 삭제됩니다.',
      confirmText: '삭제',
      isDestructive: true,
    );

    if (confirmed == true) {
      try {
        await _db.deleteChatRoom(chatRoom.id!);
        _loadChatRooms();
        if (!mounted) return;
        CommonDialog.showSnackBar(
          context: context,
          message: '채팅방이 삭제되었습니다',
        );
      } catch (e) {
        debugPrint('Error deleting chat room: $e');
        if (!mounted) return;
        CommonDialog.showSnackBar(
          context: context,
          message: '채팅방 삭제 중 오류가 발생했습니다',
        );
      }
    }
  }

  Future<void> _createNewChat() async {
    if (_character == null) return;

    try {
      final selectedPrompt = await _db.readSelectedChatPrompt();

      final existingRooms = await _db.database.then((db) async {
        final List<Map<String, dynamic>> maps = await db.query(
          'chat_rooms',
          where: 'character_id = ?',
          whereArgs: [widget.characterId],
        );
        return maps.map((map) => ChatRoom.fromMap(map)).toList();
      });

      int roomNumber = 1;
      final baseName = _character!.name;
      while (existingRooms.any((room) => room.name == '${baseName}_$roomNumber')) {
        roomNumber++;
      }

      final prefs = await SharedPreferences.getInstance();
      final chatRoom = ChatRoom(
        characterId: widget.characterId,
        name: '${baseName}_$roomNumber',
        selectedChatPromptId: selectedPrompt?.id,
        selectedPersonaId: _selectedPersonaIndex != null
            ? _personas[_selectedPersonaIndex!].id
            : null,
        selectedStartScenarioId: _selectedScenarioIndex != null
            ? _startScenarios[_selectedScenarioIndex!].id
            : null,
        pinMode: prefs.getString('default_pin_mode') ?? 'auto',
        autoPinByDate: prefs.getBool('default_auto_pin_by_date') ?? false,
        autoPinByLocation: prefs.getBool('default_auto_pin_by_location') ?? false,
        autoPinByAi: prefs.getBool('default_auto_pin_by_ai') ?? false,
        autoPinByMessageCount: prefs.getBool('default_auto_pin_by_message_count_enabled') ?? true
            ? (prefs.getInt('default_auto_pin_by_message_count') ?? 10)
            : null,
      );

      final chatRoomId = await _db.createChatRoom(chatRoom);

      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatRoomScreen(
            chatRoomId: chatRoomId,
          ),
        ),
      );

      final lastMessage = await _db.readLastChatMessage(chatRoomId);
      if (lastMessage == null) {
        await _db.deleteChatRoom(chatRoomId);
      }

      // 채팅방 리스트 새로고침
      _loadChatRooms();
    } catch (e) {
      debugPrint('Error creating chat: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('채팅방 생성 중 오류가 발생했습니다'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildCoverImage() {
    CoverImage? selectedCover;

    if (_character?.selectedCoverImageId != null && _coverImages.isNotEmpty) {
      selectedCover = _coverImages.firstWhere(
        (img) => img.id == _character!.selectedCoverImageId,
        orElse: () => _coverImages.first,
      );
    } else if (_coverImages.isNotEmpty) {
      selectedCover = _coverImages.first;
    }

    if (selectedCover == null || selectedCover.imageData == null) {
      return AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.person_outline,
            size: 80,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 1,
        child: Image.memory(
          selectedCover.imageData!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Icon(
                Icons.broken_image_outlined,
                size: 80,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPersonaDropdown() {
    return CommonDropdownButton<int>(
      value: _selectedPersonaIndex,
      items: List.generate(_personas.length, (index) => index),
      onChanged: (int? newValue) {
        setState(() {
          _selectedPersonaIndex = newValue;
        });
      },
      labelBuilder: (index) => _personas[index].name,
    );
  }

  Widget _buildSelectedPersonaContent() {
    if (_selectedPersonaIndex == null) {
      return const SizedBox();
    }

    final persona = _personas[_selectedPersonaIndex!];

    if (persona.content == null || persona.content!.isEmpty) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          persona.content!,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  Widget _buildStartScenarioDropdown() {
    return CommonDropdownButton<int>(
      value: _selectedScenarioIndex,
      items: List.generate(_startScenarios.length, (index) => index),
      onChanged: (int? newValue) {
        setState(() {
          _selectedScenarioIndex = newValue;
        });
      },
      labelBuilder: (index) => _startScenarios[index].name,
    );
  }

  Widget _buildSelectedScenarioContent() {
    if (_selectedScenarioIndex == null) {
      return const SizedBox();
    }

    final scenario = _startScenarios[_selectedScenarioIndex!];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        if (scenario.startSetting != null && scenario.startSetting!.isNotEmpty) ...[
          const CommonTitleMedium(text: '시작 상황'),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              scenario.startSetting!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (scenario.startMessage != null && scenario.startMessage!.isNotEmpty) ...[
          const CommonTitleMedium(text: '시작 메시지'),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              scenario.startMessage!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_character == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: Text('캐릭터를 불러올 수 없습니다'),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.of(context).pop(_hasChanges);
        }
      },
      child: Scaffold(
      appBar: CommonAppBar(
        title: _character!.name,
        actions: [
          CommonAppBarIconButton(
            icon: Icons.edit_outlined,
            onPressed: _navigateToEdit,
            tooltip: '편집',
            offsetX: 0.0,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Transform.translate(
            offset: const Offset(0, -16),
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: '정보'),
                Tab(text: '채팅'),
              ],
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
              indicatorColor: Theme.of(context).colorScheme.primary,
              indicatorSize: TabBarIndicatorSize.tab,
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 정보 탭
          _buildInfoTab(),
          // 채팅 탭
          _buildChatTab(),
        ],
      ),
      ),
    );
  }

  Widget _buildInfoTab() {
    final keywords = _character!.tags;

    return Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 표지 이미지
                _buildCoverImage(),
                const SizedBox(height: 24),

                // 한 줄 소개
                if (_character!.creatorNotes != null && _character!.creatorNotes!.isNotEmpty) ...[
                  const CommonTitleMedium(text: '한 줄 소개'),
                  const SizedBox(height: 8),
                  Text(
                    _character!.creatorNotes!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 24),
                ],

                // 키워드
                if (keywords.isNotEmpty) ...[
                  const CommonTitleMedium(text: '키워드'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: keywords.map((keyword) => CharacterTagChip(label: keyword)).toList(),
                  ),
                  const SizedBox(height: 24),
                ],

                // 페르소나 섹션
                if (_personas.isNotEmpty) ...[
                  const CommonTitleMedium(text: '페르소나'),
                  const SizedBox(height: 8),
                  _buildPersonaDropdown(),
                  _buildSelectedPersonaContent(),
                  const SizedBox(height: 24),
                ],

                // 시작 설정 섹션
                if (_startScenarios.isNotEmpty) ...[
                  const CommonTitleMedium(text: '시작 설정'),
                  const SizedBox(height: 8),
                  _buildStartScenarioDropdown(),
                  _buildSelectedScenarioContent(),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: CommonButton.filled(
                onPressed: _createNewChat,
                icon: Icons.chat_bubble_outline,
                label: '새 채팅',
              ),
            ),
          ),
        ],
      );
  }

  Widget _buildChatTab() {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth * 0.05;

    if (_chatRooms.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 80,
              color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              '채팅방이 없습니다',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '새 채팅을 시작해보세요',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16.0),
            itemCount: _chatRooms.length,
            separatorBuilder: (context, index) => const SizedBox(height: 20.0),
            itemBuilder: (context, index) {
              final data = _chatRooms[index];
              return GestureDetector(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatRoomScreen(
                        chatRoomId: data.chatRoom.id!,
                      ),
                    ),
                  );
                  _loadChatRooms();
                },
                onLongPress: () {
                  showDialog(
                    context: context,
                    builder: (context) => Dialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data.chatRoom.name,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Divider(),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.edit_outlined),
                              title: const Text('채팅방 이름 수정'),
                              onTap: () {
                                Navigator.pop(context);
                                _showRenameChatRoomDialog(data.chatRoom);
                              },
                            ),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(
                                Icons.delete_outline,
                                color: Theme.of(context).colorScheme.error,
                              ),
                              title: Text(
                                '삭제',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                _showDeleteChatRoomDialog(data.chatRoom);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                child: ChatRoomCard(
                  title: data.chatRoom.name,
                  lastMessage: data.lastMessage != null
                      ? MetadataParser.removeMetadataTags(data.lastMessage!.content)
                      : '메시지가 없습니다',
                  date: _formatDate(data.chatRoom.updatedAt),
                  imageData: data.coverImage?.imageData,
                  messageCount: data.messageCount,
                  tokenCount: data.tokenCount,
                  isEditMode: false,
                  isSelected: false,
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: CommonButton.filled(
              onPressed: _createNewChat,
              icon: Icons.chat_bubble_outline,
              label: '새 채팅',
            ),
          ),
        ),
      ],
    );
  }
}

