import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/ui_constants.dart';
import '../../l10n/app_localizations.dart';
import '../../database/database_helper.dart';
import '../../models/chat/chat_model.dart';
import '../../models/chat/custom_model.dart';
import '../../models/chat/custom_provider.dart';
import '../../models/chat/unified_model.dart';
import '../../models/chat/auto_summary_settings.dart';
import '../../models/chat/summary_prompt_item.dart';
import '../../models/prompt/prompt_parameters.dart';
import '../../utils/common_dialog.dart';
import '../../widgets/common/common_appbar.dart';
import '../../widgets/common/common_edit_text.dart';
import '../../widgets/common/common_editable_expandable_item.dart';
import '../../widgets/common/common_info_box.dart';
import '../../widgets/common/common_parameter_field.dart';
import '../../widgets/common/common_segmented_button.dart';

class AutoSummaryScreen extends StatefulWidget {
  final int chatRoomId;

  const AutoSummaryScreen({
    super.key,
    required this.chatRoomId,
  });

  @override
  State<AutoSummaryScreen> createState() => _AutoSummaryScreenState();
}

class _AutoSummaryScreenState extends State<AutoSummaryScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseHelper _db = DatabaseHelper.instance;
  late TabController _tabController;

  bool _isEnabled = true;
  bool _isAgentEnabled = true;
  bool _useSubModel = false;
  ChatModelProvider _selectedProvider = ChatModelProvider.googleAIStudio;
  String? _selectedCustomProviderId;
  UnifiedModel _selectedModel = UnifiedModel.fromChatModel(ChatModel.geminiFlash3Preview);
  List<CustomModel> _customModels = [];
  List<CustomProvider> _customProviders = [];
  late TextEditingController _tokenThresholdController;
  AutoSummarySettings? _existingSettings;
  bool _isLoading = true;

  // Parameters
  PromptParameters _parameters = const PromptParameters(
    maxOutputTokens: 10000,
    temperature: 1.0,
  );
  final _maxOutputTokensController = TextEditingController(text: '10000');

  // Message count default (global only)
  final _autoPinByMessageCountController = TextEditingController(text: '10');

  // Drag state
  bool _isDragging = false;

  // Prompt items
  List<SummaryPromptItem> _promptItems = [];
  final Map<int, TextEditingController> _itemContentControllers = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tokenThresholdController = TextEditingController(text: '20000');
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      if (widget.chatRoomId == 0) {
        final prefs = await SharedPreferences.getInstance();
        final msgCount = prefs.getInt('default_auto_pin_by_message_count');
        _autoPinByMessageCountController.text = msgCount?.toString() ?? '10';
      }

      _customProviders = await CustomProviderRepository.loadAll();
      _customModels = await CustomModelRepository.loadAll();

      final settings = await _db.getAutoSummarySettings(widget.chatRoomId);
      if (settings != null) {
        _existingSettings = settings;
        final UnifiedModel resolvedModel;
        if (settings.summaryModel.startsWith('custom:')) {
          final customId = settings.summaryModel.replaceFirst('custom:', '');
          final custom = _customModels.where((m) => m.id == customId).firstOrNull;
          if (custom != null) {
            final cp = custom.providerId != null
                ? _customProviders.where((p) => p.id == custom.providerId).firstOrNull
                : null;
            resolvedModel = UnifiedModel.fromCustomModel(custom, provider: cp);
          } else {
            resolvedModel = UnifiedModel.fromChatModel(ChatModel.geminiFlash3Preview);
          }
        } else {
          resolvedModel = UnifiedModel.fromChatModel(
            ChatModel.resolveFromStoredValue(settings.summaryModel),
          );
        }

        List<SummaryPromptItem> promptItems;
        if (settings.summaryPromptItems != null &&
            settings.summaryPromptItems!.isNotEmpty) {
          promptItems =
              SummaryPromptItem.listFromJson(settings.summaryPromptItems);
        } else {
          promptItems = await SummaryPromptItem.loadDefaultItems();
        }

        setState(() {
          _isEnabled = settings.isEnabled;
          _isAgentEnabled = settings.isAgentEnabled;
          _useSubModel = settings.useSubModel;
          _selectedModel = resolvedModel;
          _selectedProvider = resolvedModel.provider;
          _tokenThresholdController.text = settings.tokenThreshold.toString();

          if (settings.parameters != null && settings.parameters!.isNotEmpty) {
            _parameters =
                PromptParameters.fromJson(jsonDecode(settings.parameters!));
          }
          _maxOutputTokensController.text =
              _parameters.maxOutputTokens?.toString() ?? '';

          _promptItems = promptItems;
          _buildContentControllers();
          _isLoading = false;
        });
      } else {
        final promptItems = await SummaryPromptItem.loadDefaultItems();
        setState(() {
          _promptItems = promptItems;
          _buildContentControllers();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('AutoSummaryScreen _loadSettings error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _buildContentControllers() {
    // Dispose existing controllers before clearing
    for (final controller in _itemContentControllers.values) {
      controller.dispose();
    }
    _itemContentControllers.clear();

    // Create new controllers
    for (int i = 0; i < _promptItems.length; i++) {
      _itemContentControllers[i] =
          TextEditingController(text: _promptItems[i].content);
    }
  }

  Future<void> _saveAndPop() async {
_syncContentFromControllers();
    _syncParametersFromControllers();

    final settings = AutoSummarySettings(
      id: _existingSettings?.id,
      chatRoomId: widget.chatRoomId,
      isEnabled: _isEnabled,
      isAgentEnabled: _isAgentEnabled,
      useSubModel: _useSubModel,
      summaryModel: _selectedModel.id,
      tokenThreshold: int.tryParse(_tokenThresholdController.text) ?? 20000,
      summaryPrompt: '',
      parameters: jsonEncode(_parameters.toJson()),
      summaryPromptItems: SummaryPromptItem.listToJson(_promptItems),
    );

    if (_existingSettings != null) {
      await _db.updateAutoSummarySettings(settings);
    } else {
      await _db.createAutoSummarySettings(settings);
    }

    if (widget.chatRoomId == 0) {
      final prefs = await SharedPreferences.getInstance();
      final msgCount = int.tryParse(_autoPinByMessageCountController.text);
      if (msgCount != null && msgCount > 0) {
        await prefs.setInt('default_auto_pin_by_message_count', msgCount);
      } else {
        await prefs.remove('default_auto_pin_by_message_count');
      }
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _syncParametersFromControllers() {
    final maxOutput = int.tryParse(_maxOutputTokensController.text);
    _parameters = _parameters.copyWith(
      maxOutputTokens: maxOutput,
    );
  }

  void _syncContentFromControllers() {
    for (int i = 0; i < _promptItems.length; i++) {
      final controller = _itemContentControllers[i];
      if (controller != null && _promptItems[i].role != SummaryPromptRole.summary) {
        _promptItems[i] = _promptItems[i].copyWith(content: controller.text);
      }
    }
  }

  void _addPromptItem() {
    setState(() {
      final newItem = SummaryPromptItem(
        role: SummaryPromptRole.user,
        content: '',
        order: _promptItems.length,
        isExpanded: true,
      );
      _promptItems.add(newItem);
      final idx = _promptItems.length - 1;
      _itemContentControllers[idx] = TextEditingController();
    });
  }

  void _movePromptItem(int from, int to) {
    _syncContentFromControllers();
    setState(() {
      final item = _promptItems.removeAt(from);
      _promptItems.insert(to, item);
      _buildContentControllers();
    });
  }

  void _deletePromptItem(int index) {
    setState(() {
      // Dispose the controller at the deleted index
      _itemContentControllers[index]?.dispose();

      // Remove the item from the list
      _promptItems.removeAt(index);

      // Rebuild controllers with proper index mapping
      final Map<int, TextEditingController> newControllers = {};
      for (int i = 0; i < _promptItems.length; i++) {
        if (i < index) {
          // Keep controllers before the deleted index
          newControllers[i] = _itemContentControllers[i]!;
        } else {
          // Shift controllers after the deleted index forward
          newControllers[i] = _itemContentControllers[i + 1]!;
        }
      }
      _itemContentControllers.clear();
      _itemContentControllers.addAll(newControllers);
    });
  }

  Future<void> _exportSummaryPrompt() async {
    try {
      _syncContentFromControllers();

      final jsonList = _promptItems.map((e) => e.toJson()).toList();
      final jsonString =
          const JsonEncoder.withIndent('  ').convert(jsonList);
      const fileName = 'summary_prompt.json';

      if (Platform.isAndroid) {
        const platform = MethodChannel('com.flanapp.flan/file_saver');
        final result = await platform.invokeMethod('saveToDownloads', {
          'fileName': fileName,
          'content': jsonString,
        });

        if (mounted) {
          final l10n = AppLocalizations.of(context);
          CommonDialog.showSnackBar(
            context: context,
            message: result == true
                ? l10n.characterExportSuccessAndroid(fileName)
                : l10n.autoSummarySaveFailed,
          );
        }
      } else if (Platform.isIOS) {
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/$fileName';
        final file = File(filePath);
        await file.writeAsString(jsonString);

        if (mounted) {
          CommonDialog.showSnackBar(
            context: context,
            message: AppLocalizations.of(context).characterExportSuccessIos(filePath),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        CommonDialog.showSnackBar(
          context: context,
          message: AppLocalizations.of(context).autoSummaryExportFailed(e.toString()),
        );
      }
    }
  }

  Future<void> _resetToDefaultPrompt() async {
    final l10n = AppLocalizations.of(context);
    final confirm = await CommonDialog.showConfirmation(
      context: context,
      title: l10n.autoSummaryResetTitle,
      content: l10n.autoSummaryResetContent,
      confirmText: l10n.autoSummaryResetConfirm,
      isDestructive: true,
    );
    if (confirm != true) return;

    try {
      final defaultItems = await SummaryPromptItem.loadDefaultItems();
      setState(() {
        _promptItems = defaultItems;
        _buildContentControllers();
      });

      if (mounted) {
        CommonDialog.showSnackBar(
          context: context,
          message: l10n.autoSummaryResetSuccess,
        );
      }
    } catch (e) {
      if (mounted) {
        CommonDialog.showSnackBar(
          context: context,
          message: l10n.autoSummaryResetFailed(e.toString()),
        );
      }
    }
  }

  Future<void> _importSummaryPrompt() async {
    final l10n = AppLocalizations.of(context);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );

      if (result == null || result.files.isEmpty) return;

      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();
      final decoded = jsonDecode(jsonString);

      final List<dynamic> jsonList;
      if (decoded is List) {
        jsonList = decoded;
      } else {
        throw FormatException(l10n.autoSummaryInvalidFormat);
      }

      final items =
          jsonList.map((e) => SummaryPromptItem.fromJson(e)).toList();

      if (items.isEmpty) {
        throw FormatException(l10n.autoSummaryEmptyItems);
      }

      setState(() {
        _promptItems = items;
        _buildContentControllers();
      });

      if (mounted) {
        CommonDialog.showSnackBar(
          context: context,
          message: l10n.autoSummaryImportSuccess,
        );
      }
    } catch (e) {
      if (mounted) {
        CommonDialog.showSnackBar(
          context: context,
          message: l10n.autoSummaryImportFailed(e.toString()),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _tokenThresholdController.dispose();
    _maxOutputTokensController.dispose();
    _autoPinByMessageCountController.dispose();
    for (final controller in _itemContentControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_isLoading) {
      return Scaffold(
        appBar: CommonAppBar(title: l10n.autoSummaryTitle),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _saveAndPop();
        }
      },
      child: Scaffold(
        appBar: CommonAppBar(
          title: l10n.autoSummaryTitle,
          showBackButton: false,
          showCloseButton: true,
          onClosePressed: _saveAndPop,
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
                    child: Center(child: Text(l10n.autoSummaryTabBasic)),
                  ),
                ),
                Tab(
                  child: SizedBox(
                    width: 65,
                    child: Center(child: Text(l10n.autoSummaryTabParameters)),
                  ),
                ),
                Tab(
                  child: SizedBox(
                    width: 65,
                    child: Center(child: Text(l10n.autoSummaryTabPrompt)),
                  ),
                ),
              ],
            ),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildBasicInfoTab(),
            _buildParametersTab(),
            _buildPromptTab(),
          ],
        ),
      ),
    );
  }

  // ==================== Tab 1: Basic Info ====================

  Widget _buildBasicInfoTab() {
    final l10n = AppLocalizations.of(context);
    return ListView(
      children: [
        _buildSectionHeader(l10n.autoSummarySection),
        SwitchListTile(
          secondary: const Icon(Icons.auto_awesome),
          title: Text(l10n.autoSummaryEnableTitle),
          subtitle: Text(l10n.autoSummaryEnableSubtitle),
          value: _isEnabled,
          onChanged: (value) {
            setState(() {
              _isEnabled = value;
            });
          },
        ),
        if (_isEnabled) ...[
          SwitchListTile(
            secondary: const Icon(Icons.smart_toy_outlined),
            title: Text(l10n.autoSummaryAgentTitle),
            subtitle: Text(l10n.autoSummaryAgentSubtitle),
            value: _isAgentEnabled,
            onChanged: (value) {
              setState(() {
                _isAgentEnabled = value;
              });
            },
          ),
          const Divider(),
          _buildSectionHeader(l10n.autoSummaryModelSection),
          SwitchListTile(
            secondary: const Icon(Icons.swap_horiz),
            title: Text(l10n.autoSummaryUseSubModel),
            subtitle: Text(l10n.autoSummaryUseSubModelSubtitle),
            value: _useSubModel,
            onChanged: (value) {
              setState(() {
                _useSubModel = value;
              });
            },
          ),
          if (!_useSubModel) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Builder(builder: (context) {
                final dropdownItems = <DropdownMenuItem<String>>[];
                for (final p in ChatModelProvider.values) {
                  if (p == ChatModelProvider.custom) continue;
                  dropdownItems.add(DropdownMenuItem(
                    value: p.name,
                    child: Text(p.displayName),
                  ));
                }
                for (final cp in _customProviders) {
                  dropdownItems.add(DropdownMenuItem(
                    value: 'custom:${cp.id}',
                    child: Text(cp.name),
                  ));
                }

                final selectedKey = _selectedProvider == ChatModelProvider.custom
                    && _selectedCustomProviderId != null
                    ? 'custom:$_selectedCustomProviderId'
                    : _selectedProvider.name;

                return DropdownButton<String>(
                  value: dropdownItems.any((i) => i.value == selectedKey)
                      ? selectedKey
                      : ChatModelProvider.googleAIStudio.name,
                  isExpanded: true,
                  underline: const SizedBox(),
                  borderRadius: BorderRadius.circular(16),
                  items: dropdownItems,
                  onChanged: (value) {
                    if (value == null) return;
                    List<UnifiedModel> models;
                    if (value.startsWith('custom:')) {
                      final cpId = value.substring(7);
                      models = UnifiedModel.getByCustomProvider(cpId, _customModels, _customProviders);
                      setState(() {
                        _selectedProvider = ChatModelProvider.custom;
                        _selectedCustomProviderId = cpId;
                        if (models.isNotEmpty) _selectedModel = models.first;
                      });
                    } else {
                      final p = ChatModelProvider.values.firstWhere(
                        (e) => e.name == value,
                        orElse: () => ChatModelProvider.googleAIStudio,
                      );
                      models = UnifiedModel.getByProvider(p, _customModels, _customProviders);
                      setState(() {
                        _selectedProvider = p;
                        _selectedCustomProviderId = null;
                        if (models.isNotEmpty) _selectedModel = models.first;
                      });
                    }
                  },
                );
              }),
            ),
            _buildModelDropdown(),
          ],
          const Divider(),
          _buildSectionHeader(l10n.autoSummaryStartCondition),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: CommonEditText(
              controller: _tokenThresholdController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              hintText: l10n.autoSummaryTokenHint,
            ),
          ),
        ],
        if (widget.chatRoomId == 0) ...[
          const Divider(),
          _buildSectionHeader(l10n.autoSummaryPeriod),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: CommonEditText(
              controller: _autoPinByMessageCountController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              hintText: 'N',
            ),
          ),
        ],
        const SizedBox(height: 32),
      ],
    );
  }

  // ==================== Tab 2: Parameters ====================

  Widget _buildParametersTab() {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(UIConstants.spacing20),
      children: [
        const CommonInfoBox(
          message: '',
        ),
        const SizedBox(height: 24),
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
        const SizedBox(height: 32),
      ],
    );
  }

  // ==================== Tab 3: Prompt ====================

  Widget _buildPromptTab() {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(UIConstants.spacing20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CommonInfoBox(
            message: l10n.autoSummaryPromptHelp,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _promptItems.isEmpty
                ? Center(
                    child: Text(
                      l10n.autoSummaryNoItems,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.5),
                          ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _promptItems.length + 1,
                    itemBuilder: (context, index) {
                      if (index < _promptItems.length) {
                        return _buildDraggablePromptItem(index);
                      }
                      return _buildDropSlot(_promptItems.length);
                    },
                  ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _addPromptItem,
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(l10n.autoSummaryAddItem),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.outlined(
                onPressed: _resetToDefaultPrompt,
                icon: const Icon(Icons.refresh, size: 20),
                tooltip: l10n.autoSummaryResetDefault,
              ),
              const SizedBox(width: 4),
              IconButton.outlined(
                onPressed: _importSummaryPrompt,
                icon: const Icon(Icons.file_download_outlined, size: 20),
                tooltip: l10n.autoSummaryImport,
              ),
              const SizedBox(width: 4),
              IconButton.outlined(
                onPressed: _exportSummaryPrompt,
                icon: const Icon(Icons.file_upload_outlined, size: 20),
                tooltip: l10n.autoSummaryExport,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropSlot(int targetIndex) {
    if (!_isDragging) return const SizedBox.shrink();
    return DragTarget<int>(
      onWillAcceptWithDetails: (details) {
        final fromIndex = details.data;
        return fromIndex != targetIndex && fromIndex != targetIndex - 1;
      },
      onAcceptWithDetails: (details) {
        final fromIndex = details.data;
        _movePromptItem(fromIndex, fromIndex < targetIndex ? targetIndex - 1 : targetIndex);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        return SizedBox(
          height: 16,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height: isHovering ? 3 : 0,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDraggablePromptItem(int index) {
    final item = _promptItems[index];
    final card = _buildPromptItemCard(index);
    return Column(
      children: [
        _buildDropSlot(index),
        LongPressDraggable<int>(
          data: index,
          onDragStarted: () => setState(() => _isDragging = true),
          onDragEnd: (_) => setState(() => _isDragging = false),
          feedback: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(UIConstants.borderRadiusMedium),
            child: Container(
              width: 300,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(UIConstants.borderRadiusMedium),
              ),
              child: Row(
                children: [
                  Icon(
                    _getRoleIcon(item.role),
                    size: UIConstants.iconSizeMedium,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  const SizedBox(width: UIConstants.spacing12),
                  Expanded(
                    child: Text(
                      item.name ?? item.role.displayName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          childWhenDragging: Opacity(opacity: 0.3, child: card),
          child: card,
        ),
      ],
    );
  }

  Widget _buildPromptItemCard(int index) {
    final item = _promptItems[index];
    return CommonEditableExpandableItem(
      key: ValueKey('prompt_item_$index'),
      icon: Icon(
        _getRoleIcon(item.role),
        size: UIConstants.iconSizeMedium,
        color: Theme.of(context).colorScheme.secondary,
      ),
      name: item.name ?? item.role.displayName,
      isExpanded: item.isExpanded,
      onToggleExpanded: () {
        if (item.isExpanded) {
          FocusScope.of(context).unfocus();
        }
        setState(() {
          _promptItems[index] =
              item.copyWith(isExpanded: !item.isExpanded);
        });
      },
      onDelete: () => _deletePromptItem(index),
      showNameField: true,
      nameHint: AppLocalizations.of(context).autoSummaryItemNameHint,
      onNameChanged: (value) {
        _promptItems[index] =
            item.copyWith(name: value.isEmpty ? null : value);
      },
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).autoSummaryItemRole,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 6),
          CommonSegmentedButton<SummaryPromptRole>(
            values: SummaryPromptRole.values,
            selected: item.role,
            onSelectionChanged: (selected) {
              setState(() {
                _promptItems[index] = item.copyWith(role: selected);
              });
            },
            labelBuilder: (role) => role.displayName,
          ),
          const SizedBox(height: UIConstants.spacing12),
          if (item.role == SummaryPromptRole.summary)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context).autoSummaryTargetMessageInfo,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                            color:
                                Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            Text(
              AppLocalizations.of(context).autoSummaryItemPrompt,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 6),
            CommonEditText(
              controller: _itemContentControllers[index],
              hintText: AppLocalizations.of(context).autoSummaryItemPromptHint,
              size: CommonEditTextSize.small,
              maxLines: null,
              minLines: 3,
            ),
          ],
        ],
      ),
    );
  }

  IconData _getRoleIcon(SummaryPromptRole role) {
    switch (role) {
      case SummaryPromptRole.system:
        return Icons.settings_outlined;
      case SummaryPromptRole.user:
        return Icons.person_outline;
      case SummaryPromptRole.assistant:
        return Icons.smart_toy_outlined;
      case SummaryPromptRole.summary:
        return Icons.summarize_outlined;
    }
  }

  Widget _buildModelDropdown() {
    final models = _selectedProvider == ChatModelProvider.custom && _selectedCustomProviderId != null
        ? UnifiedModel.getByCustomProvider(_selectedCustomProviderId!, _customModels, _customProviders)
        : UnifiedModel.getByProvider(_selectedProvider, _customModels, _customProviders);
    final currentValid = models.contains(_selectedModel);
    final effectiveModel = currentValid
        ? _selectedModel
        : (models.isNotEmpty ? models.first : null);

    if (models.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Text(
          AppLocalizations.of(context).autoSummaryNoModel,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: DropdownButton<UnifiedModel>(
        value: effectiveModel,
        isExpanded: true,
        underline: const SizedBox(),
        borderRadius: BorderRadius.circular(16),
        items: models
            .map((m) => DropdownMenuItem(
                  value: m,
                  child: Text(
                    m.displayName,
                    overflow: TextOverflow.ellipsis,
                  ),
                ))
            .toList(),
        onChanged: (value) {
          if (value != null) {
            setState(() {
              _selectedModel = value;
            });
          }
        },
      ),
    );
  }

  // ==================== Common Widgets ====================

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

}
