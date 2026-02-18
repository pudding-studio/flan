import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../database/database_helper.dart';
import '../../models/prompt/chat_prompt.dart';
import '../../utils/common_dialog.dart';
import '../../widgets/common/common_appbar.dart';
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

      for (final folder in folders) {
        final newFolderId = await _db.createPromptItemFolder(
          folder.copyWith(id: null, chatPromptId: newPromptId),
        );
        for (int i = 0; i < folder.items.length; i++) {
          await _db.createPromptItem(
            folder.items[i].copyWithNullableFolderId(
              id: null,
              chatPromptId: newPromptId,
              folderId: newFolderId,
              order: i,
            ),
          );
        }
      }
      for (int i = 0; i < standaloneItems.length; i++) {
        await _db.createPromptItem(
          standaloneItems[i].copyWithNullableFolderId(
            id: null,
            chatPromptId: newPromptId,
            folderId: null,
            order: i,
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

  Future<void> _exportPrompt(ChatPrompt prompt) async {
    try {
      final folders = await _db.readPromptItemFolders(prompt.id!);
      for (final folder in folders) {
        folder.items.addAll(await _db.readPromptItemsByFolder(folder.id!));
      }
      final standaloneItems = await _db.readStandalonePromptItems(prompt.id!);
      final regexRules = await _db.readPromptRegexRules(prompt.id!);

      final jsonString = const JsonEncoder.withIndent('  ').convert(
        prompt.toJson(folders: folders, standaloneItems: standaloneItems, regexRules: regexRules),
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

      final prompt = ChatPrompt.fromJson(jsonData);
      final promptId = await _db.createChatPrompt(prompt);

      if (jsonData.containsKey('folders')) {
        final folders = prompt.foldersFromJson(jsonData);
        for (final folder in folders) {
          final folderId = await _db.createPromptItemFolder(
            folder.copyWith(id: null, chatPromptId: promptId),
          );
          for (int i = 0; i < folder.items.length; i++) {
            await _db.createPromptItem(
              folder.items[i].copyWithNullableFolderId(
                id: null,
                chatPromptId: promptId,
                folderId: folderId,
                order: i,
              ),
            );
          }
        }
        final standaloneItems = prompt.standaloneItemsFromJson(jsonData);
        for (int i = 0; i < standaloneItems.length; i++) {
          await _db.createPromptItem(
            standaloneItems[i].copyWithNullableFolderId(
              id: null,
              chatPromptId: promptId,
              folderId: null,
              order: i,
            ),
          );
        }
      } else {
        for (int i = 0; i < prompt.items.length; i++) {
          await _db.createPromptItem(
            prompt.items[i].copyWith(
              id: null,
              chatPromptId: promptId,
              order: i,
            ),
          );
        }
      }

      // Import regex rules
      final regexRules = prompt.regexRulesFromJson(jsonData);
      for (int i = 0; i < regexRules.length; i++) {
        await _db.createPromptRegexRule(
          regexRules[i].copyWith(
            id: null,
            chatPromptId: promptId,
            order: i,
          ),
        );
      }

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
                        onTap: () => _navigateToEdit(prompt),
                        onEdit: prompt.isDefault ? null : () => _navigateToEdit(prompt),
                        onExport: () => _exportPrompt(prompt),
                        onDelete: prompt.isDefault
                            ? null
                            : () => _deletePrompt(prompt.id!, prompt.name),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createNewPrompt(),
        elevation: 0,
        child: const Icon(Icons.add),
      ),
    );
  }
}
