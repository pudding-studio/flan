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
import '../../../models/prompt/prompt_condition.dart';
import '../../../models/prompt/prompt_condition_option.dart';
import '../../../models/prompt/prompt_condition_preset.dart';
import '../../../models/prompt/prompt_condition_preset_value.dart';
import '../../../models/chat/chat_model.dart';
import '../../../models/chat/model_preset.dart';
import '../../../providers/chat_model_provider.dart';
import '../../../models/chat/agent_entry.dart';
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
  final ValueChanged<String> onModelPresetChanged;
  final ValueChanged<int?> onPromptChanged;
  final ValueChanged<int?> onPersonaChanged;
  final ValueChanged<String> onPinModeChanged;
  final ValueChanged<bool> onAutoPinByDateChanged;
  final ValueChanged<bool> onAutoPinByLocationChanged;
  final ValueChanged<bool> onAutoPinByAiChanged;
  final ValueChanged<int?> onAutoPinByMessageCountChanged;
  final ValueChanged<int?> onPresetChanged;

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
    required this.onModelPresetChanged,
    required this.onPromptChanged,
    required this.onPersonaChanged,
    required this.onPinModeChanged,
    required this.onAutoPinByDateChanged,
    required this.onAutoPinByLocationChanged,
    required this.onAutoPinByAiChanged,
    required this.onAutoPinByMessageCountChanged,
    required this.onPresetChanged,
  });

  @override
  ChatRoomDrawerState createState() => ChatRoomDrawerState();
}

class ChatRoomDrawerState extends State<ChatRoomDrawer> {
  final DatabaseHelper _db = DatabaseHelper.instance;

  // Drawer label styles (+2pt from default)
  TextStyle? get _sectionHeaderStyle =>
      Theme.of(context).textTheme.titleSmall?.copyWith(fontSize: 16);
  TextStyle? get _fieldLabelStyle =>
      Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600, fontSize: 14);
  TextStyle? get _subLabelStyle =>
      Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 14);

  late DrawerTab _selectedTab;
  bool _memoExpanded = true;

  late TextEditingController _memoController;
  late TextEditingController _descriptionController;
  late TextEditingController _personaNameController;
  late TextEditingController _personaContentController;

  Persona? _persona;

  List<PromptConditionPreset> _presets = [];
  List<PromptCondition> _conditions = [];
  final Map<int, TextEditingController> _customValueControllers = {};

  List<CharacterBookFolder> _folders = [];
  List<CharacterBook> _standaloneBooks = [];
  final Map<String, TextEditingController> _bookFieldControllers = {};

  late TextEditingController _pinMessageCountController;

  List<ChatSummary> _summaries = [];
  final Map<int, TextEditingController> _summaryControllers = {};
  final Set<int> _expandedSummaryIds = {};
  final Set<int> _regeneratingSummaryIds = {};
  final AutoSummaryService _autoSummaryService = AutoSummaryService();

  // Agent mode state
  bool _autoSummaryEnabled = false;
  bool _agentEnabled = false;
  int _agentSubTabIndex = 0;
  List<AgentEntry> _agentEntries = [];
  final Map<int, TextEditingController> _agentEntryControllers = {};
  final Set<int> _expandedAgentEntryIds = {};

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
    for (final c in _customValueControllers.values) {
      c.dispose();
    }
    for (final c in _bookFieldControllers.values) {
      c.dispose();
    }
    for (final c in _summaryControllers.values) {
      c.dispose();
    }
    for (final c in _agentEntryControllers.values) {
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

    await _loadPresetsAndConditions();

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

    // Load agent settings and entries
    final summarySettings = await _db.getAutoSummarySettings(0);
    final agentEntries = await _db.getAgentEntries(widget.chatRoom.id!);
    for (final entry in agentEntries) {
      if (entry.id != null && !_agentEntryControllers.containsKey(entry.id)) {
        _agentEntryControllers[entry.id!] = TextEditingController(
          text: entry.toReadableText(),
        );
      }
    }

    setState(() {
      _folders = folders;
      _standaloneBooks = standaloneBooks;
      _summaries = summaries;
      _autoSummaryEnabled = summarySettings?.isEnabled ?? false;
      _agentEnabled = summarySettings?.isAgentEnabled ?? false;
      _agentEntries = agentEntries;
      _isLoading = false;
    });
  }

  TextEditingController _getBookFieldController(String key, String initialValue) {
    if (!_bookFieldControllers.containsKey(key)) {
      _bookFieldControllers[key] = TextEditingController(text: initialValue);
    }
    return _bookFieldControllers[key]!;
  }

  Future<void> _loadPresetsAndConditions() async {
    final promptId = widget.chatRoom.selectedChatPromptId;
    if (promptId == null) {
      _presets = [];
      _conditions = [];
      return;
    }

    final presets = await _db.readPromptConditionPresets(promptId);
    for (final preset in presets) {
      final values = await _db.readPromptConditionPresetValues(preset.id!);
      preset.values.addAll(values);
    }

    final conditions = await _db.readPromptConditions(promptId);
    for (final condition in conditions) {
      final options = await _db.readPromptConditionOptions(condition.id!);
      condition.options.addAll(options);
    }

    _presets = presets;
    _conditions = conditions;
  }

  PromptConditionPreset? get _selectedPreset {
    final presetId = widget.chatRoom.selectedConditionPresetId;
    if (presetId == null) {
      // Return default preset
      try {
        return _presets.firstWhere((p) => p.isDefault);
      } catch (_) {
        return _presets.isNotEmpty ? _presets.first : null;
      }
    }
    try {
      return _presets.firstWhere((p) => p.id == presetId);
    } catch (_) {
      return _presets.isNotEmpty ? _presets.first : null;
    }
  }

  PromptConditionPresetValue? _getValueForCondition(PromptConditionPreset preset, int? conditionId) {
    if (conditionId == null) return null;
    try {
      return preset.values.firstWhere((v) => v.conditionId == conditionId);
    } catch (_) {
      return null;
    }
  }

  void _setValueForCondition(PromptConditionPreset preset, PromptCondition condition, String value, {String? customValue}) {
    setState(() {
      final existingIndex = preset.values.indexWhere((v) => v.conditionId == condition.id);
      final presetValue = PromptConditionPresetValue(
        presetId: preset.id,
        conditionId: condition.id,
        value: value,
        customValue: customValue,
      );
      if (existingIndex != -1) {
        preset.values[existingIndex] = presetValue;
      } else {
        preset.values.add(presetValue);
      }
    });
    _savePresetValues(preset);
  }

  Future<void> _savePresetValues(PromptConditionPreset preset) async {
    if (preset.id == null) return;
    await _db.deletePromptConditionPresetValuesByPreset(preset.id!);
    for (final value in preset.values) {
      await _db.createPromptConditionPresetValue(
        value.copyWith(presetId: preset.id),
      );
    }
  }

  TextEditingController _getCustomValueController(int conditionId, String? initialValue) {
    if (!_customValueControllers.containsKey(conditionId)) {
      _customValueControllers[conditionId] = TextEditingController(text: initialValue ?? '');
    }
    return _customValueControllers[conditionId]!;
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
                widget.character.name,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
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
                      style: _sectionHeaderStyle,
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
    final currentPreset = ModelPreset.fromString(widget.chatRoom.modelPreset);
    final providerOptions = ProviderOption.buildOptions(modelProvider.customProviders);

    // Determine current provider option for custom mode
    ProviderOption? currentProviderOption;
    if (currentPreset == ModelPreset.custom) {
      if (modelProvider.selectedProvider == ChatModelProvider.custom &&
          modelProvider.selectedCustomProviderId != null) {
        currentProviderOption = providerOptions.where(
          (o) => o.customProviderId == modelProvider.selectedCustomProviderId,
        ).firstOrNull;
      } else {
        currentProviderOption = providerOptions.where(
          (o) => o.builtInProvider == modelProvider.selectedProvider,
        ).firstOrNull;
      }
      currentProviderOption ??= providerOptions.firstOrNull;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '채팅창 설정',
          style: _sectionHeaderStyle,
        ),
        const SizedBox(height: 12),
        _buildVerticalSettingRow(
          label: '모델설정',
          child: CommonDropdownButton<ModelPreset>(
            value: currentPreset,
            items: ModelPreset.values,
            onChanged: (preset) {
              if (preset != null) {
                widget.onModelPresetChanged(preset.name);
              }
            },
            labelBuilder: (preset) => preset.displayName,
            size: CommonDropdownButtonSize.xsmall,
          ),
        ),
        if (currentPreset != ModelPreset.custom) ...[
          const SizedBox(height: 4),
          Text(
            currentPreset == ModelPreset.primary
                ? modelProvider.primaryModelLabel
                : modelProvider.subModelLabel,
            style: _subLabelStyle?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
        ],
        if (currentPreset == ModelPreset.custom) ...[
          const SizedBox(height: 8),
          _buildVerticalSettingRow(
            label: '제조사',
            child: CommonDropdownButton<ProviderOption>(
              value: currentProviderOption,
              items: providerOptions,
              onChanged: (option) async {
                if (option == null) return;
                final settingsProvider = context.read<ChatModelSettingsProvider>();
                if (option.isCustom) {
                  await settingsProvider.setCustomProviderSelection(option.customProviderId!);
                } else {
                  await settingsProvider.setProvider(option.builtInProvider!);
                }
                if (!mounted) return;
                widget.onModelChanged(settingsProvider.selectedModel);
              },
              labelBuilder: (option) => option.displayName,
              size: CommonDropdownButtonSize.xsmall,
            ),
          ),
          const SizedBox(height: 8),
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
        ],
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
        if (widget.chatRoom.selectedChatPromptId != null && _presets.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildPresetSection(),
        ],
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

  Widget _buildPresetSection() {
    final selectedPreset = _selectedPreset;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('프롬프트 프리셋', style: _fieldLabelStyle),
        const SizedBox(height: 4),
        CommonDropdownButton<int?>(
          value: selectedPreset?.id,
          items: _presets.map((p) => p.id).toList(),
          onChanged: (id) {
            widget.onPresetChanged(id);
            // Reset custom value controllers when preset changes
            for (final c in _customValueControllers.values) {
              c.dispose();
            }
            _customValueControllers.clear();
            setState(() {});
          },
          labelBuilder: (id) {
            if (id == null) return '없음';
            try {
              return _presets.firstWhere((p) => p.id == id).name;
            } catch (_) {
              return '없음';
            }
          },
          size: CommonDropdownButtonSize.xsmall,
        ),
        if (selectedPreset != null && _conditions.isNotEmpty) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _conditions.map((condition) =>
                _buildPresetConditionRow(selectedPreset, condition),
              ).toList(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPresetConditionRow(PromptConditionPreset preset, PromptCondition condition) {
    switch (condition.type) {
      case ConditionType.toggle:
        return _buildPresetToggleRow(preset, condition);
      case ConditionType.singleSelect:
        return _buildPresetSingleSelectRow(preset, condition);
      case ConditionType.variable:
        return _buildPresetVariableRow(preset, condition);
    }
  }

  Widget _buildPresetToggleRow(PromptConditionPreset preset, PromptCondition condition) {
    final presetValue = _getValueForCondition(preset, condition.id);
    final isOn = presetValue?.value == 'true';

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              condition.name.isEmpty ? '이름 없음' : condition.name,
              style: _subLabelStyle,
            ),
          ),
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                height: 28,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Switch(
                    value: isOn,
                    onChanged: (value) {
                      _setValueForCondition(preset, condition, value ? 'true' : 'false');
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetSingleSelectRow(PromptConditionPreset preset, PromptCondition condition) {
    final presetValue = _getValueForCondition(preset, condition.id);
    final selectedOption = condition.options.cast<PromptConditionOption?>().firstWhere(
      (o) => o!.name == presetValue?.value,
      orElse: () => null,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text(
              condition.name.isEmpty ? '이름 없음' : condition.name,
              style: _subLabelStyle,
            ),
          ),
          Expanded(
            flex: 2,
            child: CommonDropdownButton<PromptConditionOption>(
              value: selectedOption,
              items: condition.options,
              size: CommonDropdownButtonSize.xsmall,
              hintText: '항목을 선택하세요',
              onChanged: (value) {
                if (value != null) {
                  _setValueForCondition(preset, condition, value.name);
                }
              },
              labelBuilder: (o) => o.name,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetVariableRow(PromptConditionPreset preset, PromptCondition condition) {
    final presetValue = _getValueForCondition(preset, condition.id);
    final isCustom = presetValue?.value == PromptConditionPresetValue.customOptionKey;

    final optionsWithCustom = [
      ...condition.options,
      PromptConditionOption(id: -9999, name: '기타', order: condition.options.length),
    ];

    PromptConditionOption? selectedOption;
    if (isCustom) {
      selectedOption = optionsWithCustom.last;
    } else if (presetValue != null) {
      selectedOption = optionsWithCustom.cast<PromptConditionOption?>().firstWhere(
        (o) => o!.name == presetValue.value && o.id != -9999,
        orElse: () => null,
      );
    }

    final customController = _getCustomValueController(
      condition.id!,
      presetValue?.customValue,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 1,
                child: Text(
                  condition.name.isEmpty ? '이름 없음' : condition.name,
                  style: _subLabelStyle,
                ),
              ),
              Expanded(
                flex: 2,
                child: CommonDropdownButton<PromptConditionOption>(
                  value: selectedOption,
                  items: optionsWithCustom,
                  size: CommonDropdownButtonSize.xsmall,
                  hintText: '항목을 선택하세요',
                  onChanged: (value) {
                    if (value != null) {
                      if (value.id == -9999) {
                        _setValueForCondition(
                          preset,
                          condition,
                          PromptConditionPresetValue.customOptionKey,
                          customValue: customController.text,
                        );
                      } else {
                        _setValueForCondition(preset, condition, value.name);
                        customController.clear();
                      }
                    }
                  },
                  labelBuilder: (o) => o.name,
                ),
              ),
            ],
          ),
          if (isCustom) ...[
            const SizedBox(height: 4),
            CommonEditText(
              controller: customController,
              size: CommonEditTextSize.small,
              hintText: '값을 입력하세요',
              onFocusLost: (value) {
                _setValueForCondition(
                  preset,
                  condition,
                  PromptConditionPresetValue.customOptionKey,
                  customValue: value.trim(),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVerticalSettingRow({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _fieldLabelStyle),
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
          Expanded(
            flex: 3,
            child: Text(label, style: _subLabelStyle),
          ),
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                height: 28,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Switch(
                    value: value,
                    onChanged: onChanged,
                  ),
                ),
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
                labelStyle: _sectionHeaderStyle,
                labelSpacing: 8,
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
                  labelStyle: _sectionHeaderStyle,
                  labelSpacing: 8,
                  child: CommonEditText(
                    controller: _personaNameController,
                    hintText: '페르소나 이름',
                    size: CommonEditTextSize.small,
                  ),
                ),
                CommonFieldSection(
                  label: '페르소나 설명',
                  labelStyle: _sectionHeaderStyle,
                  labelSpacing: 8,
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
                style: _sectionHeaderStyle,
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
        title: Text(folder.name, style: _sectionHeaderStyle),
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
    return Column(
      children: [
        // Toggles
        SwitchListTile(
          secondary: const Icon(Icons.auto_awesome, size: 20),
          title: const Text('자동 요약'),
          dense: true,
          value: _autoSummaryEnabled,
          onChanged: (value) async {
            setState(() => _autoSummaryEnabled = value);
            final settings = await _db.getAutoSummarySettings(0);
            if (settings != null) {
              await _db.updateAutoSummarySettings(
                settings.copyWith(isEnabled: value),
              );
            }
          },
        ),
        if (_autoSummaryEnabled)
          SwitchListTile(
            secondary: const Icon(Icons.smart_toy_outlined, size: 20),
            title: const Text('에이전트 모드'),
            dense: true,
            value: _agentEnabled,
            onChanged: (value) async {
              setState(() => _agentEnabled = value);
              final settings = await _db.getAutoSummarySettings(0);
              if (settings != null) {
                await _db.updateAutoSummarySettings(
                  settings.copyWith(isAgentEnabled: value),
                );
              }
            },
          ),
        const Divider(height: 1),
        // Content area
        Expanded(
          child: _autoSummaryEnabled && _agentEnabled
              ? _buildAgentView()
              : _buildClassicSummaryView(),
        ),
      ],
    );
  }

  Widget _buildClassicSummaryView() {
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
                    style: _sectionHeaderStyle,
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

  // ==================== Agent 뷰 ====================

  static const _agentTabTypes = AgentEntryType.values;
  static const _agentTabIcons = [
    Icons.auto_stories,
    Icons.person_outline,
    Icons.place_outlined,
    Icons.inventory_2_outlined,
    Icons.emoji_events_outlined,
  ];

  Widget _buildAgentView() {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Column(
      children: [
        // Sub-tab chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: List.generate(_agentTabTypes.length, (i) {
              final type = _agentTabTypes[i];
              final count = _agentEntries.where((e) => e.entryType == type).length;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: FilterChip(
                  avatar: Icon(_agentTabIcons[i], size: 16),
                  label: Text('${type.displayName} ($count)'),
                  selected: _agentSubTabIndex == i,
                  onSelected: (_) => setState(() => _agentSubTabIndex = i),
                  visualDensity: VisualDensity.compact,
                ),
              );
            }),
          ),
        ),
        const Divider(height: 1),
        // Entry list for selected type
        Expanded(
          child: _buildAgentEntryList(
            _agentTabTypes[_agentSubTabIndex],
            bottomInset,
          ),
        ),
      ],
    );
  }

  Widget _buildAgentEntryList(AgentEntryType type, double bottomInset) {
    final entries = _agentEntries.where((e) => e.entryType == type).toList();

    if (entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            '${type.displayName} 데이터가 없습니다.\n채팅을 진행하면 자동으로 생성됩니다.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottomInset),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final isExpanded = _expandedAgentEntryIds.contains(entry.id);

        return CommonEditableExpandableItem(
          key: ValueKey('agent_${entry.id}'),
          icon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _agentTabIcons[_agentTabTypes.indexOf(type)],
                size: 20,
                color: entry.isActive
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: entry.isActive
                      ? Colors.green
                      : Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
            ],
          ),
          name: entry.name,
          isExpanded: isExpanded,
          showNameField: false,
          onToggleExpanded: () {
            setState(() {
              if (isExpanded) {
                _expandedAgentEntryIds.remove(entry.id!);
              } else {
                _expandedAgentEntryIds.add(entry.id!);
              }
            });
          },
          onDelete: () => _deleteAgentEntry(entry),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Active toggle
              Row(
                children: [
                  Text(
                    entry.isActive ? '활성' : '비활성',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: entry.isActive
                          ? Colors.green
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  Switch(
                    value: entry.isActive,
                    onChanged: (value) => _toggleAgentEntryActive(entry, value),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Data fields
              ..._buildAgentEntryFields(entry),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildAgentEntryFields(AgentEntry entry) {
    final fields = <Widget>[];
    final data = entry.data;

    void addField(String label, dynamic value) {
      if (value == null) return;
      final text = value is List ? value.join(', ') : value.toString();
      if (text.isEmpty) return;
      fields.add(Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              text,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ));
    }

    switch (entry.entryType) {
      case AgentEntryType.episode:
        addField('날짜/시간', data['date_range']);
        addField('등장인물', data['characters']);
        addField('장소', data['locations']);
        addField('요약', data['summary_text']);
      case AgentEntryType.character:
        addField('외형', data['appearance']);
        addField('성격', data['personality']);
        addField('과거', data['past']);
        addField('능력', data['abilities']);
        addField('작중행적', data['story_actions']);
        addField('대사 스타일', data['dialogue_style']);
        addField('소지품', data['possessions']);
      case AgentEntryType.location:
        addField('위치', data['parent_location']);
        addField('특징', data['features']);
        if (data['ascii_map'] != null) addField('맵', data['ascii_map']);
        addField('관련 에피소드', data['related_episodes']);
      case AgentEntryType.item:
        addField('키워드', data['keywords']);
        addField('특징', data['features']);
        addField('관련 에피소드', data['related_episodes']);
      case AgentEntryType.event:
        addField('일시', data['datetime']);
        addField('개요', data['overview']);
        addField('결과', data['result']);
        addField('관련 에피소드', data['related_episodes']);
    }

    // Related names (cross-references)
    if (entry.relatedNames.isNotEmpty) {
      fields.add(Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Wrap(
          spacing: 4,
          runSpacing: 4,
          children: entry.relatedNames.map((name) {
            return Chip(
              label: Text(name),
              visualDensity: VisualDensity.compact,
              labelStyle: Theme.of(context).textTheme.labelSmall,
              padding: EdgeInsets.zero,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            );
          }).toList(),
        ),
      ));
    }

    return fields;
  }

  Future<void> _toggleAgentEntryActive(AgentEntry entry, bool isActive) async {
    if (entry.id == null) return;
    await _db.setAgentEntryActive(entry.id!, isActive);
    await _loadData();
  }

  Future<void> _deleteAgentEntry(AgentEntry entry) async {
    if (entry.id == null) return;
    final confirmed = await CommonDialog.showDeleteConfirmation(
      context: context,
      itemName: entry.name,
    );
    if (!confirmed) return;

    await _db.deleteAgentEntry(entry.id!);
    _agentEntryControllers[entry.id!]?.dispose();
    _agentEntryControllers.remove(entry.id!);
    await _loadData();

    if (!mounted) return;
    CommonDialog.showSnackBar(context: context, message: '${entry.name} 삭제됨');
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
