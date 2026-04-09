import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/ui_constants.dart';
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
          CommonDialog.showSnackBar(
            context: context,
            message: result == true
                ? 'Download/$fileName에 저장되었습니다'
                : '저장에 실패했습니다',
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
            message: '$filePath에 저장되었습니다',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        CommonDialog.showSnackBar(
          context: context,
          message: '요약 프롬프트 내보내기 실패: $e',
        );
      }
    }
  }

  Future<void> _resetToDefaultPrompt() async {
    final confirm = await CommonDialog.showConfirmation(
      context: context,
      title: '초기화',
      content: '요약 프롬프트를 최신 기본 프롬프트로 되돌리시겠습니까?',
      confirmText: '초기화',
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
          message: '요약 프롬프트가 초기화되었습니다',
        );
      }
    } catch (e) {
      if (mounted) {
        CommonDialog.showSnackBar(
          context: context,
          message: '요약 프롬프트 초기화에 실패했습니다: $e',
        );
      }
    }
  }

  Future<void> _importSummaryPrompt() async {
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
        throw const FormatException('올바른 요약 프롬프트 형식이 아닙니다');
      }

      final items =
          jsonList.map((e) => SummaryPromptItem.fromJson(e)).toList();

      if (items.isEmpty) {
        throw const FormatException('프롬프트 항목이 비어있습니다');
      }

      setState(() {
        _promptItems = items;
        _buildContentControllers();
      });

      if (mounted) {
        CommonDialog.showSnackBar(
          context: context,
          message: '요약 프롬프트를 가져왔습니다',
        );
      }
    } catch (e) {
      if (mounted) {
        CommonDialog.showSnackBar(
          context: context,
          message: '요약 프롬프트 가져오기 실패: $e',
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
    if (_isLoading) {
      return Scaffold(
        appBar: const CommonAppBar(title: '자동 요약'),
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
          title: '자동 요약',
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
              tabs: const [
                Tab(
                  child: SizedBox(
                    width: 65,
                    child: Center(child: Text('기본정보')),
                  ),
                ),
                Tab(
                  child: SizedBox(
                    width: 65,
                    child: Center(child: Text('파라미터')),
                  ),
                ),
                Tab(
                  child: SizedBox(
                    width: 65,
                    child: Center(child: Text('프롬프트')),
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
    return ListView(
      children: [
        _buildSectionHeader('자동 요약 설정'),
        SwitchListTile(
          secondary: const Icon(Icons.auto_awesome),
          title: const Text('자동 요약'),
          subtitle: const Text('토큰 수 초과 시 자동으로 요약을 생성합니다'),
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
            title: const Text('에이전트 모드'),
            subtitle: const Text('구조화된 세계관 데이터를 자동으로 관리합니다'),
            value: _isAgentEnabled,
            onChanged: (value) {
              setState(() {
                _isAgentEnabled = value;
              });
            },
          ),
          const Divider(),
          _buildSectionHeader('요약 모델'),
          SwitchListTile(
            secondary: const Icon(Icons.swap_horiz),
            title: const Text('보조 모델 사용'),
            subtitle: const Text('채팅 모델 설정의 보조 모델을 사용합니다'),
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
          _buildSectionHeader('자동 요약 시작 조건'),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: CommonEditText(
              controller: _tokenThresholdController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              hintText: '토큰 수를 입력하세요',
            ),
          ),
        ],
        if (widget.chatRoomId == 0) ...[
          const Divider(),
          _buildSectionHeader('요약 주기'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: CommonEditText(
              controller: _autoPinByMessageCountController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              hintText: 'N개 메시지마다 자동 요약',
            ),
          ),
        ],
        const SizedBox(height: 32),
      ],
    );
  }

  // ==================== Tab 2: Parameters ====================

  Widget _buildParametersTab() {
    return ListView(
      padding: const EdgeInsets.all(UIConstants.spacing20),
      children: [
        const CommonInfoBox(
          message: 'AI 모델의 생성 파라미터를 설정합니다. 모델에 따라 지원되는 파라미터가 다를 수 있습니다.',
        ),
        const SizedBox(height: 24),
        CommonParameterTextField(
          label: '최대 응답 크기',
          helpText: '생성할 수 있는 최대 토큰 수입니다.',
          controller: _maxOutputTokensController,
          onChanged: (value) {
            setState(() {
              _parameters = _parameters.copyWith(maxOutputTokens: value);
            });
          },
        ),
        const SizedBox(height: UIConstants.spacing20),
        CommonParameterSlider(
          label: '온도',
          value: _parameters.temperature,
          defaultValue: 1.0,
          min: 0.0,
          max: 2.0,
          divisions: 40,
          helpText: '값이 높을수록 더 창의적이고 다양한 응답을 생성합니다.',
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
          helpText: '누적 확률 임계값입니다. 값이 낮을수록 더 집중된 응답을 생성합니다.',
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
          helpText: '고려할 상위 토큰의 수입니다.',
          onChanged: (value) {
            setState(() {
              _parameters = _parameters.copyWith(topK: value?.round());
            });
          },
        ),
        const SizedBox(height: UIConstants.spacing20),
        CommonParameterSlider(
          label: '프리센스 패널티',
          value: _parameters.presencePenalty,
          defaultValue: 0.0,
          min: -2.0,
          max: 2.0,
          divisions: 80,
          helpText: '양수 값은 새로운 주제를 장려하고, 음수 값은 기존 주제에 집중합니다.',
          onChanged: (value) {
            setState(() {
              _parameters = _parameters.copyWith(presencePenalty: value);
            });
          },
        ),
        const SizedBox(height: UIConstants.spacing20),
        CommonParameterSlider(
          label: '빈도 패널티',
          value: _parameters.frequencyPenalty,
          defaultValue: 0.0,
          min: -2.0,
          max: 2.0,
          divisions: 80,
          helpText: '양수 값은 반복을 줄이고, 음수 값은 반복을 증가시킵니다.',
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
    return Padding(
      padding: const EdgeInsets.all(UIConstants.spacing20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CommonInfoBox(
            message: '요약 프롬프트 항목을 구성합니다. '
                '"요약대상" 역할 위치에 요약할 메시지가 자동으로 삽입됩니다.\n\n'
                '길게 눌러 순서를 변경할 수 있습니다.',
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _promptItems.isEmpty
                ? Center(
                    child: Text(
                      '프롬프트 항목이 없습니다',
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
                  label: const Text('항목 추가'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.outlined(
                onPressed: _resetToDefaultPrompt,
                icon: const Icon(Icons.refresh, size: 20),
                tooltip: '기본 프롬프트로 초기화',
              ),
              const SizedBox(width: 4),
              IconButton.outlined(
                onPressed: _importSummaryPrompt,
                icon: const Icon(Icons.file_download_outlined, size: 20),
                tooltip: '가져오기',
              ),
              const SizedBox(width: 4),
              IconButton.outlined(
                onPressed: _exportSummaryPrompt,
                icon: const Icon(Icons.file_upload_outlined, size: 20),
                tooltip: '내보내기',
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
      nameHint: '항목 이름 (예: 시스템 설정)',
      onNameChanged: (value) {
        _promptItems[index] =
            item.copyWith(name: value.isEmpty ? null : value);
      },
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '역할',
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
                      '요약할 메시지가 이 위치에 자동으로 삽입됩니다',
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
              '프롬프트',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 6),
            CommonEditText(
              controller: _itemContentControllers[index],
              hintText: '프롬프트 내용을 입력하세요',
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
          '모델 없음',
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
