import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
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
import '../../../providers/chat_background_provider.dart';
import '../../../providers/chat_model_provider.dart';
import '../../../models/chat/agent_entry.dart';
import '../../../widgets/common/common_dropdown_button.dart';
import '../../../widgets/common/common_edit_text.dart';
import '../../../widgets/common/common_field_section.dart';
import 'drawer_agent_panel.dart';
import 'drawer_lorebook_panel.dart';
import 'drawer_summary_panel.dart';

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
  final ValueChanged<int?> onAutoPinByMessageCountChanged;
  final ValueChanged<int?> onPresetChanged;
  final ValueChanged<bool> onShowImagesChanged;

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
    required this.onAutoPinByMessageCountChanged,
    required this.onPresetChanged,
    required this.onShowImagesChanged,
  });

  @override
  ChatRoomDrawerState createState() => ChatRoomDrawerState();
}

class ChatRoomDrawerState extends State<ChatRoomDrawer> {
  final DatabaseHelper _db = DatabaseHelper.instance;

  // Keys for child panels that need save-on-tab-change
  final _lorebookKey = GlobalKey<DrawerLorebookPanelState>();
  final _summaryKey = GlobalKey<DrawerSummaryPanelState>();

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

  late TextEditingController _pinMessageCountController;

  List<ChatSummary> _summaries = [];

  // Agent mode state
  bool _autoSummaryEnabled = false;
  bool _agentEnabled = false;
  List<AgentEntry> _agentEntries = [];

  bool _isLoading = true;

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
        _lorebookKey.currentState?.save();
        break;
      case DrawerTab.summary:
        _summaryKey.currentState?.saveAll();
        break;
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
      for (final book in books) {
        await _loadDrawerBookImages(book);
      }
      folder.characterBooks.addAll(books);
    }
    final standaloneBooks = await _db.readStandaloneCharacterBooks(characterId);
    for (final book in standaloneBooks) {
      await _loadDrawerBookImages(book);
    }

    final summaries = await _db.getChatSummaries(widget.chatRoom.id!);

    // Load agent settings and entries
    final summarySettings = await _db.getAutoSummarySettings(0);
    final agentEntries = await _db.getAgentEntries(widget.chatRoom.id!);

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

  /// Loads the character-book's images (if any) into the in-memory model.
  /// Drawer is read-only, so this is purely for display.
  Future<void> _loadDrawerBookImages(CharacterBook book) async {
    if (book.id == null || book.id! <= 0) return;
    final images = await _db.readCharacterBookImages(book.id!);
    book.images
      ..clear()
      ..addAll(images);
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
    final newPersonaName = AppLocalizations.of(context).drawerNewPersona;
    final characterId = widget.character.id!;
    final personas = await _db.readPersonas(characterId);
    final newPersona = Persona(
      characterId: characterId,
      name: newPersonaName,
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
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildChip(
              icon: Icons.chat_outlined,
              label: l10n.drawerTabInfo,
              tab: DrawerTab.info,
            ),
            const SizedBox(width: 8),
            _buildChip(
              icon: Icons.face_outlined,
              label: l10n.drawerTabPersona,
              tab: DrawerTab.persona,
            ),
            const SizedBox(width: 8),
            _buildChip(
              icon: Icons.person_outlined,
              label: l10n.drawerTabCharacter,
              tab: DrawerTab.character,
            ),
            const SizedBox(width: 8),
            _buildChip(
              icon: Icons.description_outlined,
              label: l10n.drawerTabLorebook,
              tab: DrawerTab.lorebook,
            ),
            const SizedBox(width: 8),
            _buildChip(
              icon: Icons.history,
              label: l10n.drawerTabSummary,
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
    final l10n = AppLocalizations.of(context);
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
                      l10n.drawerChatMemo,
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
                  hintText: l10n.drawerMemoHint,
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
    final l10n = AppLocalizations.of(context);
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
          l10n.drawerChatSettings,
          style: _sectionHeaderStyle,
        ),
        const SizedBox(height: 12),
        _buildVerticalSettingRow(
          label: l10n.drawerModelPreset,
          child: CommonDropdownButton<ModelPreset>(
            value: currentPreset,
            items: ModelPreset.values,
            onChanged: (preset) {
              if (preset != null) {
                widget.onModelPresetChanged(preset.name);
              }
            },
            labelBuilder: (preset) => switch (preset) {
              ModelPreset.primary => l10n.modelPresetPrimary,
              ModelPreset.secondary => l10n.modelPresetSecondary,
              ModelPreset.custom => l10n.modelPresetCustom,
            },
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
            label: l10n.drawerProvider,
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
            label: l10n.drawerChatModel,
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
          label: l10n.drawerChatPrompt,
          child: CommonDropdownButton<int?>(
            value: widget.chatRoom.selectedChatPromptId,
            items: [...widget.chatPrompts.map((p) => p.id), null],
            onChanged: (id) => widget.onPromptChanged(id),
            labelBuilder: (id) {
              if (id == null) return l10n.drawerNone;
              return widget.chatPrompts.firstWhere((p) => p.id == id).name;
            },
            size: CommonDropdownButtonSize.xsmall,
          ),
        ),
        if (widget.chatRoom.selectedChatPromptId != null && _presets.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildPresetSection(),
        ],
      ],
    );
  }

  Widget _buildPresetSection() {
    final l10n = AppLocalizations.of(context);
    final selectedPreset = _selectedPreset;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.drawerPromptPreset, style: _fieldLabelStyle),
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
            if (id == null) return l10n.drawerNone;
            try {
              return _presets.firstWhere((p) => p.id == id).name;
            } catch (_) {
              return l10n.drawerNone;
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
        const SizedBox(height: 8),
        Row(
          children: [
            Text(l10n.drawerShowImages, style: _fieldLabelStyle),
            const Spacer(),
            SizedBox(
              height: 28,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Switch(
                  value: widget.chatRoom.showImages,
                  onChanged: (value) {
                    widget.onShowImagesChanged(value);
                  },
                ),
              ),
            ),
          ],
        ),
        Consumer<ChatBackgroundProvider>(
          builder: (context, provider, _) => Row(
            children: [
              Text(l10n.settingsBackgroundImage, style: _fieldLabelStyle),
              const Spacer(),
              SizedBox(
                height: 28,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Switch(
                    value: provider.enabled,
                    onChanged: provider.setEnabled,
                  ),
                ),
              ),
            ],
          ),
        ),
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
    final l10n = AppLocalizations.of(context);
    final presetValue = _getValueForCondition(preset, condition.id);
    final isOn = presetValue?.value == 'true';

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              condition.name.isEmpty ? l10n.drawerNoName : condition.name,
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
    final l10n = AppLocalizations.of(context);
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
              condition.name.isEmpty ? l10n.drawerNoName : condition.name,
              style: _subLabelStyle,
            ),
          ),
          Expanded(
            flex: 2,
            child: CommonDropdownButton<PromptConditionOption>(
              value: selectedOption,
              items: condition.options,
              size: CommonDropdownButtonSize.xsmall,
              hintText: l10n.drawerSelectItem,
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
    final l10n = AppLocalizations.of(context);
    final presetValue = _getValueForCondition(preset, condition.id);
    final isCustom = presetValue?.value == PromptConditionPresetValue.customOptionKey;

    final optionsWithCustom = [
      ...condition.options,
      PromptConditionOption(id: -9999, name: l10n.drawerOther, order: condition.options.length),
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
                  condition.name.isEmpty ? l10n.drawerNoName : condition.name,
                  style: _subLabelStyle,
                ),
              ),
              Expanded(
                flex: 2,
                child: CommonDropdownButton<PromptConditionOption>(
                  value: selectedOption,
                  items: optionsWithCustom,
                  size: CommonDropdownButtonSize.xsmall,
                  hintText: l10n.drawerSelectItem,
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
              hintText: l10n.drawerEnterValue,
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
    final l10n = AppLocalizations.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
            children: [
              CommonFieldSection(
                label: l10n.drawerSelectPersona,
                labelStyle: _sectionHeaderStyle,
                labelSpacing: 8,
                child: CommonDropdownButton<int?>(
                  value: widget.chatRoom.selectedPersonaId,
                  items: [null, ...widget.personas.map((p) => p.id), _createNewPersonaId],
                  onChanged: _onPersonaDropdownChanged,
                  labelBuilder: (id) {
                    if (id == null) return l10n.drawerNone;
                    if (id == _createNewPersonaId) return l10n.drawerCreateNewPersona;
                    return widget.personas.firstWhere((p) => p.id == id).name;
                  },
                  size: CommonDropdownButtonSize.xsmall,
                ),
              ),
              if (_persona != null) ...[
                CommonFieldSection(
                  label: l10n.drawerPersonaName,
                  labelStyle: _sectionHeaderStyle,
                  labelSpacing: 8,
                  child: CommonEditText(
                    controller: _personaNameController,
                    hintText: l10n.drawerPersonaName,
                    size: CommonEditTextSize.small,
                  ),
                ),
                CommonFieldSection(
                  label: l10n.drawerPersonaDescription,
                  labelStyle: _sectionHeaderStyle,
                  labelSpacing: 8,
                  bottomSpacing: 0,
                  child: CommonEditText(
                    controller: _personaContentController,
                    hintText: l10n.drawerPersonaDescriptionHint,
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
    final l10n = AppLocalizations.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
            children: [
              Text(
                l10n.drawerCharacter,
                style: _sectionHeaderStyle,
              ),
              const SizedBox(height: 8),
              CommonEditText(
                controller: _descriptionController,
                hintText: l10n.drawerCharacterDescriptionHint,
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
    return DrawerLorebookPanel(
      key: _lorebookKey,
      folders: _folders,
      standaloneBooks: _standaloneBooks,
      db: _db,
      characterId: widget.character.id!,
    );
  }

  // ==================== 요약 탭 ====================

  Widget _buildSummaryTab() {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        // Toggles
        SwitchListTile(
          secondary: const Icon(Icons.auto_awesome, size: 20),
          title: Text(l10n.drawerAutoSummary),
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
            title: Text(l10n.drawerAgentMode),
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
        if (_autoSummaryEnabled)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: _buildVerticalSettingRow(
              label: l10n.drawerSummaryMessageCount,
              child: SizedBox(
                width: double.infinity,
                child: CommonEditText(
                  controller: _pinMessageCountController,
                  hintText: l10n.drawerMessageCountHint,
                  size: CommonEditTextSize.small,
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final count = int.tryParse(value);
                    widget.onAutoPinByMessageCountChanged(count != null && count > 0 ? count : null);
                  },
                ),
              ),
            ),
          ),
        const Divider(height: 1),
        // Content area
        Expanded(
          child: _autoSummaryEnabled && _agentEnabled
              ? DrawerAgentPanel(
                  agentEntries: _agentEntries,
                  db: _db,
                  onDataChanged: _loadData,
                )
              : DrawerSummaryPanel(
                  key: _summaryKey,
                  summaries: _summaries,
                  chatRoomId: widget.chatRoom.id!,
                  db: _db,
                  onDataChanged: _loadData,
                ),
        ),
      ],
    );
  }

}
