import 'package:flutter/material.dart';
import '../../constants/ui_constants.dart';
import '../../constants/ai_model_constants.dart';
import '../../database/database_helper.dart';
import '../../models/prompt/chat_prompt.dart';
import '../../models/prompt/prompt_item.dart';
import '../../models/prompt/prompt_parameters.dart';
import '../../utils/common_dialog.dart';
import '../../widgets/custom_text_field.dart';
import 'tabs/prompt_items_tab.dart';

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

  final List<PromptItem> _items = [];
  final Map<int, TextEditingController> _contentControllers = {};
  int _nextTempId = -1;
  int _getNextTempId() => _nextTempId--;

  bool get _isEditing => widget.prompt != null;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    if (_isEditing) {
      _loadPromptData();
    }
  }

  void _loadPromptData() {
    final prompt = widget.prompt!;
    _nameController.text = prompt.name;
    _descriptionController.text = prompt.description ?? '';
    _selectedModel = prompt.supportedModel;
    _parameters = prompt.parameters ?? const PromptParameters();

    _items.addAll(prompt.items);
    for (var item in _items) {
      _contentControllers[item.id!] = TextEditingController(text: item.content);
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
    super.dispose();
  }

  Future<void> _savePrompt() async {
    if (!_formKey.currentState!.validate()) {
      _tabController.animateTo(0);
      return;
    }

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

      for (int i = 0; i < _items.length; i++) {
        final item = _items[i];
        final controller = _contentControllers[item.id]!;

        await _db.createPromptItem(
          item.copyWith(
            id: null,
            chatPromptId: promptId,
            content: controller.text.trim(),
            order: i,
          ),
        );
      }

      if (mounted) {
        CommonDialog.showSnackBar(
          context: context,
          message: '프롬프트가 ${_isEditing ? "수정" : "생성"}되었습니다',
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        CommonDialog.showSnackBar(
          context: context,
          message: '프롬프트 저장 실패: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _addItem() {
    setState(() {
      final newItem = PromptItem(
        id: _getNextTempId(),
        role: PromptRole.system,
        content: '',
        order: _items.length,
        isExpanded: true,
      );
      _items.add(newItem);
      _contentControllers[newItem.id!] = TextEditingController();
    });
  }

  Future<void> _deleteItem(PromptItem item) async {
    final confirmed = await CommonDialog.showDeleteConfirmation(
      context: context,
      itemName: item.name ?? item.role.displayName,
    );

    if (confirmed) {
      setState(() {
        _items.remove(item);
        _contentControllers.remove(item.id)?.dispose();
      });
    }
  }

  void _moveItem(PromptItem draggedItem, PromptItem targetItem) {
    setState(() {
      final draggedIndex = _items.indexOf(draggedItem);
      final targetIndex = _items.indexOf(targetItem);

      if (draggedIndex != -1 && targetIndex != -1) {
        _items.removeAt(draggedIndex);
        _items.insert(targetIndex, draggedItem);

        for (int i = 0; i < _items.length; i++) {
          _items[i] = _items[i].copyWith(order: i);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '프롬프트 수정' : '새 프롬프트'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _savePrompt,
            ),
        ],
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
          PromptItemsTab(
            items: _items,
            contentControllers: _contentControllers,
            onUpdate: () => setState(() {}),
            onDelete: _deleteItem,
            onMove: _moveItem,
            onAdd: _addItem,
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoTab() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(UIConstants.spacing20),
        children: [
          CustomTextField(
            controller: _nameController,
            label: '프롬프트 이름',
            hintText: '예: 친근한 도우미, 전문가 모드',
            maxLines: null,
            showCounter: true,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '프롬프트 이름을 입력해주세요';
              }
              return null;
            },
          ),
          const SizedBox(height: UIConstants.spacing20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: CustomTextField.labelHorizontalPadding),
                child: Row(
                  children: [
                    Text(
                      '설명',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(선택)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: CustomTextField.labelBottomSpacing),
              TextField(
                controller: _descriptionController,
                style: Theme.of(context).textTheme.bodyMedium,
                decoration: InputDecoration(
                  hintText: '이 프롬프트에 대한 설명을 입력하세요',
                  hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(CustomTextField.borderRadius),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.outline.withValues(alpha: CustomTextField.borderOpacity),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(CustomTextField.borderRadius),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.outline.withValues(alpha: CustomTextField.borderOpacity),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(CustomTextField.borderRadius),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: CustomTextField.horizontalPadding,
                    vertical: CustomTextField.verticalPadding,
                  ),
                  isDense: true,
                ),
                maxLines: null,
                minLines: 3,
              ),
            ],
          ),
          const SizedBox(height: UIConstants.spacing20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: CustomTextField.labelHorizontalPadding),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '지원 모델',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(width: CustomTextField.labelIconSpacing),
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            content: const Text(
                              '이 프롬프트가 최적화된 AI 모델을 선택하세요.\n'
                              'ALL을 선택하면 모든 모델에서 사용할 수 있습니다.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('확인'),
                              ),
                            ],
                          ),
                        );
                      },
                      child: Icon(
                        Icons.help_outline,
                        size: CustomTextField.helpIconSize,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: CustomTextField.labelBottomSpacing),
              DropdownButtonFormField<String>(
                value: _selectedModel,
                style: Theme.of(context).textTheme.bodyMedium,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(CustomTextField.borderRadius),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.outline.withValues(alpha: CustomTextField.borderOpacity),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(CustomTextField.borderRadius),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.outline.withValues(alpha: CustomTextField.borderOpacity),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(CustomTextField.borderRadius),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: CustomTextField.horizontalPadding,
                    vertical: CustomTextField.verticalPadding,
                  ),
                  isDense: true,
                ),
                items: AIModelConstants.supportedModels.map((model) {
                  return DropdownMenuItem(
                    value: model,
                    child: Text(AIModelConstants.getDisplayName(model)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedModel = value);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildParametersTab() {
    return ListView(
      padding: const EdgeInsets.all(UIConstants.spacing20),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'AI 모델의 생성 파라미터를 설정합니다. 모델에 따라 지원되는 파라미터가 다를 수 있습니다.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildSimpleTextFieldParameter(
          label: '최대 입력 크기',
          value: _parameters.maxInputTokens,
          helpText: '입력할 수 있는 최대 토큰 수입니다.',
          onChanged: (value) {
            setState(() {
              _parameters = _parameters.copyWith(maxInputTokens: value);
            });
          },
        ),
        const SizedBox(height: UIConstants.spacing20),
        _buildSimpleTextFieldParameter(
          label: '최대 응답 크기',
          value: _parameters.maxOutputTokens,
          helpText: '생성할 수 있는 최대 토큰 수입니다.',
          onChanged: (value) {
            setState(() {
              _parameters = _parameters.copyWith(maxOutputTokens: value);
            });
          },
        ),
        const SizedBox(height: UIConstants.spacing20),
        _buildCheckableTextFieldParameter(
          label: '사고토큰',
          value: _parameters.thinkingTokens,
          helpText: '사고에 사용할 토큰 수입니다.',
          onChanged: (value) {
            setState(() {
              _parameters = _parameters.copyWith(thinkingTokens: value);
            });
          },
        ),
        const SizedBox(height: UIConstants.spacing20),
        _buildCheckableSliderParameter(
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
        _buildCheckableSliderParameter(
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
        _buildCheckableSliderParameter(
          label: 'Top K',
          value: _parameters.topK?.toDouble(),
          defaultValue: 40.0,
          min: 1.0,
          max: 100.0,
          divisions: 99,
          helpText: '고려할 상위 토큰의 수입니다.',
          onChanged: (value) {
            setState(() {
              _parameters = _parameters.copyWith(topK: value?.round());
            });
          },
        ),
        const SizedBox(height: UIConstants.spacing20),
        _buildCheckableSliderParameter(
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
        _buildCheckableSliderParameter(
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
        const SizedBox(height: 24),
        _buildThinkingSection(),
      ],
    );
  }

  Widget _buildCheckableTextFieldParameter({
    required String label,
    required int? value,
    required String helpText,
    required ValueChanged<int?> onChanged,
  }) {
    final isEnabled = value != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: CustomTextField.labelHorizontalPadding),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: isEnabled,
                  onChanged: (checked) {
                    if (checked == true) {
                      onChanged(0);
                    } else {
                      onChanged(null);
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(width: CustomTextField.labelIconSpacing),
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      content: Text(helpText),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('확인'),
                        ),
                      ],
                    ),
                  );
                },
                child: Icon(
                  Icons.help_outline,
                  size: CustomTextField.helpIconSize,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: CustomTextField.labelBottomSpacing),
        TextFormField(
          initialValue: value?.toString() ?? '',
          enabled: isEnabled,
          keyboardType: TextInputType.number,
          style: Theme.of(context).textTheme.bodyMedium,
          decoration: InputDecoration(
            hintText: '숫자 입력',
            hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(CustomTextField.borderRadius),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: CustomTextField.borderOpacity),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(CustomTextField.borderRadius),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: CustomTextField.borderOpacity),
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(CustomTextField.borderRadius),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(CustomTextField.borderRadius),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: CustomTextField.horizontalPadding,
              vertical: CustomTextField.verticalPadding,
            ),
            isDense: true,
          ),
          onTapOutside: (event) {
            FocusScope.of(context).unfocus();
          },
          onFieldSubmitted: (text) {
            if (text.isEmpty) {
              onChanged(0);
            } else {
              final newValue = int.tryParse(text);
              if (newValue != null) {
                onChanged(newValue);
              }
            }
          },
          onEditingComplete: () {
            FocusScope.of(context).unfocus();
          },
        ),
      ],
    );
  }

  Widget _buildCheckableSliderParameter({
    required String label,
    required double? value,
    required double defaultValue,
    required double min,
    required double max,
    required int divisions,
    required String helpText,
    required ValueChanged<double?> onChanged,
  }) {
    final isEnabled = value != null;
    final displayValue = value ?? defaultValue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: CustomTextField.labelHorizontalPadding),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: isEnabled,
                  onChanged: (checked) {
                    if (checked == true) {
                      onChanged(defaultValue);
                    } else {
                      onChanged(null);
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(width: CustomTextField.labelIconSpacing),
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      content: Text(helpText),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('확인'),
                        ),
                      ],
                    ),
                  );
                },
                child: Icon(
                  Icons.help_outline,
                  size: CustomTextField.helpIconSize,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Text(
                displayValue.toStringAsFixed(2),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isEnabled
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: CustomTextField.labelBottomSpacing),
        Slider(
          value: displayValue,
          min: min,
          max: max,
          divisions: divisions,
          label: displayValue.toStringAsFixed(2),
          onChanged: isEnabled
              ? (newValue) => onChanged(newValue)
              : null,
        ),
      ],
    );
  }

  Widget _buildSimpleTextFieldParameter({
    required String label,
    required int? value,
    required String helpText,
    required ValueChanged<int?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: CustomTextField.labelHorizontalPadding),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(width: CustomTextField.labelIconSpacing),
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      content: Text(helpText),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('확인'),
                        ),
                      ],
                    ),
                  );
                },
                child: Icon(
                  Icons.help_outline,
                  size: CustomTextField.helpIconSize,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: CustomTextField.labelBottomSpacing),
        TextFormField(
          initialValue: value?.toString() ?? '',
          keyboardType: TextInputType.number,
          style: Theme.of(context).textTheme.bodyMedium,
          decoration: InputDecoration(
            hintText: '숫자 입력',
            hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(CustomTextField.borderRadius),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: CustomTextField.borderOpacity),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(CustomTextField.borderRadius),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: CustomTextField.borderOpacity),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(CustomTextField.borderRadius),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: CustomTextField.horizontalPadding,
              vertical: CustomTextField.verticalPadding,
            ),
            isDense: true,
          ),
          onTapOutside: (event) {
            FocusScope.of(context).unfocus();
          },
          onFieldSubmitted: (text) {
            if (text.isEmpty) {
              onChanged(null);
            } else {
              final newValue = int.tryParse(text);
              if (newValue != null) {
                onChanged(newValue);
              }
            }
          },
          onEditingComplete: () {
            FocusScope.of(context).unfocus();
          },
        ),
      ],
    );
  }

  Widget _buildThinkingSection() {
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
              Text(
                '사고기능 구성',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
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
                  Row(
                    children: [
                      Checkbox(
                        value: _parameters.includeThoughts ?? false,
                        onChanged: (value) {
                          setState(() {
                            _parameters = _parameters.copyWith(
                              includeThoughts: value == true ? true : null,
                            );
                          });
                        },
                      ),
                      Text(
                        '생각 포함',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSimpleTextFieldParameter(
                    label: '생각토큰 수',
                    value: _parameters.thinkingMaxTokens,
                    helpText: '생각에 사용할 최대 토큰 수입니다.',
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
                        padding: const EdgeInsets.symmetric(horizontal: CustomTextField.labelHorizontalPadding),
                        child: Text(
                          '생각 수준',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                      const SizedBox(height: CustomTextField.labelBottomSpacing),
                      DropdownButtonFormField<ThinkingLevel>(
                        value: _parameters.thinkingLevel ?? ThinkingLevel.unspecified,
                        style: Theme.of(context).textTheme.bodyMedium,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(CustomTextField.borderRadius),
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.outline.withValues(alpha: CustomTextField.borderOpacity),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(CustomTextField.borderRadius),
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.outline.withValues(alpha: CustomTextField.borderOpacity),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(CustomTextField.borderRadius),
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: CustomTextField.horizontalPadding,
                            vertical: CustomTextField.verticalPadding,
                          ),
                          isDense: true,
                        ),
                        items: ThinkingLevel.values.map((level) {
                          return DropdownMenuItem(
                            value: level,
                            child: Text(level.displayName),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _parameters = _parameters.copyWith(thinkingLevel: value);
                            });
                          }
                        },
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
