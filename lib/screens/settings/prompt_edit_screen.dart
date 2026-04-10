import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../l10n/app_localizations.dart';
import '../../constants/ui_constants.dart';
import '../../constants/ai_model_constants.dart';
import '../../database/database_helper.dart';
import '../../models/prompt/chat_prompt.dart';
import '../../models/prompt/prompt_item.dart';
import '../../models/prompt/prompt_item_folder.dart';
import '../../models/prompt/prompt_parameters.dart';
import '../../utils/common_dialog.dart';
import '../../widgets/common/common_custom_text_field.dart';
import '../../widgets/common/common_appbar.dart';
import '../../widgets/common/common_dropdown_button.dart';
import '../../widgets/common/common_edit_text.dart';
import '../../widgets/common/common_info_box.dart';
import '../../widgets/common/common_parameter_field.dart';
import '../../widgets/common/common_title_medium.dart';
import '../../models/prompt/prompt_condition.dart';
import '../../models/prompt/prompt_condition_preset.dart';
import '../../models/prompt/prompt_regex_rule.dart';
import 'tabs/prompt_items_tab.dart';
import 'tabs/prompt_other_settings_tab.dart';
import 'tabs/prompt_regex_tab.dart';

class PromptEditScreen extends StatefulWidget {
  final ChatPrompt? prompt;

  const PromptEditScreen({super.key, this.prompt});

  @override
  State<PromptEditScreen> createState() => _PromptEditScreenState();
}

class _PromptEditScreenState extends State<PromptEditScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final DatabaseHelper _db = DatabaseHelper.instance;
  bool _isLoading = false;

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedModel = AIModelConstants.all;

  PromptParameters _parameters = const PromptParameters();

  final List<PromptItemFolder> _folders = [];
  final List<PromptItem> _standaloneItems = [];
  final Map<int, TextEditingController> _contentControllers = {};
  int _nextTempId = -1;
  int _getNextTempId() => _nextTempId--;
  int _nextFolderTempId = -1;
  int _getNextFolderTempId() => _nextFolderTempId--;

  // Regex rules
  final List<PromptRegexRule> _regexRules = [];
  final Map<int, TextEditingController> _regexPatternControllers = {};
  final Map<int, TextEditingController> _regexReplacementControllers = {};
  int _nextRegexTempId = -1;
  int _getNextRegexTempId() => _nextRegexTempId--;

  // Conditions
  final List<PromptCondition> _conditions = [];
  int _nextConditionTempId = -1;
  int _getNextConditionTempId() => _nextConditionTempId--;
  int _nextConditionOptionTempId = -1;
  int _getNextConditionOptionTempId() => _nextConditionOptionTempId--;
  bool _conditionsSectionExpanded = true;

  // Presets
  final List<PromptConditionPreset> _presets = [];
  int _nextPresetTempId = -1;
  int _getNextPresetTempId() => _nextPresetTempId--;
  bool _presetsSectionExpanded = true;

  // Parameter controllers
  final _maxInputTokensController = TextEditingController();
  final _maxOutputTokensController = TextEditingController();
  final _thinkingTokensController = TextEditingController();
  final _thinkingMaxTokensController = TextEditingController();

  bool get _isEditing => widget.prompt != null;
  bool get _isReadOnly => false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);

    if (_isEditing) {
      _loadPromptData();
    } else {
      _initDefaultItems();

      // New prompt: create default preset
      _presets.add(PromptConditionPreset(
        id: _getNextPresetTempId(),
        name: AppLocalizations.of(context).promptEditDefaultName,
        isDefault: true,
        order: 0,
      ));
    }
  }

  Future<void> _initDefaultItems() async {
    final jsonString = await rootBundle.loadString(
      'assets/defaults/chat_prompts/default_roleplay.json',
    );
    final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
    final prompt = ChatPrompt.fromJson(jsonData);

    final folders = prompt.foldersFromJson(jsonData);
    for (final folder in folders) {
      final folderId = _getNextFolderTempId();
      final items = <PromptItem>[];
      for (final item in folder.items) {
        final tempId = _getNextTempId();
        final newItem = item.copyWith(id: tempId, folderId: folderId);
        items.add(newItem);
        _contentControllers[tempId] = TextEditingController(text: newItem.content);
      }
      _folders.add(PromptItemFolder(
        id: folderId,
        name: folder.name,
        order: folder.order,
        isExpanded: folder.isExpanded,
        items: items,
      ));
    }

    final standaloneItems = prompt.standaloneItemsFromJson(jsonData);
    for (final item in standaloneItems) {
      final tempId = _getNextTempId();
      final newItem = item.copyWith(id: tempId);
      _standaloneItems.add(newItem);
      _contentControllers[tempId] = TextEditingController(text: newItem.content);
    }

    if (mounted) setState(() {});
  }

  void _loadPromptData() async {
    final prompt = widget.prompt!;
    _nameController.text = prompt.name;
    _descriptionController.text = prompt.description ?? '';
    _selectedModel = prompt.supportedModel;
    _parameters = prompt.parameters ?? const PromptParameters();

    // Load parameter values to controllers
    _maxInputTokensController.text = _parameters.maxInputTokens?.toString() ?? '';
    _maxOutputTokensController.text = _parameters.maxOutputTokens?.toString() ?? '';
    _thinkingTokensController.text = _parameters.thinkingTokens?.toString() ?? '';
    _thinkingMaxTokensController.text = _parameters.thinkingMaxTokens?.toString() ?? '';

    // Load folders and their items
    final folders = await _db.readPromptItemFolders(prompt.id!);
    for (var folder in folders) {
      final folderItems = await _db.readPromptItemsByFolder(folder.id!);
      folder.items.addAll(folderItems);
      for (var item in folderItems) {
        _contentControllers[item.id!] = TextEditingController(text: item.content);
      }
    }
    _folders.addAll(folders);

    // Load standalone items (items without folder)
    final standaloneItems = await _db.readStandalonePromptItems(prompt.id!);
    _standaloneItems.addAll(standaloneItems);
    for (var item in standaloneItems) {
      _contentControllers[item.id!] = TextEditingController(text: item.content);
    }

    // Load regex rules
    final regexRules = await _db.readPromptRegexRules(prompt.id!);
    _regexRules.addAll(regexRules);
    for (var rule in regexRules) {
      _regexPatternControllers[rule.id!] = TextEditingController(text: rule.pattern);
      _regexReplacementControllers[rule.id!] = TextEditingController(text: rule.replacement);
    }

    // Load conditions
    final conditions = await _db.readPromptConditions(prompt.id!);
    for (var condition in conditions) {
      final options = await _db.readPromptConditionOptions(condition.id!);
      condition.options.addAll(options);
    }
    _conditions.addAll(conditions);

    // Load presets
    final presets = await _db.readPromptConditionPresets(prompt.id!);
    for (var preset in presets) {
      final values = await _db.readPromptConditionPresetValues(preset.id!);
      preset.values.addAll(values);
    }
    _presets.addAll(presets);

    // Ensure default preset exists
    if (_presets.isEmpty || !_presets.any((p) => p.isDefault)) {
      _presets.insert(0, PromptConditionPreset(
        id: _getNextPresetTempId(),
        name: AppLocalizations.of(context).promptEditDefaultName,
        isDefault: true,
        order: 0,
      ));
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    for (var controller in _contentControllers.values) {
      controller.dispose();
    }
    _maxInputTokensController.dispose();
    _maxOutputTokensController.dispose();
    _thinkingTokensController.dispose();
    _thinkingMaxTokensController.dispose();
    for (var controller in _regexPatternControllers.values) {
      controller.dispose();
    }
    for (var controller in _regexReplacementControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _syncParametersFromControllers() {
    // TextField controller 값을 _parameters에 동기화
    final maxInputTokens = _maxInputTokensController.text.isEmpty
        ? null
        : int.tryParse(_maxInputTokensController.text);
    final maxOutputTokens = _maxOutputTokensController.text.isEmpty
        ? null
        : int.tryParse(_maxOutputTokensController.text);
    final thinkingTokens = _thinkingTokensController.text.isEmpty
        ? null
        : int.tryParse(_thinkingTokensController.text);
    final thinkingMaxTokens = _thinkingMaxTokensController.text.isEmpty
        ? null
        : int.tryParse(_thinkingMaxTokensController.text);

    _parameters = _parameters.copyWith(
      maxInputTokens: maxInputTokens,
      maxOutputTokens: maxOutputTokens,
      thinkingTokens: thinkingTokens,
      thinkingMaxTokens: thinkingMaxTokens,
    );
  }

  Future<void> _savePrompt() async {
    FocusScope.of(context).unfocus();
    await Future.delayed(Duration.zero);

    if (!_formKey.currentState!.validate()) {
      _tabController.animateTo(0);
      return;
    }

    // Controller 값을 parameters에 반영
    _syncParametersFromControllers();

    setState(() => _isLoading = true);

    try {
      int promptId;

      if (_isEditing) {
        final updated = widget.prompt!.copyWith(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          supportedModel: _selectedModel,
          parameters: _parameters,
          updatedAt: DateTime.now(),
        );
        await _db.updateChatPrompt(updated);
        promptId = widget.prompt!.id!;

        final existingItems = await _db.readPromptItemsByChatPrompt(promptId);
        for (var item in existingItems) {
          await _db.deletePromptItem(item.id!);
        }
      } else {
        final prompt = ChatPrompt(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          supportedModel: _selectedModel,
          parameters: _parameters,
        );
        promptId = await _db.createChatPrompt(prompt);
      }

      // Delete existing folders
      final existingFolders = await _db.readPromptItemFolders(promptId);
      for (var folder in existingFolders) {
        await _db.deletePromptItemFolder(folder.id!);
      }

      // Save conditions first and build old->new ID mapping
      await _db.deletePromptConditionsByPrompt(promptId);
      final Map<int, int> conditionIdMap = {};
      for (int i = 0; i < _conditions.length; i++) {
        final condition = _conditions[i];
        final oldId = condition.id;
        final conditionId = await _db.createPromptCondition(
          condition.copyWith(
            id: null,
            chatPromptId: promptId,
            order: i,
          ),
        );
        if (oldId != null) {
          conditionIdMap[oldId] = conditionId;
        }
        for (int j = 0; j < condition.options.length; j++) {
          await _db.createPromptConditionOption(
            condition.options[j].copyWith(
              id: null,
              conditionId: conditionId,
              order: j,
            ),
          );
        }
      }

      // Save presets
      await _db.deletePromptConditionPresetsByPrompt(promptId);
      for (int i = 0; i < _presets.length; i++) {
        final preset = _presets[i];
        final presetId = await _db.createPromptConditionPreset(
          preset.copyWith(
            id: null,
            chatPromptId: promptId,
            order: i,
          ),
        );
        for (final value in preset.values) {
          final newConditionId = conditionIdMap[value.conditionId] ?? value.conditionId;
          await _db.createPromptConditionPresetValue(
            value.copyWith(
              id: null,
              presetId: presetId,
              conditionId: newConditionId,
            ),
          );
        }
      }

      // Remap conditionId from old/temp IDs to new DB IDs
      int? remapConditionId(int? oldId) {
        if (oldId == null) return null;
        return conditionIdMap[oldId] ?? oldId;
      }

      // Save folders and their items
      for (final folder in _folders) {
        final folderId = await _db.createPromptItemFolder(
          folder.copyWith(
            id: null,
            chatPromptId: promptId,
          ),
        );

        for (int j = 0; j < folder.items.length; j++) {
          final item = folder.items[j];
          final controller = _contentControllers[item.id]!;

          await _db.createPromptItem(
            item.copyWithNullableFolderId(
              id: null,
              chatPromptId: promptId,
              folderId: folderId,
              content: controller.text.trim(),
              order: j,
              conditionId: remapConditionId(item.conditionId),
            ),
          );
        }
      }

      // Save standalone items
      for (final item in _standaloneItems) {
        final controller = _contentControllers[item.id]!;

        await _db.createPromptItem(
          item.copyWithNullableFolderId(
            id: null,
            chatPromptId: promptId,
            folderId: null,
            content: controller.text.trim(),
            conditionId: remapConditionId(item.conditionId),
          ),
        );
      }

      // Save regex rules
      await _db.deletePromptRegexRulesByPrompt(promptId);
      for (int i = 0; i < _regexRules.length; i++) {
        final rule = _regexRules[i];
        final patternCtrl = _regexPatternControllers[rule.id];
        final replacementCtrl = _regexReplacementControllers[rule.id];

        await _db.createPromptRegexRule(
          rule.copyWith(
            id: null,
            chatPromptId: promptId,
            pattern: patternCtrl?.text ?? rule.pattern,
            replacement: replacementCtrl?.text ?? rule.replacement,
            order: i,
          ),
        );
      }

      if (mounted) {
        final l10n = AppLocalizations.of(context);
        CommonDialog.showSnackBar(
          context: context,
          message: _isEditing ? l10n.promptEditUpdated : l10n.promptEditCreated,
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        CommonDialog.showSnackBar(
          context: context,
          message: AppLocalizations.of(context).promptEditSaveFailed(e.toString()),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  int _getNextMixedOrder() {
    int maxOrder = -1;
    for (final folder in _folders) {
      if (folder.order > maxOrder) maxOrder = folder.order;
    }
    for (final item in _standaloneItems) {
      if (item.order > maxOrder) maxOrder = item.order;
    }
    return maxOrder + 1;
  }

  void _addItem(PromptItemFolder? folder) {
    setState(() {
      final newItem = PromptItem(
        id: _getNextTempId(),
        role: PromptRole.system,
        content: '',
        order: folder != null ? folder.items.length : _getNextMixedOrder(),
        isExpanded: true,
      );
      _contentControllers[newItem.id!] = TextEditingController();

      if (folder != null) {
        final folderIndex = _folders.indexOf(folder);
        if (folderIndex != -1) {
          _folders[folderIndex].items.add(newItem);
        }
      } else {
        _standaloneItems.add(newItem);
      }
    });
  }

  void _addFolder() {
    final newFolderName = AppLocalizations.of(context).promptEditNewFolderName;
    setState(() {
      final newFolder = PromptItemFolder(
        id: _getNextFolderTempId(),
        name: newFolderName,
        order: _getNextMixedOrder(),
        isExpanded: true,
      );
      _folders.add(newFolder);
    });
  }

  Future<void> _deleteItem(PromptItem item) async {
    final confirmed = await CommonDialog.showDeleteConfirmation(
      context: context,
      itemName: item.name ?? item.role.displayName,
    );

    if (confirmed) {
      setState(() {
        // Check in standalone items
        if (_standaloneItems.remove(item)) {
          _contentControllers.remove(item.id)?.dispose();
          return;
        }

        // Check in folders
        for (var folder in _folders) {
          if (folder.items.remove(item)) {
            _contentControllers.remove(item.id)?.dispose();
            return;
          }
        }
      });
    }
  }

  Future<void> _deleteFolder(PromptItemFolder folder) async {
    final confirmed = await CommonDialog.showDeleteConfirmation(
      context: context,
      itemName: folder.name,
    );

    if (confirmed) {
      setState(() {
        int nextOrder = _getNextMixedOrder();
        for (var item in folder.items) {
          _standaloneItems.add(item.copyWithNullableFolderId(folderId: null, order: nextOrder++));
        }
        _folders.remove(folder);
      });
    }
  }

  void _moveItemToFolder(PromptItem item, PromptItemFolder? fromFolder, PromptItemFolder toFolder) {
    setState(() {
      // Remove from source
      if (fromFolder != null) {
        fromFolder.items.remove(item);
      } else {
        _standaloneItems.remove(item);
      }

      // Add to target folder
      final updatedItem = item.copyWithNullableFolderId(folderId: toFolder.id);
      toFolder.items.add(updatedItem);
    });
  }

  void _moveItemOutOfFolder(PromptItem item, PromptItemFolder fromFolder) {
    setState(() {
      fromFolder.items.remove(item);
      final updatedItem = item.copyWithNullableFolderId(
        folderId: null,
        order: _getNextMixedOrder(),
      );
      _standaloneItems.add(updatedItem);
    });
  }

  void _reorderItem(PromptItem item, int targetIndex, PromptItemFolder? folder) {
    setState(() {
      if (folder != null) {
        final list = folder.items;
        final fromIndex = list.indexOf(item);
        if (fromIndex != -1) {
          list.removeAt(fromIndex);
          final insertIndex = fromIndex < targetIndex ? targetIndex - 1 : targetIndex;
          list.insert(insertIndex, item);
        }
      } else {
        _reassignMixedOrder(movedItem: item, targetMixedIndex: targetIndex);
      }
    });
  }

  void _reorderFolder(PromptItemFolder folder, int targetMixedIndex) {
    setState(() {
      _reassignMixedOrder(movedFolder: folder, targetMixedIndex: targetMixedIndex);
    });
  }

  void _reassignMixedOrder({PromptItem? movedItem, PromptItemFolder? movedFolder, required int targetMixedIndex}) {
    final entries = <Object>[];
    for (final f in _folders) entries.add(f);
    for (final i in _standaloneItems) entries.add(i);
    entries.sort((a, b) {
      final orderA = a is PromptItemFolder ? a.order : (a as PromptItem).order;
      final orderB = b is PromptItemFolder ? b.order : (b as PromptItem).order;
      return orderA.compareTo(orderB);
    });

    final moved = movedItem ?? movedFolder!;
    final fromIndex = entries.indexOf(moved);
    if (fromIndex != -1) {
      entries.removeAt(fromIndex);
      final insertIndex = fromIndex < targetMixedIndex ? targetMixedIndex - 1 : targetMixedIndex;
      entries.insert(insertIndex.clamp(0, entries.length), moved);
    }

    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      if (entry is PromptItemFolder) {
        entry.order = i;
      } else if (entry is PromptItem) {
        final idx = _standaloneItems.indexOf(entry);
        if (idx != -1) {
          _standaloneItems[idx] = entry.copyWith(order: i);
        }
      }
    }
  }

  void _addRegexRule() {
    setState(() {
      final newRule = PromptRegexRule(
        id: _getNextRegexTempId(),
        name: '',
        target: RegexTarget.disabled,
        order: _regexRules.length,
        isExpanded: true,
      );
      _regexRules.add(newRule);
      _regexPatternControllers[newRule.id!] = TextEditingController();
      _regexReplacementControllers[newRule.id!] = TextEditingController();
    });
  }

  Future<void> _deleteRegexRule(PromptRegexRule rule) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await CommonDialog.showDeleteConfirmation(
      context: context,
      itemName: rule.name.isEmpty ? l10n.promptEditDefaultRuleName : rule.name,
    );

    if (confirmed) {
      setState(() {
        _regexRules.remove(rule);
        _regexPatternControllers.remove(rule.id)?.dispose();
        _regexReplacementControllers.remove(rule.id)?.dispose();
      });
    }
  }

  void _addCondition() {
    setState(() {
      _conditions.add(PromptCondition(
        id: _getNextConditionTempId(),
        name: '',
        type: ConditionType.toggle,
        order: _conditions.length,
        isExpanded: true,
      ));
    });
  }

  void _addPreset() {
    setState(() {
      _presets.add(PromptConditionPreset(
        id: _getNextPresetTempId(),
        name: '',
        isDefault: false,
        order: _presets.length,
        isExpanded: true,
      ));
    });
  }

  Future<void> _deletePreset(PromptConditionPreset preset) async {
    if (preset.isDefault) return;
    final l10n = AppLocalizations.of(context);
    final confirmed = await CommonDialog.showDeleteConfirmation(
      context: context,
      itemName: preset.name.isEmpty ? l10n.promptEditDefaultPresetName : preset.name,
    );

    if (confirmed) {
      setState(() {
        _presets.remove(preset);
      });
    }
  }

  Future<void> _deleteCondition(PromptCondition condition) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await CommonDialog.showDeleteConfirmation(
      context: context,
      itemName: condition.name.isEmpty ? l10n.promptEditDefaultConditionName : condition.name,
    );

    if (confirmed) {
      setState(() {
        _conditions.remove(condition);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: CommonAppBar(
        title: _isReadOnly
            ? l10n.promptEditTitleView
            : (_isEditing ? l10n.promptEditTitleEdit : l10n.promptEditTitleNew),
        actions: [
          if (!_isReadOnly) ...[
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              CommonAppBarIconButton(
                icon: Icons.check,
                onPressed: _savePrompt,
              ),
          ],
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            overlayColor: WidgetStateProperty.all(Colors.transparent),
            splashFactory: NoSplash.splashFactory,
            tabs: [
              Tab(
                child: SizedBox(
                  width: 65,
                  child: Center(child: Text(l10n.promptEditTabBasic)),
                ),
              ),
              Tab(
                child: SizedBox(
                  width: 65,
                  child: Center(child: Text(l10n.promptEditTabParameters)),
                ),
              ),
              Tab(
                child: SizedBox(
                  width: 65,
                  child: Center(child: Text(l10n.promptEditTabPrompt)),
                ),
              ),
              Tab(
                child: SizedBox(
                  width: 65,
                  child: Center(child: Text(l10n.promptEditTabRegex)),
                ),
              ),
              Tab(
                child: SizedBox(
                  width: 65,
                  child: Center(child: Text(l10n.promptEditTabOther)),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildBasicInfoTab(),
            _buildParametersTab(),
            PromptItemsTab(
              folders: _folders,
              standaloneItems: _standaloneItems,
              contentControllers: _contentControllers,
              readOnly: _isReadOnly,
              onUpdate: () => setState(() {}),
              onDeleteItem: _deleteItem,
              onDeleteFolder: _deleteFolder,
              onAddItem: _addItem,
              onAddFolder: _addFolder,
              onMoveItemToFolder: _moveItemToFolder,
              onMoveItemOutOfFolder: _moveItemOutOfFolder,
              onReorderItem: _reorderItem,
              onReorderFolder: _reorderFolder,
              conditions: _conditions,
              conditionsSectionExpanded: _conditionsSectionExpanded,
              onConditionsSectionToggle: () =>
                  setState(() => _conditionsSectionExpanded = !_conditionsSectionExpanded),
              onAddCondition: _addCondition,
              onDeleteCondition: _deleteCondition,
              onUpdateConditions: () => setState(() {}),
              getNextConditionOptionTempId: _getNextConditionOptionTempId,
            ),
            PromptRegexTab(
              rules: _regexRules,
              patternControllers: _regexPatternControllers,
              replacementControllers: _regexReplacementControllers,
              readOnly: _isReadOnly,
              onUpdate: () => setState(() {}),
              onDeleteRule: _deleteRegexRule,
              onAddRule: _addRegexRule,
            ),
            PromptOtherSettingsTab(
              presets: _presets,
              conditions: _conditions,
              readOnly: _isReadOnly,
              onUpdate: () => setState(() {}),
              onDeletePreset: _deletePreset,
              onAddPreset: _addPreset,
              presetsSectionExpanded: _presetsSectionExpanded,
              onPresetsSectionToggle: () =>
                  setState(() => _presetsSectionExpanded = !_presetsSectionExpanded),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoTab() {
    final l10n = AppLocalizations.of(context);
    return IgnorePointer(
      ignoring: _isReadOnly,
      child: ListView(
          padding: const EdgeInsets.all(UIConstants.spacing20),
          children: [
            CommonCustomTextField(
              controller: _nameController,
              label: l10n.promptEditNameLabel,
              hintText: l10n.promptEditNameHint,
              maxLines: null,
              showCounter: true,
              validator: _isReadOnly
                  ? null
                  : (value) {
                      if (value == null || value.trim().isEmpty) {
                        return l10n.promptEditNameRequired;
                      }
                      return null;
                    },
            ),
            const SizedBox(height: UIConstants.spacing20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: CommonCustomTextField.labelHorizontalPadding),
                  child: Row(
                    children: [
                      CommonTitleMedium(text: l10n.promptEditDescriptionTitle),
                    ],
                  ),
                ),
                const SizedBox(height: CommonCustomTextField.labelBottomSpacing),
                CommonEditText(
                  controller: _descriptionController,
                  hintText: l10n.promptEditDescriptionHint,
                  size: CommonEditTextSize.medium,
                  maxLines: null,
                  minLines: 3,
                ),
              ],
            ),
          ],
      ),
    );
  }

  Widget _buildParametersTab() {
    final l10n = AppLocalizations.of(context);
    return IgnorePointer(
      ignoring: _isReadOnly,
      child: ListView(
      padding: const EdgeInsets.all(UIConstants.spacing20),
      children: [
        const CommonInfoBox(message: ''),
        const SizedBox(height: 24),
        CommonParameterTextField(
          label: l10n.promptEditMaxInputSize,
          helpText: l10n.promptEditMaxInputHelp,
          controller: _maxInputTokensController,
          onChanged: (value) {
            setState(() {
              _parameters = _parameters.copyWith(maxInputTokens: value);
            });
          },
        ),
        const SizedBox(height: UIConstants.spacing20),
        CommonParameterTextField(
          label: l10n.autoSummaryMaxResponseSize,
          helpText: l10n.autoSummaryMaxResponseHelp,
          controller: _maxOutputTokensController,
          onChanged: (value) {
            setState(() {
              _parameters = _parameters.copyWith(maxOutputTokens: value);
            });
          },
        ),
        const SizedBox(height: UIConstants.spacing20),
        CommonParameterTextField(
          label: l10n.promptEditThinkingTokens,
          helpText: l10n.promptEditThinkingHelp,
          controller: _thinkingTokensController,
          showCheckbox: true,
          isChecked: _parameters.thinkingTokens != null,
          onCheckboxChanged: (checked) {
            setState(() {
              _parameters = _parameters.copyWith(thinkingTokens: checked ? 0 : null);
            });
          },
          onChanged: (value) {
            setState(() {
              _parameters = _parameters.copyWith(thinkingTokens: value);
            });
          },
        ),
        const SizedBox(height: UIConstants.spacing20),
        CommonParameterSlider(
          label: l10n.autoSummaryTemperature,
          value: _parameters.temperature,
          defaultValue: 1.0,
          min: 0.0,
          max: 2.0,
          divisions: 40,
          helpText: l10n.autoSummaryTemperatureHelp,
          onChanged: (value) {
            setState(() {
              _parameters = _parameters.copyWith(temperature: value);
            });
          },
        ),
        const SizedBox(height: UIConstants.spacing20),
        CommonParameterSlider(
          label: 'Top P',
          value: _parameters.topP,
          defaultValue: 0.95,
          min: 0.0,
          max: 1.0,
          divisions: 100,
          helpText: l10n.autoSummaryTopPHelp,
          onChanged: (value) {
            setState(() {
              _parameters = _parameters.copyWith(topP: value);
            });
          },
        ),
        const SizedBox(height: UIConstants.spacing20),
        CommonParameterSlider(
          label: 'Top K',
          value: _parameters.topK?.toDouble(),
          defaultValue: 40.0,
          min: 1.0,
          max: 100.0,
          divisions: 99,
          decimalPlaces: 0,
          helpText: l10n.autoSummaryTopKHelp,
          onChanged: (value) {
            setState(() {
              _parameters = _parameters.copyWith(topK: value?.round());
            });
          },
        ),
        const SizedBox(height: UIConstants.spacing20),
        CommonParameterSlider(
          label: l10n.autoSummaryPresencePenalty,
          value: _parameters.presencePenalty,
          defaultValue: 0.0,
          min: -2.0,
          max: 2.0,
          divisions: 80,
          helpText: l10n.autoSummaryPresencePenaltyHelp,
          onChanged: (value) {
            setState(() {
              _parameters = _parameters.copyWith(presencePenalty: value);
            });
          },
        ),
        const SizedBox(height: UIConstants.spacing20),
        CommonParameterSlider(
          label: l10n.autoSummaryFrequencyPenalty,
          value: _parameters.frequencyPenalty,
          defaultValue: 0.0,
          min: -2.0,
          max: 2.0,
          divisions: 80,
          helpText: l10n.autoSummaryFrequencyPenaltyHelp,
          onChanged: (value) {
            setState(() {
              _parameters = _parameters.copyWith(frequencyPenalty: value);
            });
          },
        ),
        const SizedBox(height: UIConstants.spacing20),
        _buildStopSequencesSection(),
        const SizedBox(height: 24),
        _buildThinkingSection(),
      ],
    ),
    );
  }

  Widget _buildStopSequencesSection() {
    final l10n = AppLocalizations.of(context);
    final sequences = _parameters.stopSequences ?? [];
    final controller = TextEditingController();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.promptEditStopStrings,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        if (sequences.isNotEmpty)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: sequences.asMap().entries.map((entry) {
              return Chip(
                label: Text(
                  entry.value,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: _isReadOnly ? null : () {
                  setState(() {
                    final updated = List<String>.from(sequences)..removeAt(entry.key);
                    _parameters = _parameters.copyWith(
                      stopSequences: updated.isEmpty ? null : updated,
                    );
                  });
                },
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              );
            }).toList(),
          ),
        if (!_isReadOnly) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  style: Theme.of(context).textTheme.bodySmall,
                  decoration: InputDecoration(
                    hintText: l10n.promptEditStopStringsHint,
                    hintStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onSubmitted: (value) {
                    if (value.trim().isNotEmpty) {
                      setState(() {
                        final updated = List<String>.from(sequences)..add(value.trim());
                        _parameters = _parameters.copyWith(stopSequences: updated);
                      });
                      controller.clear();
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.add, size: 20),
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                padding: EdgeInsets.zero,
                onPressed: () {
                  if (controller.text.trim().isNotEmpty) {
                    setState(() {
                      final updated = List<String>.from(sequences)..add(controller.text.trim());
                      _parameters = _parameters.copyWith(stopSequences: updated);
                    });
                    controller.clear();
                  }
                },
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildThinkingSection() {
    final l10n = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Row(
            children: [
              CommonTitleMedium(text: l10n.promptEditThinkingConfig),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Gemini',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CommonParameterTextField(
                    label: l10n.promptEditThinkingTokenCount,
                    helpText: l10n.promptEditThinkingTokenHelp,
                    controller: _thinkingMaxTokensController,
                    onChanged: (value) {
                      setState(() {
                        _parameters = _parameters.copyWith(thinkingMaxTokens: value);
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: CommonCustomTextField.labelHorizontalPadding),
                        child: CommonTitleMedium(text: l10n.promptEditThinkingLevel),
                      ),
                      const SizedBox(height: CommonCustomTextField.labelBottomSpacing),
                      CommonDropdownButton<ThinkingLevel>(
                        value: _parameters.thinkingLevel ?? ThinkingLevel.unspecified,
                        items: ThinkingLevel.values,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _parameters = _parameters.copyWith(thinkingLevel: value);
                            });
                          }
                        },
                        labelBuilder: (level) => level.displayName,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
