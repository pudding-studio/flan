import 'package:flutter/material.dart';
import '../../models/character/character.dart';
import '../../models/character/cover_image.dart';
import '../../models/character/persona.dart';
import '../../models/character/start_scenario.dart';
import '../../database/database_helper.dart';
import '../../models/chat/chat_room.dart';
import '../chat/chat_room_screen.dart';
import 'character_edit_screen.dart';
import '../../widgets/character/character_tag_chip.dart';

class CharacterViewScreen extends StatefulWidget {
  final int characterId;

  const CharacterViewScreen({
    super.key,
    required this.characterId,
  });

  @override
  State<CharacterViewScreen> createState() => _CharacterViewScreenState();
}

class _CharacterViewScreenState extends State<CharacterViewScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;

  Character? _character;
  List<CoverImage> _coverImages = [];
  List<Persona> _personas = [];
  List<StartScenario> _startScenarios = [];
  bool _isLoading = true;
  bool _hasChanges = false;

  int? _selectedPersonaIndex;
  int? _selectedScenarioIndex;

  @override
  void initState() {
    super.initState();
    _loadCharacterData();
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

      final messages = await _db.readChatMessagesByChatRoom(chatRoomId);
      if (messages.isEmpty) {
        await _db.deleteChatRoom(chatRoomId);
      }
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButton<int>(
        value: _selectedPersonaIndex,
        isExpanded: true,
        underline: const SizedBox(),
        isDense: true,
        items: List.generate(
          _personas.length,
          (index) => DropdownMenuItem<int>(
            value: index,
            child: Text(
              _personas[index].name,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
        onChanged: (int? newValue) {
          setState(() {
            _selectedPersonaIndex = newValue;
          });
        },
      ),
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
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            persona.content!,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildStartScenarioDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButton<int>(
        value: _selectedScenarioIndex,
        isExpanded: true,
        underline: const SizedBox(),
        isDense: true,
        items: List.generate(
          _startScenarios.length,
          (index) => DropdownMenuItem<int>(
            value: index,
            child: Text(
              _startScenarios[index].name,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
        onChanged: (int? newValue) {
          setState(() {
            _selectedScenarioIndex = newValue;
          });
        },
      ),
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
          Text(
            '시작 상황',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
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
          Text(
            '시작 메시지',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
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

    final keywords = _character!.tags;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.of(context).pop(_hasChanges);
        }
      },
      child: Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, _hasChanges),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: _navigateToEdit,
            tooltip: '편집',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 표지 이미지
                _buildCoverImage(),
                const SizedBox(height: 24),

                // 캐릭터 이름
                Text(
                  _character!.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 20),

                // 한 줄 소개
                if (_character!.creatorNotes != null && _character!.creatorNotes!.isNotEmpty) ...[
                  Text(
                    '한 줄 소개',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
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
                  Text(
                    '키워드',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
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
                  Text(
                    '페르소나',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  _buildPersonaDropdown(),
                  _buildSelectedPersonaContent(),
                  const SizedBox(height: 24),
                ],

                // 시작 설정 섹션
                if (_startScenarios.isNotEmpty) ...[
                  Text(
                    '시작 설정',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
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
              child: FilledButton.icon(
                onPressed: _createNewChat,
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('새 채팅'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}
