import 'package:flutter/material.dart';

import '../../../database/database_helper.dart';
import '../../../models/chat/chat_room.dart';
import '../../../models/chat/chat_summary.dart';
import '../../../models/character/character.dart';
import '../../../models/character/character_book_folder.dart';
import '../../../models/character/persona.dart';
import '../../../utils/common_dialog.dart';
import '../../../widgets/common/common_edit_text.dart';
import '../../../widgets/common/common_button.dart';
import '../../../widgets/common/common_editable_expandable_item.dart';
import '../../../widgets/common/common_field_section.dart';
import '../../../widgets/common/common_segmented_button.dart';

enum DrawerTab {
  info,
  persona,
  character,
  lorebook,
  summary,
}

class ChatRoomDrawer extends StatefulWidget {
  final ChatRoom chatRoom;
  final Character character;
  final int? selectedPersonaId;
  final DrawerTab initialTab;
  final ValueChanged<DrawerTab> onTabChanged;
  final VoidCallback onChatRoomUpdated;

  const ChatRoomDrawer({
    super.key,
    required this.chatRoom,
    required this.character,
    this.selectedPersonaId,
    this.initialTab = DrawerTab.info,
    required this.onTabChanged,
    required this.onChatRoomUpdated,
  });

  @override
  State<ChatRoomDrawer> createState() => _ChatRoomDrawerState();
}

class _ChatRoomDrawerState extends State<ChatRoomDrawer> {
  final DatabaseHelper _db = DatabaseHelper.instance;

  late DrawerTab _selectedTab;
  bool _memoExpanded = true;

  late TextEditingController _memoController;
  late TextEditingController _descriptionController;
  late TextEditingController _summaryController;
  late TextEditingController _personaNameController;
  late TextEditingController _personaContentController;

  Persona? _persona;

  List<CharacterBookFolder> _folders = [];
  List<CharacterBook> _standaloneBooks = [];
  final Map<String, TextEditingController> _bookFieldControllers = {};

  List<ChatSummary> _summaries = [];
  final Map<int, TextEditingController> _summaryControllers = {};

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
    _memoController = TextEditingController(text: widget.chatRoom.memo);
    _descriptionController = TextEditingController(text: widget.character.description ?? '');
    _summaryController = TextEditingController(text: widget.chatRoom.summary);
    _personaNameController = TextEditingController();
    _personaContentController = TextEditingController();
    _loadData();
  }

  @override
  void dispose() {
    _memoController.dispose();
    _descriptionController.dispose();
    _summaryController.dispose();
    _personaNameController.dispose();
    _personaContentController.dispose();
    for (final c in _bookFieldControllers.values) {
      c.dispose();
    }
    for (final c in _summaryControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadData() async {
    final characterId = widget.character.id!;

    if (widget.selectedPersonaId != null) {
      final persona = await _db.readPersona(widget.selectedPersonaId!);
      if (persona != null) {
        _persona = persona;
        _personaNameController.text = persona.name;
        _personaContentController.text = persona.content ?? '';
      }
    }

    final folders = await _db.readCharacterBookFolders(characterId);
    for (final folder in folders) {
      final books = await _db.readCharacterBooksByFolder(folder.id!);
      folder.characterBooks.addAll(books);
    }
    final standaloneBooks = await _db.readStandaloneCharacterBooks(characterId);

    final summaries = await _db.getChatSummaries(widget.chatRoom.id!);
    for (final summary in summaries) {
      if (!_summaryControllers.containsKey(summary.id)) {
        _summaryControllers[summary.id!] = TextEditingController(text: summary.summaryContent);
      }
    }

    setState(() {
      _folders = folders;
      _standaloneBooks = standaloneBooks;
      _summaries = summaries;
      _isLoading = false;
    });
  }

  TextEditingController _getBookFieldController(String key, String initialValue) {
    if (!_bookFieldControllers.containsKey(key)) {
      _bookFieldControllers[key] = TextEditingController(text: initialValue);
    }
    return _bookFieldControllers[key]!;
  }

  Future<void> _saveMemo() async {
    final updated = widget.chatRoom.copyWith(
      memo: _memoController.text,
      updatedAt: DateTime.now(),
    );
    await _db.updateChatRoom(updated);
    widget.onChatRoomUpdated();
    if (!mounted) return;
    CommonDialog.showSnackBar(context: context, message: '메모가 저장되었습니다');
  }

  Future<void> _savePersona() async {
    final name = _personaNameController.text.trim();
    final content = _personaContentController.text;

    if (_persona != null) {
      final updated = _persona!.copyWith(
        name: name.isEmpty ? _persona!.name : name,
        content: content,
      );
      await _db.updatePersona(updated);
      _persona = updated;
      if (!mounted) return;
      CommonDialog.showSnackBar(context: context, message: '페르소나가 저장되었습니다');
    } else {
      if (name.isEmpty && content.isEmpty) return;
      final characterId = widget.character.id!;
      final personas = await _db.readPersonas(characterId);
      final newPersona = Persona(
        characterId: characterId,
        name: name.isEmpty ? '새 페르소나' : name,
        order: personas.length,
        content: content,
      );
      final newId = await _db.createPersona(newPersona);
      _persona = newPersona.copyWith(id: newId);

      final updatedRoom = widget.chatRoom.copyWith(
        selectedPersonaId: newId,
        updatedAt: DateTime.now(),
      );
      await _db.updateChatRoom(updatedRoom);
      widget.onChatRoomUpdated();

      if (!mounted) return;
      setState(() {});
      CommonDialog.showSnackBar(context: context, message: '새 페르소나가 생성되었습니다');
    }
  }

  Future<void> _saveDescription() async {
    final updated = widget.character.copyWith(
      description: _descriptionController.text,
      updatedAt: DateTime.now(),
    );
    await _db.updateCharacter(updated);
    if (!mounted) return;
    CommonDialog.showSnackBar(context: context, message: '캐릭터 설정이 저장되었습니다');
  }

  Future<void> _saveLorebook() async {
    final characterId = widget.character.id!;

    for (final folder in _folders) {
      if (folder.id != null && folder.id! > 0) {
        await _db.updateCharacterBookFolder(folder.copyWith(characterId: characterId));
      } else {
        final newId = await _db.createCharacterBookFolder(
          folder.copyWith(characterId: characterId),
        );
        for (final book in folder.characterBooks) {
          book.order = folder.characterBooks.indexOf(book);
        }
        for (final book in folder.characterBooks) {
          await _saveOrCreateBook(book, characterId, folderId: newId);
        }
        continue;
      }

      for (final book in folder.characterBooks) {
        await _saveOrCreateBook(book, characterId, folderId: folder.id);
      }
    }

    for (final book in _standaloneBooks) {
      await _saveOrCreateBook(book, characterId);
    }

    if (!mounted) return;
    CommonDialog.showSnackBar(context: context, message: '로어북이 저장되었습니다');
  }

  Future<void> _saveOrCreateBook(CharacterBook book, int characterId, {int? folderId}) async {
    if (book.id != null && book.id! > 0) {
      await _db.updateCharacterBook(book.copyWith(characterId: characterId, folderId: folderId));
    } else {
      await _db.createCharacterBook(book.copyWith(characterId: characterId, folderId: folderId));
    }
  }

  Future<void> _saveSummary() async {
    final updated = widget.chatRoom.copyWith(
      summary: _summaryController.text,
      updatedAt: DateTime.now(),
    );
    await _db.updateChatRoom(updated);
    widget.onChatRoomUpdated();
    if (!mounted) return;
    CommonDialog.showSnackBar(context: context, message: '요약이 저장되었습니다');
  }

  Widget _buildBottomSaveButton(VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: CommonButton.filled(
          onPressed: onPressed,
          icon: Icons.save_outlined,
          label: '저장',
          size: CommonButtonSize.small,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.95,
      child: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              _buildTabBar(),
              const SizedBox(height: 8),
              Expanded(child: _buildTabContent()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildChip(
              icon: Icons.chat_outlined,
              label: '기본 정보',
              tab: DrawerTab.info,
            ),
            const SizedBox(width: 8),
            _buildChip(
              icon: Icons.face_outlined,
              label: '페르소나',
              tab: DrawerTab.persona,
            ),
            const SizedBox(width: 8),
            _buildChip(
              icon: Icons.person_outlined,
              label: '캐릭터 정보',
              tab: DrawerTab.character,
            ),
            const SizedBox(width: 8),
            _buildChip(
              icon: Icons.description_outlined,
              label: '로어북',
              tab: DrawerTab.lorebook,
            ),
            const SizedBox(width: 8),
            _buildChip(
              icon: Icons.history,
              label: '요약',
              tab: DrawerTab.summary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip({
    required IconData icon,
    required String label,
    required DrawerTab tab,
  }) {
    final selected = _selectedTab == tab;
    return FilterChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        setState(() => _selectedTab = tab);
        widget.onTabChanged(tab);
      },
      showCheckmark: false,
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case DrawerTab.info:
        return _buildInfoTab();
      case DrawerTab.persona:
        return _buildPersonaTab();
      case DrawerTab.character:
        return _buildCharacterTab();
      case DrawerTab.lorebook:
        return _buildLorebookTab();
      case DrawerTab.summary:
        return _buildSummaryTab();
    }
  }

  // ==================== 기본 정보 탭 ====================

  Widget _buildInfoTab() {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                '사용 캐릭터',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Text(
                widget.character.name,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              InkWell(
                onTap: () => setState(() => _memoExpanded = !_memoExpanded),
                child: Row(
                  children: [
                    Text(
                      '채팅 메모',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const Spacer(),
                    Icon(
                      _memoExpanded ? Icons.expand_less : Icons.expand_more,
                      size: 20,
                    ),
                  ],
                ),
              ),
              if (_memoExpanded) ...[
                const SizedBox(height: 8),
                CommonEditText(
                  controller: _memoController,
                  hintText: '메모를 입력하세요',
                  maxLines: null,
                  minLines: 5,
                  size: CommonEditTextSize.small,
                ),
              ],
            ],
          ),
        ),
        if (_memoExpanded)
          _buildBottomSaveButton(_saveMemo),
      ],
    );
  }

  // ==================== 페르소나 탭 ====================

  Widget _buildPersonaTab() {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                '페르소나 이름',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              CommonEditText(
                controller: _personaNameController,
                hintText: '페르소나 이름',
                size: CommonEditTextSize.small,
              ),
              const SizedBox(height: 16),
              Text(
                '페르소나 설명',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              CommonEditText(
                controller: _personaContentController,
                hintText: '페르소나 설명을 입력하세요',
                maxLines: null,
                minLines: 10,
                size: CommonEditTextSize.small,
              ),
            ],
          ),
        ),
        _buildBottomSaveButton(_savePersona),
      ],
    );
  }

  // ==================== 캐릭터 정보 탭 ====================

  Widget _buildCharacterTab() {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                '캐릭터',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              CommonEditText(
                controller: _descriptionController,
                hintText: '캐릭터 설정을 입력하세요',
                maxLines: null,
                minLines: 10,
                size: CommonEditTextSize.small,
              ),
            ],
          ),
        ),
        _buildBottomSaveButton(_saveDescription),
      ],
    );
  }

  // ==================== 로어북 탭 ====================

  Widget _buildLorebookTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final allItems = <Widget>[];

    for (final folder in _folders) {
      allItems.add(_buildFolderSection(folder));
    }

    for (final book in _standaloneBooks) {
      allItems.add(_buildBookCard(book, null));
    }

    return Column(
      children: [
        Expanded(
          child: allItems.isEmpty
              ? Center(
                  child: Text(
                    '로어북 항목이 없습니다',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: allItems,
                ),
        ),
        _buildBottomSaveButton(_saveLorebook),
      ],
    );
  }

  Widget _buildFolderSection(CharacterBookFolder folder) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        title: Text(folder.name, style: Theme.of(context).textTheme.titleSmall),
        leading: const Icon(Icons.folder_outlined, size: 20),
        initiallyExpanded: folder.isExpanded,
        onExpansionChanged: (expanded) => folder.isExpanded = expanded,
        children: [
          for (final book in folder.characterBooks)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: _buildBookCard(book, folder),
            ),
        ],
      ),
    );
  }

  Widget _buildBookCard(CharacterBook book, CharacterBookFolder? folder) {
    return CommonEditableExpandableItem(
      key: ValueKey('book_${book.id}'),
      icon: Icon(
        Icons.description_outlined,
        size: 20,
        color: Theme.of(context).colorScheme.secondary,
      ),
      name: book.name,
      isExpanded: book.isExpanded,
      onToggleExpanded: () {
        setState(() => book.isExpanded = !book.isExpanded);
      },
      onDelete: () => _deleteBook(book, folder),
      nameHint: '캐릭터북 이름',
      onNameChanged: (value) => book.name = value,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CommonFieldSection(
            label: '활성화 조건',
            child: CommonSegmentedButton<CharacterBookActivationCondition>(
              values: CharacterBookActivationCondition.values,
              selected: book.enabled,
              onSelectionChanged: (selected) {
                setState(() => book.enabled = selected);
              },
              labelBuilder: (c) => c.displayName,
            ),
          ),
          if (book.enabled == CharacterBookActivationCondition.keyBased) ...[
            _buildBookKeysField(book),
            CommonFieldSection(
              label: '키 사용 조건',
              child: CommonSegmentedButton<CharacterBookKeyCondition>(
                values: CharacterBookKeyCondition.values,
                selected: book.keyCondition,
                onSelectionChanged: (selected) {
                  setState(() => book.keyCondition = selected);
                },
                labelBuilder: (c) => c.displayName,
              ),
            ),
          ],
          _buildBookInsertionOrderField(book),
          _buildBookContentField(book),
        ],
      ),
    );
  }

  Widget _buildBookKeysField(CharacterBook book) {
    final key = 'book_${book.id}_keys';
    final controller = _getBookFieldController(key, book.keys.join(', '));
    return CommonFieldSection(
      label: '활성화 키',
      child: CommonEditText(
        controller: controller,
        hintText: '쉼표로 구분하여 입력',
        size: CommonEditTextSize.small,
        onFocusLost: (value) {
          book.keys = value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
        },
      ),
    );
  }

  Widget _buildBookInsertionOrderField(CharacterBook book) {
    final key = 'book_${book.id}_insertionOrder';
    final controller = _getBookFieldController(key, book.insertionOrder.toString());
    return CommonFieldSection(
      label: '배치 순서',
      child: CommonEditText(
        controller: controller,
        hintText: '0',
        size: CommonEditTextSize.small,
        keyboardType: TextInputType.number,
        onFocusLost: (value) {
          final intValue = int.tryParse(value);
          if (intValue != null) book.insertionOrder = intValue;
        },
      ),
    );
  }

  Widget _buildBookContentField(CharacterBook book) {
    final key = 'book_${book.id}_content';
    final controller = _getBookFieldController(key, book.content ?? '');
    return CommonFieldSection(
      label: '내용',
      bottomSpacing: 0,
      child: CommonEditText(
        controller: controller,
        hintText: '캐릭터북 내용을 입력해주세요',
        size: CommonEditTextSize.small,
        maxLines: null,
        minLines: 5,
        onFocusLost: (value) => book.content = value,
      ),
    );
  }

  Future<void> _deleteBook(CharacterBook book, CharacterBookFolder? folder) async {
    final confirmed = await CommonDialog.showDeleteConfirmation(
      context: context,
      itemName: book.name,
    );
    if (!confirmed) return;

    if (book.id != null && book.id! > 0) {
      await _db.deleteCharacterBook(book.id!);
    }

    setState(() {
      if (folder != null) {
        folder.characterBooks.remove(book);
      } else {
        _standaloneBooks.remove(book);
      }
    });
  }

  // ==================== 요약 탭 ====================

  Widget _buildSummaryTab() {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '자동 요약 목록',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Text(
                    '${_summaries.length}개',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_summaries.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      '자동 요약이 없습니다.\n설정에서 자동 요약을 활성화하세요.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
              else
                ...List.generate(_summaries.length, (index) {
                  final summary = _summaries[index];
                  final controller = _summaryControllers[summary.id]!;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Summary #${index + 1}',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 20),
                                onPressed: () => _deleteSummary(summary.id!),
                                tooltip: '삭제',
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          CommonEditText(
                            controller: controller,
                            hintText: '요약 내용',
                            maxLines: null,
                            minLines: 4,
                            size: CommonEditTextSize.small,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                onPressed: () => _saveSummaryItem(summary),
                                icon: const Icon(Icons.save, size: 16),
                                label: const Text('저장'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 16),
              Divider(),
              const SizedBox(height: 16),
              Text(
                '채팅방 요약 (레거시)',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              CommonEditText(
                controller: _summaryController,
                hintText: '요약을 입력하세요',
                maxLines: null,
                minLines: 6,
                size: CommonEditTextSize.small,
              ),
            ],
          ),
        ),
        _buildBottomSaveButton(_saveSummary),
      ],
    );
  }

  Future<void> _saveSummaryItem(ChatSummary summary) async {
    try {
      final controller = _summaryControllers[summary.id]!;
      final updated = summary.copyWith(
        summaryContent: controller.text,
        updatedAt: DateTime.now(),
      );
      await _db.updateChatSummary(updated);

      await _loadData();

      if (!mounted) return;
      CommonDialog.showSnackBar(context: context, message: '요약이 저장되었습니다');
    } catch (e) {
      if (!mounted) return;
      CommonDialog.showSnackBar(
        context: context,
        message: '요약 저장 중 오류가 발생했습니다: $e',
      );
    }
  }

  Future<void> _deleteSummary(int summaryId) async {
    final confirmed = await CommonDialog.showDeleteConfirmation(
      context: context,
      itemName: '이 요약',
    );

    if (!confirmed) return;

    try {
      await _db.deleteChatSummary(summaryId);

      _summaryControllers[summaryId]?.dispose();
      _summaryControllers.remove(summaryId);

      await _loadData();

      if (!mounted) return;
      CommonDialog.showSnackBar(context: context, message: '요약이 삭제되었습니다');
    } catch (e) {
      if (!mounted) return;
      CommonDialog.showSnackBar(
        context: context,
        message: '요약 삭제 중 오류가 발생했습니다: $e',
      );
    }
  }
}
