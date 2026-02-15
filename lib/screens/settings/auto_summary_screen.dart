import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../database/database_helper.dart';
import '../../models/chat/chat_model.dart';
import '../../models/chat/auto_summary_settings.dart';
import '../../widgets/common/common_appbar.dart';
import '../../widgets/common/common_edit_text.dart';

class AutoSummaryScreen extends StatefulWidget {
  final int chatRoomId;

  const AutoSummaryScreen({
    super.key,
    required this.chatRoomId,
  });

  @override
  State<AutoSummaryScreen> createState() => _AutoSummaryScreenState();
}

class _AutoSummaryScreenState extends State<AutoSummaryScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;

  bool _isEnabled = true;
  String _selectedModel = ChatModel.geminiFlash3Preview.modelId;
  late TextEditingController _tokenThresholdController;
  late TextEditingController _summaryPromptController;
  AutoSummarySettings? _existingSettings;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tokenThresholdController = TextEditingController(text: '5000');
    _summaryPromptController = TextEditingController(
      text: 'Please summarize the following conversation concisely.',
    );
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await _db.getAutoSummarySettings(widget.chatRoomId);
    if (settings != null) {
      _existingSettings = settings;
      final isValidModel = ChatModel.values.any((m) => m.modelId == settings.summaryModel);
      setState(() {
        _isEnabled = settings.isEnabled;
        _selectedModel = isValidModel ? settings.summaryModel : ChatModel.geminiFlash3Preview.modelId;
        _tokenThresholdController.text = settings.tokenThreshold.toString();
        _summaryPromptController.text = settings.summaryPrompt;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveAndPop() async {
    final settings = AutoSummarySettings(
      id: _existingSettings?.id,
      chatRoomId: widget.chatRoomId,
      isEnabled: _isEnabled,
      summaryModel: _selectedModel,
      tokenThreshold: int.tryParse(_tokenThresholdController.text) ?? 5000,
      summaryPrompt: _summaryPromptController.text,
    );

    if (_existingSettings != null) {
      await _db.updateAutoSummarySettings(settings);
    } else {
      await _db.createAutoSummarySettings(settings);
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _tokenThresholdController.dispose();
    _summaryPromptController.dispose();
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
        ),
        body: ListView(
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
              const Divider(),
              _buildSectionHeader('요약 모델'),
              _buildListTile(
                icon: Icons.psychology,
                title: '자동요약 모델',
                trailing: DropdownButton<String>(
                  value: _selectedModel,
                  underline: const SizedBox(),
                  borderRadius: BorderRadius.circular(16),
                  items: ChatModel.values
                      .map((model) => DropdownMenuItem(
                            value: model.modelId,
                            child: Text(model.displayName),
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
              ),
              const Divider(),
              _buildSectionHeader('자동 요약 시작 조건'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: CommonEditText(
                  controller: _tokenThresholdController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  hintText: '토큰 수를 입력하세요',
                ),
              ),
              const Divider(),
              _buildSectionHeader('자동 요약 프롬프트'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: CommonEditText(
                  controller: _summaryPromptController,
                  maxLines: 5,
                  hintText: '요약 생성 시 사용될 프롬프트를 입력하세요',
                ),
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

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

  Widget _buildListTile({
    required IconData icon,
    required String title,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: trailing,
    );
  }
}
