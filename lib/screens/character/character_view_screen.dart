import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/app_localizations.dart';
import '../../mixins/chat_room_pagination_mixin.dart';
import '../../models/character/character.dart';
import '../../models/character/cover_image.dart';
import '../../models/character/persona.dart';
import '../../models/character/start_scenario.dart';
import '../../models/chat/chat_room.dart';
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

class _CharacterViewScreenState extends State<CharacterViewScreen> with SingleTickerProviderStateMixin, ChatRoomPaginationMixin {
  late TabController _tabController;

  Character? _character;
  List<CoverImage> _coverImages = [];
  List<Persona> _personas = [];
  List<StartScenario> _startScenarios = [];
  bool _isLoading = true;
  bool _hasChanges = false;

  @override
  int? get paginationCharacterId => widget.characterId;

  @override
  void onChatRoomsLoaded() {
    _resolveChatCoverImages();
  }

  Future<void> _resolveChatCoverImages() async {
    for (final data in chatRooms) {
      final cover = data.coverImage;
      if (cover != null && cover.imageData == null && cover.path != null) {
        cover.imageData = await cover.resolveImageData();
      }
    }
    if (mounted) setState(() {});
  }

  int? _selectedPersonaIndex;
  int? _selectedScenarioIndex;

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

  String _formatDate(DateTime dateTime, AppLocalizations l10n) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return l10n.chatDateToday;
    } else if (difference.inDays == 1) {
      return l10n.chatDateYesterday;
    } else if (difference.inDays < 7) {
      return l10n.chatDateDaysAgo(difference.inDays);
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return l10n.chatDateWeeksAgo(weeks);
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return l10n.chatDateMonthsAgo(months);
    } else {
      final years = (difference.inDays / 365).floor();
      return l10n.chatDateYearsAgo(years);
    }
  }

  Future<void> _showRenameChatRoomDialog(ChatRoom chatRoom) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(text: chatRoom.name);

    try {
      final result = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.chatRoomRenameTitle),
          content: CommonEditText(
            controller: controller,
            hintText: l10n.chatRoomRenameHint,
            size: CommonEditTextSize.medium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: Text(l10n.commonCancel),
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
              child: Text(l10n.commonConfirm),
            ),
          ],
        ),
      );

      if (result != null && result.isNotEmpty && result != chatRoom.name) {
        final updatedChatRoom = chatRoom.copyWith(
          name: result,
        );
        await paginationDb.updateChatRoom(updatedChatRoom);
        loadChatRooms();
      }
    } catch (e) {
      debugPrint('Error renaming chat room: $e');
      if (!mounted) return;
      CommonDialog.showSnackBar(
        context: context,
        message: l10n.chatRoomRenameFailed,
      );
    } finally {
      controller.dispose();
    }
  }

  Future<void> _showDeleteChatRoomDialog(ChatRoom chatRoom) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await CommonDialog.showConfirmation(
      context: context,
      title: l10n.chatRoomDeleteTitle,
      content: l10n.chatRoomDeleteOneContent(chatRoom.name),
      confirmText: l10n.commonDelete,
      isDestructive: true,
    );

    if (confirmed == true) {
      try {
        await paginationDb.deleteChatRoom(chatRoom.id!);
        loadChatRooms();
        if (!mounted) return;
        CommonDialog.showSnackBar(
          context: context,
          message: l10n.chatRoomDeleted,
        );
      } catch (e) {
        debugPrint('Error deleting chat room: $e');
        if (!mounted) return;
        CommonDialog.showSnackBar(
          context: context,
          message: l10n.chatRoomDeleteFailed,
        );
      }
    }
  }

  Future<void> _createNewChat() async {
    if (_character == null) return;

    try {
      final selectedPrompt = await paginationDb.readSelectedChatPrompt();

      final existingRooms = await paginationDb.database.then((db) async {
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
        autoPinByMessageCount: prefs.getInt('default_auto_pin_by_message_count') ?? 10,
      );

      final chatRoomId = await paginationDb.createChatRoom(chatRoom);

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

      // 채팅방 리스트 새로고침
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

    final fallback = AspectRatio(
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

    if (selectedCover == null) return fallback;

    return FutureBuilder<Uint8List?>(
      future: selectedCover.resolveImageData(),
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        if (bytes == null) return fallback;
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: 1,
            child: Image.memory(
              bytes,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
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
      },
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

  String _replaceStartTextKeywords(String text) {
    final keywords = {
      'char': _character?.name ?? '',
      'user': '',
    };
    var result = text;
    for (final entry in keywords.entries) {
      result = result.replaceAll('{{${entry.key}}}', entry.value);
    }
    return result;
  }

  Widget _buildSelectedScenarioContent() {
    if (_selectedScenarioIndex == null) {
      return const SizedBox();
    }

    final scenario = _startScenarios[_selectedScenarioIndex!];

    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        if (scenario.startSetting != null && scenario.startSetting!.isNotEmpty) ...[
          CommonTitleMedium(text: l10n.characterViewStartContext),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _replaceStartTextKeywords(scenario.startSetting!),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (scenario.startMessage != null && scenario.startMessage!.isNotEmpty) ...[
          CommonTitleMedium(text: l10n.characterViewStartMessage),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _replaceStartTextKeywords(scenario.startMessage!),
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
    final l10n = AppLocalizations.of(context);
    final keywords = _character!.tags;

    return Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Cover image
                _buildCoverImage(),
                const SizedBox(height: 24),

                if (_character!.creatorNotes != null && _character!.creatorNotes!.isNotEmpty) ...[
                  CommonTitleMedium(text: l10n.characterViewTagline),
                  const SizedBox(height: 8),
                  Text(
                    _character!.creatorNotes!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 24),
                ],

                if (keywords.isNotEmpty) ...[
                  CommonTitleMedium(text: l10n.characterViewKeywords),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: keywords.map((keyword) => CharacterTagChip(label: keyword)).toList(),
                  ),
                  const SizedBox(height: 24),
                ],

                if (_personas.isNotEmpty) ...[
                  CommonTitleMedium(text: l10n.characterViewPersona),
                  const SizedBox(height: 8),
                  _buildPersonaDropdown(),
                  _buildSelectedPersonaContent(),
                  const SizedBox(height: 24),
                ],

                if (_startScenarios.isNotEmpty) ...[
                  CommonTitleMedium(text: l10n.characterViewStartSetting),
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
                label: l10n.characterViewNewChat,
              ),
            ),
          ),
        ],
      );
  }

  Widget _buildChatTab() {
    final l10n = AppLocalizations.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth * 0.05;

    if (chatRooms.isEmpty) {
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
              l10n.characterViewNoChats,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.characterViewStartNewChat,
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
            controller: chatScrollController,
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16.0),
            itemCount: chatRooms.length + (hasMoreChats ? 1 : 0),
            separatorBuilder: (context, index) => const SizedBox(height: 20.0),
            itemBuilder: (context, index) {
              if (index >= chatRooms.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              final data = chatRooms[index];
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
                  loadChatRooms();
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
                              title: Text(l10n.chatRoomRenameTitle),
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
                                l10n.commonDelete,
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
                      : l10n.chatNoMessages,
                  date: _formatDate(data.chatRoom.updatedAt, l10n),
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
              label: l10n.characterViewNewChat,
            ),
          ),
        ),
      ],
    );
  }
}

