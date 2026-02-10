import 'package:flutter/material.dart';
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

  final List<PromptItemFolder> _folders = [];
  final List<PromptItem> _standaloneItems = [];
  final Map<int, TextEditingController> _contentControllers = {};
  int _nextTempId = -1;
  int _getNextTempId() => _nextTempId--;
  int _nextFolderTempId = -1;
  int _getNextFolderTempId() => _nextFolderTempId--;

  // Parameter controllers
  final _maxInputTokensController = TextEditingController();
  final _maxOutputTokensController = TextEditingController();
  final _thinkingTokensController = TextEditingController();
  final _thinkingMaxTokensController = TextEditingController();

  bool get _isEditing => widget.prompt != null;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    if (_isEditing) {
      _loadPromptData();
    }
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
    setState(() {
      final newFolder = PromptItemFolder(
        id: _getNextFolderTempId(),
        name: '새 폴더',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: _isEditing ? '프롬프트 수정' : '새 프롬프트',
        actions: [
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
              onUpdate: () => setState(() {}),
              onDeleteItem: _deleteItem,
              onDeleteFolder: _deleteFolder,
              onAddItem: _addItem,
              onAddFolder: _addFolder,
              onMoveItemToFolder: _moveItemToFolder,
              onMoveItemOutOfFolder: _moveItemOutOfFolder,
              onReorderItem: _reorderItem,
              onReorderFolder: _reorderFolder,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoTab() {
    return ListView(
        padding: const EdgeInsets.all(UIConstants.spacing20),
        children: [
          CommonCustomTextField(
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
                padding: const EdgeInsets.symmetric(horizontal: CommonCustomTextField.labelHorizontalPadding),
                child: Row(
                  children: [
                    const CommonTitleMedium(text: '설명'),
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
              const SizedBox(height: CommonCustomTextField.labelBottomSpacing),
              CommonEditText(
                controller: _descriptionController,
                hintText: '이 프롬프트에 대한 설명을 입력하세요',
                size: CommonEditTextSize.medium,
                maxLines: null,
                minLines: 3,
              ),
            ],
          ),
          // TODO: 지원 모델 기능 구현 후 숨김 해제
        ],
    );
  }

  Widget _buildParametersTab() {
    return ListView(
      padding: const EdgeInsets.all(UIConstants.spacing20),
      children: [
        const CommonInfoBox(
          message: 'AI 모델의 생성 파라미터를 설정합니다. 모델에 따라 지원되는 파라미터가 다를 수 있습니다.',
        ),
        const SizedBox(height: 24),
        CommonParameterTextField(
          label: '최대 입력 크기',
          helpText: '입력할 수 있는 최대 토큰 수입니다.',
          controller: _maxInputTokensController,
          onChanged: (value) {
            setState(() {
              _parameters = _parameters.copyWith(maxInputTokens: value);
            });
          },
        ),
        const SizedBox(height: UIConstants.spacing20),
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
        CommonParameterTextField(
          label: '사고토큰',
          helpText: '사고에 사용할 토큰 수입니다.',
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
        const SizedBox(height: 24),
        _buildThinkingSection(),
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
              const CommonTitleMedium(text: '사고기능 구성'),
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
                  // TODO: 생각 포함 토글 기능 수정 후 숨김 해제
                  CommonParameterTextField(
                    label: '생각토큰 수',
                    helpText: '생각에 사용할 최대 토큰 수입니다.',
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
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: CommonCustomTextField.labelHorizontalPadding),
                        child: CommonTitleMedium(text: '생각 수준'),
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
