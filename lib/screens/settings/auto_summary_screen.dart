import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/chat/chat_model.dart';
import '../../models/chat/auto_summary_settings.dart';
import '../../widgets/common/common_appbar.dart';
import '../../widgets/common/common_title_medium.dart';

class AutoSummaryScreen extends StatefulWidget {
  final AutoSummarySettings? initialSettings;
  final int chatRoomId;

  const AutoSummaryScreen({
    super.key,
    this.initialSettings,
    required this.chatRoomId,
  });

  @override
  State<AutoSummaryScreen> createState() => _AutoSummaryScreenState();
}

class _AutoSummaryScreenState extends State<AutoSummaryScreen> {
  late bool _isEnabled;
  late String _selectedModel;
  late TextEditingController _tokenThresholdController;
  late TextEditingController _summaryPromptController;

  @override
  void initState() {
    super.initState();
    _isEnabled = widget.initialSettings?.isEnabled ?? true;
    _selectedModel = widget.initialSettings?.summaryModel ?? 'gemini-2.0-flash-exp';
    _tokenThresholdController = TextEditingController(
      text: (widget.initialSettings?.tokenThreshold ?? 5000).toString(),
    );
    _summaryPromptController = TextEditingController(
      text: widget.initialSettings?.summaryPrompt ??
          'Please summarize the following conversation concisely.',
    );
  }

  @override
  void dispose() {
    _tokenThresholdController.dispose();
    _summaryPromptController.dispose();
    super.dispose();
  }

  void _saveSettings() {
    final settings = AutoSummarySettings(
      id: widget.initialSettings?.id,
      chatRoomId: widget.chatRoomId,
      isEnabled: _isEnabled,
      summaryModel: _selectedModel,
      tokenThreshold: int.tryParse(_tokenThresholdController.text) ?? 5000,
      summaryPrompt: _summaryPromptController.text,
    );

    Navigator.pop(context, settings);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: '자동 요약',
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveSettings,
          ),
        ],
      ),
      body: ListView(
        children: [
          _buildSectionHeader('자동 요약 설정'),
          SwitchListTile(
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
              child: TextField(
                controller: _tokenThresholdController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: const InputDecoration(
                  labelText: '자동요약 시작 토큰 수',
                  helperText: '이 토큰 수를 초과하면 자동 요약이 시작됩니다',
                  border: OutlineInputBorder(),
                  suffixText: 'tokens',
                ),
              ),
            ),
            const Divider(),
            _buildSectionHeader('자동 요약 프롬프트'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _summaryPromptController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: '요약 프롬프트',
                  helperText: '요약 생성 시 사용될 프롬프트를 입력하세요',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: CommonTitleMedium(
        text: title,
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
