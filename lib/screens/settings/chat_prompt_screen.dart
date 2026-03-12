import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../database/database_helper.dart';
import '../../models/prompt/chat_prompt.dart';
import '../../utils/common_dialog.dart';
import '../../services/default_seeder_service.dart';
import '../../utils/silly_tavern_preset_converter.dart';
import '../../widgets/common/common_appbar.dart';
import '../../widgets/common/common_fab.dart';
import '../../widgets/settings/settings_prompt_list_item.dart';
import 'prompt_edit_screen.dart';

class ChatPromptScreen extends StatefulWidget {
  const ChatPromptScreen({super.key});

  @override
  State<ChatPromptScreen> createState() => _ChatPromptScreenState();
}

class _ChatPromptScreenState extends State<ChatPromptScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  List<ChatPrompt> _prompts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrompts();
  }

  Future<void> _loadPrompts() async {
    setState(() => _isLoading = true);
    try {
      final prompts = await _db.readAllChatPrompts();
      setState(() => _prompts = prompts);
    } catch (e) {
      if (mounted) {
        CommonDialog.showSnackBar(
          context: context,
          message: '프롬프트 목록을 불러오는데 실패했습니다: $e',
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectPrompt(int id) async {
    try {
      await _db.setSelectedChatPrompt(id);
      await _loadPrompts();
    } catch (e) {
      if (mounted) {
        CommonDialog.showSnackBar(
          context: context,
          message: '프롬프트 선택에 실패했습니다: $e',
        );
      }
    }
  }

  Future<void> _deletePrompt(int id, String name) async {
    final confirm = await CommonDialog.showDeleteConfirmation(
      context: context,
      itemName: name,
    );

    if (confirm) {
      try {
        await _db.deleteChatPrompt(id);
        await _loadPrompts();
        if (mounted) {
          CommonDialog.showSnackBar(
            context: context,
            message: '프롬프트가 삭제되었습니다',
          );
        }
      } catch (e) {
        if (mounted) {
          CommonDialog.showSnackBar(
            context: context,
            message: '프롬프트 삭제에 실패했습니다: $e',
          );
        }
      }
    }
  }

  Future<void> _navigateToEdit(ChatPrompt? prompt) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => PromptEditScreen(prompt: prompt),
      ),
    );
    if (result == true) {
      _loadPrompts();
    }
  }

  Future<void> _createNewPrompt() async {
    final defaults = _prompts.where((p) => p.isDefault).toList();

    if (defaults.isEmpty) {
      _navigateToEdit(null);
      return;
    }

    if (defaults.length == 1) {
      await _forkPrompt(defaults.first);
      return;
    }

    // Multiple defaults: show selection dialog
    final selected = await showDialog<ChatPrompt?>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('기본 프롬프트 선택'),
        children: [
          ...defaults.map((prompt) =>
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, prompt),
              child: ListTile(
                leading: Icon(
                  Icons.description_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(prompt.name),
                subtitle: prompt.description != null
                    ? Text(
                        prompt.description!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    : null,
              ),
            ),
          ),
          const Divider(),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context),
            child: const ListTile(
              leading: Icon(Icons.add),
              title: Text('빈 프롬프트'),
            ),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (selected != null) {
      await _forkPrompt(selected);
    } else {
      _navigateToEdit(null);
    }
  }

  Future<void> _duplicatePrompt(ChatPrompt sourcePrompt) async {
    try {
      final folders = await _db.readPromptItemFolders(sourcePrompt.id!);
      for (final folder in folders) {
        folder.items.addAll(await _db.readPromptItemsByFolder(folder.id!));
      }
      final standaloneItems = await _db.readStandalonePromptItems(sourcePrompt.id!);

      final duplicatedPrompt = ChatPrompt(
        name: '${sourcePrompt.name} (복사본)',
        description: sourcePrompt.description,
        supportedModel: sourcePrompt.supportedModel,
        parameters: sourcePrompt.parameters,
      );
      final newPromptId = await _db.createChatPrompt(duplicatedPrompt);

      // Copy conditions first to build ID remap
      final conditionIdMap = await _copyConditions(sourcePrompt.id!, newPromptId);

      for (final folder in folders) {
        final newFolderId = await _db.createPromptItemFolder(
          folder.copyWith(id: null, chatPromptId: newPromptId),
        );
        for (int i = 0; i < folder.items.length; i++) {
          final item = folder.items[i];
          final remappedConditionId = item.conditionId != null
              ? conditionIdMap[item.conditionId!]
              : null;
          await _db.createPromptItem(
            item.copyWithNullableFolderId(
              id: null,
              chatPromptId: newPromptId,
              folderId: newFolderId,
              order: i,
              enableMode: item.enableMode,
              conditionId: remappedConditionId,
              conditionValue: item.conditionValue,
            ),
          );
        }
      }
      for (int i = 0; i < standaloneItems.length; i++) {
        final item = standaloneItems[i];
        final remappedConditionId = item.conditionId != null
            ? conditionIdMap[item.conditionId!]
            : null;
        await _db.createPromptItem(
          item.copyWithNullableFolderId(
            id: null,
            chatPromptId: newPromptId,
            folderId: null,
            order: i,
            enableMode: item.enableMode,
            conditionId: remappedConditionId,
            conditionValue: item.conditionValue,
          ),
        );
      }

      final regexRules = await _db.readPromptRegexRules(sourcePrompt.id!);
      for (int i = 0; i < regexRules.length; i++) {
        await _db.createPromptRegexRule(
          regexRules[i].copyWith(
            id: null,
            chatPromptId: newPromptId,
            order: i,
          ),
        );
      }

      await _loadPrompts();
      if (mounted) {
        CommonDialog.showSnackBar(
          context: context,
          message: '프롬프트가 복사되었습니다',
        );
      }
    } catch (e) {
      if (mounted) {
        CommonDialog.showSnackBar(
          context: context,
          message: '프롬프트 복사에 실패했습니다: $e',
        );
      }
    }
  }

  Future<void> _forkPrompt(ChatPrompt sourcePrompt) async {
    try {
      final folders = await _db.readPromptItemFolders(sourcePrompt.id!);
      for (final folder in folders) {
        folder.items.addAll(await _db.readPromptItemsByFolder(folder.id!));
      }
      final standaloneItems = await _db.readStandalonePromptItems(sourcePrompt.id!);

      final forkedPrompt = ChatPrompt(
        name: '',
        description: '',
        supportedModel: sourcePrompt.supportedModel,
        parameters: sourcePrompt.parameters,
      );
      final newPromptId = await _db.createChatPrompt(forkedPrompt);

      // Copy conditions first to build ID remap
      final conditionIdMap = await _copyConditions(sourcePrompt.id!, newPromptId);

      for (final folder in folders) {
        final newFolderId = await _db.createPromptItemFolder(
          folder.copyWith(id: null, chatPromptId: newPromptId),
        );
        for (int i = 0; i < folder.items.length; i++) {
          final item = folder.items[i];
          final remappedConditionId = item.conditionId != null
              ? conditionIdMap[item.conditionId!]
              : null;
          await _db.createPromptItem(
            item.copyWithNullableFolderId(
              id: null,
              chatPromptId: newPromptId,
              folderId: newFolderId,
              order: i,
              enableMode: item.enableMode,
              conditionId: remappedConditionId,
              conditionValue: item.conditionValue,
            ),
          );
        }
      }
      for (int i = 0; i < standaloneItems.length; i++) {
        final item = standaloneItems[i];
        final remappedConditionId = item.conditionId != null
            ? conditionIdMap[item.conditionId!]
            : null;
        await _db.createPromptItem(
          item.copyWithNullableFolderId(
            id: null,
            chatPromptId: newPromptId,
            folderId: null,
            order: i,
            enableMode: item.enableMode,
            conditionId: remappedConditionId,
            conditionValue: item.conditionValue,
          ),
        );
      }

      // Fork regex rules
      final regexRules = await _db.readPromptRegexRules(sourcePrompt.id!);
      for (int i = 0; i < regexRules.length; i++) {
        await _db.createPromptRegexRule(
          regexRules[i].copyWith(
            id: null,
            chatPromptId: newPromptId,
            order: i,
          ),
        );
      }

      final forkedWithId = await _db.readChatPrompt(newPromptId);
      if (mounted && forkedWithId != null) {
        _navigateToEdit(forkedWithId);
      }
    } catch (e) {
      if (mounted) {
        CommonDialog.showSnackBar(
          context: context,
          message: '프롬프트 복사에 실패했습니다: $e',
        );
      }
    }
  }

  Future<Map<int, int>> _copyConditions(int sourcePromptId, int newPromptId) async {
    final conditions = await _db.readPromptConditions(sourcePromptId);
    final conditionIdMap = <int, int>{};
    for (int i = 0; i < conditions.length; i++) {
      final oldId = conditions[i].id;
      final options = await _db.readPromptConditionOptions(oldId!);
      final newConditionId = await _db.createPromptCondition(
        conditions[i].copyWith(id: null, chatPromptId: newPromptId, order: i),
      );
      conditionIdMap[oldId] = newConditionId;
      for (int j = 0; j < options.length; j++) {
        await _db.createPromptConditionOption(
          options[j].copyWith(id: null, conditionId: newConditionId, order: j),
        );
      }
    }

    final presets = await _db.readPromptConditionPresets(sourcePromptId);
    for (int i = 0; i < presets.length; i++) {
      final newPresetId = await _db.createPromptConditionPreset(
        presets[i].copyWith(id: null, chatPromptId: newPromptId, order: i),
      );
      final values = await _db.readPromptConditionPresetValues(presets[i].id!);
      for (final value in values) {
        final remappedConditionId = value.conditionId != null
            ? conditionIdMap[value.conditionId!]
            : null;
        await _db.createPromptConditionPresetValue(
          value.copyWith(
            id: null,
            presetId: newPresetId,
            conditionId: remappedConditionId,
          ),
        );
      }
    }

    return conditionIdMap;
  }

  Future<void> _resetDefaultPrompts() async {
    final confirm = await CommonDialog.showConfirmation(
      context: context,
      title: '초기화',
      content: '모든 기본 프롬프트를 초기 상태로 되돌리시겠습니까?',
      confirmText: '초기화',
      isDestructive: true,
    );
    if (confirm != true) return;

    try {
      await DefaultSeederService().seedDefaultChatPrompts();

      await _loadPrompts();
      if (mounted) {
        CommonDialog.showSnackBar(
          context: context,
          message: '기본 프롬프트가 초기화되었습니다',
        );
      }
    } catch (e) {
      if (mounted) {
        CommonDialog.showSnackBar(
          context: context,
          message: '기본 프롬프트 초기화에 실패했습니다: $e',
        );
      }
    }
  }

  Future<void> _exportPrompt(ChatPrompt prompt) async {
    try {
      final folders = await _db.readPromptItemFolders(prompt.id!);
      for (final folder in folders) {
        folder.items.addAll(await _db.readPromptItemsByFolder(folder.id!));
      }
      final standaloneItems = await _db.readStandalonePromptItems(prompt.id!);
      final regexRules = await _db.readPromptRegexRules(prompt.id!);

      final conditions = await _db.readPromptConditions(prompt.id!);
      for (final condition in conditions) {
        final options = await _db.readPromptConditionOptions(condition.id!);
        condition.options.addAll(options);
      }
      final conditionPresets = await _db.readPromptConditionPresets(prompt.id!);
      for (final preset in conditionPresets) {
        final values = await _db.readPromptConditionPresetValues(preset.id!);
        preset.values.addAll(values);
      }

      final jsonString = const JsonEncoder.withIndent('  ').convert(
        prompt.toJson(
          folders: folders,
          standaloneItems: standaloneItems,
          regexRules: regexRules,
          conditions: conditions,
          conditionPresets: conditionPresets,
        ),
      );
      final fileName = '${prompt.name}.json';

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
          message: '프롬프트 내보내기 실패: $e',
        );
      }
    }
  }

  Future<void> _importPrompt() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) return;

      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;

      final Map<String, dynamic> normalizedData;
      if (SillyTavernPresetConverter.isSillyTavernPreset(jsonData)) {
        final fileName = result.files.single.name.replaceAll('.json', '');
        normalizedData = SillyTavernPresetConverter.convertToNativeFormat(
          jsonData,
          fileName: fileName,
        );
      } else {
        normalizedData = jsonData;
      }

      final prompt = ChatPrompt.fromJson(normalizedData);
      await _db.insertChatPromptFromJson(prompt, normalizedData);

      await _loadPrompts();

      if (mounted) {
        CommonDialog.showSnackBar(
          context: context,
          message: '프롬프트가 가져오기 되었습니다',
        );
      }
    } catch (e) {
      if (mounted) {
        CommonDialog.showSnackBar(
          context: context,
          message: '프롬프트 가져오기 실패: $e',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth * 0.05;

    return Scaffold(
      appBar: CommonAppBar(
        title: '채팅 프롬프트',
        actions: [
          CommonAppBarPopupMenuButton<String>(
            tooltip: '더보기',
            onSelected: (value) {
              if (value == 'import') {
                _importPrompt();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'import',
                child: Row(
                  children: [
                    Icon(Icons.download_outlined, size: 20),
                    SizedBox(width: 12),
                    Text('가져오기'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _prompts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 80,
                        color: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.color
                            ?.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '프롬프트가 없습니다',
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.color
                              ?.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '+ 버튼을 눌러 새 프롬프트를 추가해보세요',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.color
                              ?.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: 16.0,
                  ),
                  itemCount: _prompts.length,
                  itemBuilder: (context, index) {
                    final prompt = _prompts[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: SettingsPromptListItem(
                        title: prompt.name,
                        description: prompt.description ?? '${prompt.items.length}개 항목',
                        isSelected: prompt.isSelected,
                        isDefault: prompt.isDefault,
                        onRadioTap: () => _selectPrompt(prompt.id!),
                        onTap: prompt.isDefault ? null : () => _navigateToEdit(prompt),
                        onEdit: prompt.isDefault ? null : () => _navigateToEdit(prompt),
                        onCopy: () => _duplicatePrompt(prompt),
                        onReset: prompt.isDefault ? () => _resetDefaultPrompts() : null,
                        onExport: () => _exportPrompt(prompt),
                        onDelete: prompt.isDefault
                            ? null
                            : () => _deletePrompt(prompt.id!, prompt.name),
                      ),
                    );
                  },
                ),
      floatingActionButton: CommonFab(
        onPressed: () => _createNewPrompt(),
      ),
    );
  }
}
