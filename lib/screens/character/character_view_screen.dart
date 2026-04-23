import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/app_localizations.dart';
import '../../mixins/chat_room_pagination_mixin.dart';
import '../../models/character/character.dart';
import '../../models/character/cover_image.dart';
import '../../models/character/persona.dart';
import '../../models/character/start_scenario.dart';
import '../../models/chat/chat_room.dart';
import '../../services/agent_summary_service.dart';
import '../../utils/chat_room_importer.dart';
import '../chat/chat_room_screen.dart';
import 'character_edit_screen.dart';
import 'tabs/character_info_tab.dart';
import 'tabs/character_chat_tab.dart';
import '../../widgets/common/common_appbar.dart';

class CharacterViewScreen extends StatefulWidget {
  final int characterId;

  const CharacterViewScreen({
    super.key,
    required this.characterId,
  });

  @override
  State<CharacterViewScreen> createState() => _CharacterViewScreenState();
}

class _CharacterViewScreenState extends State<CharacterViewScreen> with SingleTickerProviderStateMixin, ChatRoomPaginationMixin {
  late TabController _tabController;

  Character? _character;
  List<CoverImage> _coverImages = [];
  List<Persona> _personas = [];
  List<StartScenario> _startScenarios = [];
  bool _isLoading = true;
  bool _hasChanges = false;

  int? _selectedPersonaIndex;
  int? _selectedScenarioIndex;

  @override
  int? get paginationCharacterId => widget.characterId;

  @override
  void onChatRoomsLoaded() {
    resolveCoverImages();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCharacterData();
    initPagination();
  }

  @override
  void dispose() {
    disposePagination();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _importChatRoom() async {
    final success =
        await ChatRoomImporter.importToCharacter(context, paginationDb, widget.characterId);
    if (success) loadChatRooms();
  }

  Future<void> _loadCharacterData() async {
    setState(() => _isLoading = true);

    try {
      final character = await paginationDb.readCharacter(widget.characterId);
      final coverImages = await paginationDb.readCoverImages(widget.characterId);
      final personas = await paginationDb.readPersonas(widget.characterId);
      final startScenarios = await paginationDb.readStartScenarios(widget.characterId);

      setState(() {
        _character = character;
        _coverImages = coverImages;
        _personas = personas;
        _startScenarios = startScenarios;
        _selectedPersonaIndex = personas.isNotEmpty ? 0 : null;
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
      final selectedPrompt = await paginationDb.readSelectedChatPrompt();
      final existingRooms = await paginationDb.readChatRoomsByCharacter(widget.characterId);

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
        autoPinByMessageCount: prefs.getInt('default_auto_pin_by_message_count') ?? 10,
      );

      final chatRoomId = await paginationDb.createChatRoom(chatRoom);

      await AgentSummaryService().seedFromCharacterBooks(
        chatRoomId: chatRoomId,
        characterId: widget.characterId,
      );

      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatRoomScreen(
            chatRoomId: chatRoomId,
          ),
        ),
      );

      final lastMessage = await paginationDb.readLastChatMessage(chatRoomId);
      if (lastMessage == null) {
        await paginationDb.deleteChatRoom(chatRoomId);
      }

      loadChatRooms();
    } catch (e) {
      debugPrint('Error creating chat: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).characterViewChatCreateFailed),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _onChatRoomTap(chatRoomSummary) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatRoomScreen(
          chatRoomId: chatRoomSummary.chatRoom.id!,
        ),
      ),
    );
    loadChatRooms();
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

    final l10n = AppLocalizations.of(context);
    if (_character == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Text(l10n.chatRoomCannotLoad),
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
          onBackPressed: () => Navigator.of(context).pop(_hasChanges),
          actions: [
            CommonAppBarIconButton(
              icon: Icons.download_outlined,
              onPressed: _importChatRoom,
              tooltip: l10n.chatRoomImport,
              offsetX: 0.0,
            ),
            CommonAppBarIconButton(
              icon: Icons.edit_outlined,
              onPressed: _navigateToEdit,
              tooltip: l10n.commonEdit,
              offsetX: 0.0,
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Transform.translate(
              offset: const Offset(0, -16),
              child: TabBar(
                controller: _tabController,
                tabs: [
                  Tab(text: l10n.characterViewTabInfo),
                  Tab(text: l10n.characterViewTabChat),
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
            CharacterInfoTab(
              character: _character!,
              coverImages: _coverImages,
              personas: _personas,
              startScenarios: _startScenarios,
              selectedPersonaIndex: _selectedPersonaIndex,
              selectedScenarioIndex: _selectedScenarioIndex,
              onPersonaIndexChanged: (index) => setState(() => _selectedPersonaIndex = index),
              onScenarioIndexChanged: (index) => setState(() => _selectedScenarioIndex = index),
              onNewChat: _createNewChat,
            ),
            CharacterChatTab(
              chatRooms: chatRooms,
              hasMoreChats: hasMoreChats,
              scrollController: chatScrollController,
              db: paginationDb,
              onChatRoomsChanged: loadChatRooms,
              onNewChat: _createNewChat,
              onChatRoomTap: _onChatRoomTap,
            ),
          ],
        ),
      ),
    );
  }
}
