import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import '../../../database/database_helper.dart';
import '../../../models/chat/chat_room.dart';
import '../../../models/chat/chat_summary.dart';
import '../../../models/chat/unified_model.dart';
import '../../../models/character/character.dart';
import '../../../models/character/character_book_folder.dart';
import '../../../models/character/persona.dart';
import '../../../models/prompt/chat_prompt.dart';
import '../../../providers/chat_model_provider.dart';
import '../../../services/auto_summary_service.dart';
import '../../../utils/common_dialog.dart';
import '../../../widgets/common/common_dropdown_button.dart';
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
  final List<ChatPrompt> chatPrompts;
  final List<Persona> personas;
  final ValueChanged<UnifiedModel> onModelChanged;
  final ValueChanged<int?> onPromptChanged;
  final ValueChanged<int?> onPersonaChanged;
  final ValueChanged<String> onPinModeChanged;
  final ValueChanged<bool> onAutoPinByDateChanged;
  final ValueChanged<bool> onAutoPinByLocationChanged;
  final ValueChanged<bool> onAutoPinByAiChanged;
  final ValueChanged<int?> onAutoPinByMessageCountChanged;

  const ChatRoomDrawer({
    super.key,
    required this.chatRoom,
    required this.character,
    this.selectedPersonaId,
    this.initialTab = DrawerTab.info,
    required this.onTabChanged,
    required this.onChatRoomUpdated,
    required this.chatPrompts,
    required this.personas,
    required this.onModelChanged,
    required this.onPromptChanged,
    required this.onPersonaChanged,
    required this.onPinModeChanged,
    required this.onAutoPinByDateChanged,
    required this.onAutoPinByLocationChanged,
    required this.onAutoPinByAiChanged,
    required this.onAutoPinByMessageCountChanged,
  });

  @override
  ChatRoomDrawerState createState() => ChatRoomDrawerState();
}

class ChatRoomDrawerState extends State<ChatRoomDrawer> {
  final DatabaseHelper _db = DatabaseHelper.instance;

  late DrawerTab _selectedTab;
  bool _memoExpanded = true;

  late TextEditingController _memoController;
  late TextEditingController _descriptionController;
  late TextEditingController _personaNameController;
  late TextEditingController _personaContentController;

  Persona? _persona;

  List<CharacterBookFolder> _folders = [];
  List<CharacterBook> _standaloneBooks = [];
  final Map<String, TextEditingController> _bookFieldControllers = {};

  late TextEditingController _pinMessageCountController;

  List<ChatSummary> _summaries = [];
  final Map<int, TextEditingController> _summaryControllers = {};
  final Set<int> _expandedSummaryIds = {};
  final Set<int> _regeneratingSummaryIds = {};
  final AutoSummaryService _autoSummaryService = AutoSummaryService();

  bool _isLoading = true;
  bool _isAddingSummary = false;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
    _memoController = TextEditingController(text: widget.chatRoom.memo);
    _descriptionController = TextEditingController(text: widget.character.description ?? '');
    _personaNameController = TextEditingController();
    _personaContentController = TextEditingController();
    _pinMessageCountController = TextEditingController(
      text: widget.chatRoom.autoPinByMessageCount?.toString() ?? '',
    );
    _loadData();
  }

  @override
  void dispose() {
    saveCurrentTabData();
    _memoController.dispose();
    _descriptionController.dispose();
    _personaNameController.dispose();
    _personaContentController.dispose();
    _pinMessageCountController.dispose();
    for (final c in _bookFieldControllers.values) {
      c.dispose();
    }
    for (final c in _summaryControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void saveCurrentTabData() {
    switch (_selectedTab) {
      case DrawerTab.info:
        _saveMemo();
        break;
      case DrawerTab.persona:
        _savePersona();
        break;
      case DrawerTab.character:
        _saveDescription();
        break;
      case DrawerTab.lorebook:
        _saveLorebook();
        break;
      case DrawerTab.summary:
        _saveAllSummaries();
        break;
    }
  }

  Future<void> _saveAllSummaries() async {
    for (final summary in _summaries) {
      final controller = _summaryControllers[summary.id];
      if (controller != null && controller.text != summary.summaryContent) {
        final updated = summary.copyWith(
          summaryContent: controller.text,
          updatedAt: DateTime.now(),
        );
        await _db.updateChatSummary(updated);
      }
    }
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
    if (_memoController.text == widget.chatRoom.memo) return;
    final updated = widget.chatRoom.copyWith(
      memo: _memoController.text,
      updatedAt: DateTime.now(),
    );
    await _db.updateChatRoom(updated);
  }

  Future<void> _savePersona() async {
    if (_persona == null) return;
    final name = _personaNameController.text.trim();
    final content = _personaContentController.text;

    final updated = _persona!.copyWith(
      name: name.isEmpty ? _persona!.name : name,
      content: content,
    );
    await _db.updatePersona(updated);
    _persona = updated;
  }

  Future<void> _createNewPersona() async {
    final characterId = widget.character.id!;
    final personas = await _db.readPersonas(characterId);
    final newPersona = Persona(
      characterId: characterId,
      name: '새 페르소나',
      order: personas.length,
      content: '',
    );
    final newId = await _db.createPersona(newPersona);
    _persona = newPersona.copyWith(id: newId);

    _personaNameController.text = _persona!.name;
    _personaContentController.text = '';

    widget.onPersonaChanged(newId);
    if (mounted) setState(() {});
  }

  Future<void> _saveDescription() async {
    if (_descriptionController.text == (widget.character.description ?? '')) return;
    final updated = widget.character.copyWith(
      description: _descriptionController.text,
      updatedAt: DateTime.now(),
    );
    await _db.updateCharacter(updated);
  }

  void _syncBookFieldsFromControllers() {
    for (final folder in _folders) {
      for (final book in folder.characterBooks) {
        _syncBookFromController(book);
      }
    }
    for (final book in _standaloneBooks) {
      _syncBookFromController(book);
    }
  }

  void _syncBookFromController(CharacterBook book) {
    final contentKey = 'book_${book.id}_content';
    if (_bookFieldControllers.containsKey(contentKey)) {
      book.content = _bookFieldControllers[contentKey]!.text;
    }
    final keysKey = 'book_${book.id}_keys';
    if (_bookFieldControllers.containsKey(keysKey)) {
      book.keys = _bookFieldControllers[keysKey]!.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    final secondaryKeysKey = 'book_${book.id}_secondaryKeys';
    if (_bookFieldControllers.containsKey(secondaryKeysKey)) {
      book.secondaryKeys = _bookFieldControllers[secondaryKeysKey]!.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    final orderKey = 'book_${book.id}_insertionOrder';
    if (_bookFieldControllers.containsKey(orderKey)) {
      final intValue = int.tryParse(_bookFieldControllers[orderKey]!.text);
      if (intValue != null) book.insertionOrder = intValue;
    }
  }

  Future<void> _saveLorebook() async {
    _syncBookFieldsFromControllers();

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

  }

  Future<void> _saveOrCreateBook(CharacterBook book, int characterId, {int? folderId}) async {
    if (book.id != null && book.id! > 0) {
      await _db.updateCharacterBook(book.copyWith(characterId: characterId, folderId: folderId));
    } else {
      await _db.createCharacterBook(book.copyWith(characterId: characterId, folderId: folderId));
    }
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
              label: '설정집',
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
        saveCurrentTabData();
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
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
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
              _buildChatSettings(),
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
      ],
    );
  }

  Widget _buildChatSettings() {
    final modelProvider = context.watch<ChatModelSettingsProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '채팅창 설정',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 12),
        _buildVerticalSettingRow(
          label: '채팅 모델',
          child: CommonDropdownButton<UnifiedModel>(
            value: modelProvider.selectedModel,
            items: modelProvider.availableModels,
            onChanged: (model) {
              if (model != null) widget.onModelChanged(model);
            },
            labelBuilder: (model) => model.displayName,
            size: CommonDropdownButtonSize.xsmall,
          ),
        ),
        const SizedBox(height: 8),
        _buildVerticalSettingRow(
          label: '채팅 프롬프트',
          child: CommonDropdownButton<int?>(
            value: widget.chatRoom.selectedChatPromptId,
            items: [null, ...widget.chatPrompts.map((p) => p.id)],
            onChanged: (id) => widget.onPromptChanged(id),
            labelBuilder: (id) {
              if (id == null) return '없음';
              return widget.chatPrompts.firstWhere((p) => p.id == id).name;
            },
            size: CommonDropdownButtonSize.xsmall,
          ),
        ),
        const SizedBox(height: 8),
        _buildVerticalSettingRow(
          label: '핀 모드',
          child: CommonDropdownButton<String>(
            value: widget.chatRoom.pinMode,
            items: const ['auto', 'manual'],
            onChanged: (mode) {
              if (mode != null) widget.onPinModeChanged(mode);
            },
            labelBuilder: (mode) => mode == 'auto' ? '자동' : '수동',
            size: CommonDropdownButtonSize.xsmall,
          ),
        ),
        if (widget.chatRoom.pinMode == 'auto') ...[
          const SizedBox(height: 4),
          _buildToggleRow(
            label: '날짜 기준',
            value: widget.chatRoom.autoPinByDate,
            onChanged: widget.onAutoPinByDateChanged,
          ),
          _buildToggleRow(
            label: '장소 기준',
            value: widget.chatRoom.autoPinByLocation,
            onChanged: widget.onAutoPinByLocationChanged,
          ),
          _buildToggleRow(
            label: 'AI 자동',
            value: widget.chatRoom.autoPinByAi,
            onChanged: widget.onAutoPinByAiChanged,
          ),
          _buildToggleRow(
            label: '메시지 수 기준',
            value: widget.chatRoom.autoPinByMessageCount != null,
            onChanged: (value) {
              if (value) {
                _pinMessageCountController.text = '10';
                widget.onAutoPinByMessageCountChanged(10);
              } else {
                _pinMessageCountController.clear();
                widget.onAutoPinByMessageCountChanged(null);
              }
            },
          ),
          if (widget.chatRoom.autoPinByMessageCount != null)
            Padding(
              padding: const EdgeInsets.only(left: 32),
              child: _buildVerticalSettingRow(
                label: '요약 메시지 수',
                child: SizedBox(
                  width: double.infinity,
                  child: CommonEditText(
                    controller: _pinMessageCountController,
                    hintText: '메시지 수',
                    size: CommonEditTextSize.small,
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final count = int.tryParse(value);
                      if (count != null && count > 0) {
                        widget.onAutoPinByMessageCountChanged(count);
                      }
                    },
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildVerticalSettingRow({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        child,
      ],
    );
  }

  Widget _buildToggleRow({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0),
      child: Row(
        children: [
          const SizedBox(width: 16),
          SizedBox(
            width: 64,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          const Spacer(),
          SizedBox(
            height: 28,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Switch(
                value: value,
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const int _createNewPersonaId = -1;

  Future<void> _onPersonaDropdownChanged(int? id) async {
    if (id == _createNewPersonaId) {
      await _createNewPersona();
      return;
    }

    await _savePersona();
    widget.onPersonaChanged(id);

    if (id == null) {
      _persona = null;
      _personaNameController.text = '';
      _personaContentController.text = '';
    } else {
      final persona = await _db.readPersona(id);
      if (persona != null) {
        _persona = persona;
        _personaNameController.text = persona.name;
        _personaContentController.text = persona.content ?? '';
      }
    }
    if (mounted) setState(() {});
  }

  // ==================== 페르소나 탭 ====================

  Widget _buildPersonaTab() {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
            children: [
              CommonFieldSection(
                label: '페르소나 선택',
                child: CommonDropdownButton<int?>(
                  value: widget.chatRoom.selectedPersonaId,
                  items: [null, ...widget.personas.map((p) => p.id), _createNewPersonaId],
                  onChanged: _onPersonaDropdownChanged,
                  labelBuilder: (id) {
                    if (id == null) return '없음';
                    if (id == _createNewPersonaId) return '+ 새 페르소나 생성';
                    return widget.personas.firstWhere((p) => p.id == id).name;
                  },
                  size: CommonDropdownButtonSize.xsmall,
                ),
              ),
              if (_persona != null) ...[
                CommonFieldSection(
                  label: '페르소나 이름',
                  child: CommonEditText(
                    controller: _personaNameController,
                    hintText: '페르소나 이름',
                    size: CommonEditTextSize.small,
                  ),
                ),
                CommonFieldSection(
                  label: '페르소나 설명',
                  bottomSpacing: 0,
                  child: CommonEditText(
                    controller: _personaContentController,
                    hintText: '페르소나 설명을 입력하세요',
                    maxLines: null,
                    minLines: 10,
                    size: CommonEditTextSize.small,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ==================== 캐릭터 정보 탭 ====================

  Widget _buildCharacterTab() {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
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
                    '설정집 항목이 없습니다',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : ListView(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
                  children: allItems,
                ),
        ),
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
      nameHint: '설정 이름',
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
              label: '두번째 키',
              child: CommonSegmentedButton<CharacterBookSecondaryKeyUsage>(
                values: CharacterBookSecondaryKeyUsage.values,
                selected: book.secondaryKeyUsage,
                onSelectionChanged: (selected) {
                  setState(() => book.secondaryKeyUsage = selected);
                },
                labelBuilder: (c) => c.displayName,
              ),
            ),
            if (book.secondaryKeyUsage == CharacterBookSecondaryKeyUsage.enabled)
              _buildBookSecondaryKeysField(book),
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

  Widget _buildBookSecondaryKeysField(CharacterBook book) {
    final key = 'book_${book.id}_secondaryKeys';
    final controller = _getBookFieldController(key, book.secondaryKeys.join(', '));
    return CommonFieldSection(
      label: '두번째 키',
      child: CommonEditText(
        controller: controller,
        hintText: '쉼표로 구분하여 입력 (예: 마법, 전투)',
        size: CommonEditTextSize.small,
        onFocusLost: (value) {
          book.secondaryKeys = value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
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
        hintText: '설정 내용을 입력해주세요',
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
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
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
                  final isExpanded = _expandedSummaryIds.contains(summary.id);

                  return CommonEditableExpandableItem(
                    key: ValueKey('summary_${summary.id}'),
                    icon: Icon(
                      Icons.summarize_outlined,
                      size: 20,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    name: 'Summary #${index + 1}',
                    isExpanded: isExpanded,
                    showNameField: false,
                    onToggleExpanded: () {
                      setState(() {
                        if (isExpanded) {
                          _expandedSummaryIds.remove(summary.id!);
                        } else {
                          _expandedSummaryIds.add(summary.id!);
                        }
                      });
                    },
                    onDelete: () => _deleteSummary(summary.id!),
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                              onPressed: _regeneratingSummaryIds.contains(summary.id)
                                  ? null
                                  : () => _regenerateSummary(summary),
                              icon: _regeneratingSummaryIds.contains(summary.id)
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.refresh, size: 16),
                              label: Text(
                                _regeneratingSummaryIds.contains(summary.id)
                                    ? '생성 중...'
                                    : '재생성',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
        _buildAddSummaryButton(),
      ],
    );
  }

  Widget _buildAddSummaryButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: _isAddingSummary
            ? const Center(child: CircularProgressIndicator())
            : CommonButton.filled(
                onPressed: _addManualSummary,
                icon: Icons.add,
                label: '현재 메시지 기준 요약 추가',
                size: CommonButtonSize.small,
              ),
      ),
    );
  }

  Future<void> _addManualSummary() async {
    setState(() => _isAddingSummary = true);

    try {
      final chatRoomId = widget.chatRoom.id!;
      final allMessages = await _db.readChatMessagesByChatRoom(chatRoomId);
      if (allMessages.isEmpty) {
        if (!mounted) return;
        CommonDialog.showSnackBar(context: context, message: '메시지가 없습니다');
        return;
      }

      // Determine start: after the last existing summary's end, or 0
      final existingSummaries = await _db.getChatSummaries(chatRoomId);
      final startPinMessageId = existingSummaries.isNotEmpty
          ? existingSummaries.last.endPinMessageId
          : 0;

      final endPinMessageId = allMessages.last.id!;

      if (startPinMessageId == endPinMessageId) {
        if (!mounted) return;
        CommonDialog.showSnackBar(context: context, message: '요약할 새 메시지가 없습니다');
        return;
      }

      final summary = ChatSummary(
        chatRoomId: chatRoomId,
        startPinMessageId: startPinMessageId,
        endPinMessageId: endPinMessageId,
        summaryContent: '',
      );
      final newId = await _db.createChatSummary(summary);

      _summaryControllers[newId] = TextEditingController(text: '');
      _expandedSummaryIds.add(newId);

      await _loadData();

      if (!mounted) return;
      CommonDialog.showSnackBar(context: context, message: '요약이 추가되었습니다. 내용을 입력해주세요.');
    } catch (e) {
      if (!mounted) return;
      CommonDialog.showSnackBar(
        context: context,
        message: '요약 추가 중 오류가 발생했습니다: $e',
      );
    } finally {
      if (mounted) {
        setState(() => _isAddingSummary = false);
      }
    }
  }

  Future<void> _regenerateSummary(ChatSummary summary) async {
    final summaryId = summary.id!;
    setState(() => _regeneratingSummaryIds.add(summaryId));

    try {
      final updated = await _autoSummaryService.regenerateSummary(summary: summary);

      _summaryControllers[summaryId]?.text = updated.summaryContent;

      await _loadData();

      if (!mounted) return;
      CommonDialog.showSnackBar(context: context, message: '요약이 재생성되었습니다');
    } catch (e) {
      if (!mounted) return;
      CommonDialog.showSnackBar(
        context: context,
        message: '요약 재생성 중 오류가 발생했습니다: $e',
      );
    } finally {
      if (mounted) {
        setState(() => _regeneratingSummaryIds.remove(summaryId));
      }
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
