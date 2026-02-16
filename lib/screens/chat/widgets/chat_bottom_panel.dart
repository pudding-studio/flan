import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/chat/chat_room.dart';
import '../../../models/chat/unified_model.dart';
import '../../../models/prompt/chat_prompt.dart';
import '../../../models/character/persona.dart';
import '../../../providers/chat_model_provider.dart';
import '../../../providers/viewer_settings_provider.dart';
import '../../../widgets/common/common_dropdown_button.dart';

class ChatBottomPanel extends StatefulWidget {
  final ChatRoom chatRoom;
  final List<ChatPrompt> chatPrompts;
  final List<Persona> personas;
  final ValueChanged<UnifiedModel> onModelChanged;
  final ValueChanged<int?> onPromptChanged;
  final ValueChanged<int?> onPersonaChanged;
  final ValueChanged<String> onPinModeChanged;
  final ValueChanged<bool> onAutoPinByDateChanged;
  final ValueChanged<bool> onAutoPinByLocationChanged;
  final ValueChanged<bool> onAutoPinByAiChanged;

  const ChatBottomPanel({
    super.key,
    required this.chatRoom,
    required this.chatPrompts,
    required this.personas,
    required this.onModelChanged,
    required this.onPromptChanged,
    required this.onPersonaChanged,
    required this.onPinModeChanged,
    required this.onAutoPinByDateChanged,
    required this.onAutoPinByLocationChanged,
    required this.onAutoPinByAiChanged,
  });

  @override
  State<ChatBottomPanel> createState() => _ChatBottomPanelState();
}

class _ChatBottomPanelState extends State<ChatBottomPanel> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: '채팅창'),
                Tab(text: '뷰어'),
              ],
              labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              unselectedLabelStyle: Theme.of(context).textTheme.bodySmall,
            ),
            SizedBox(
              height: widget.chatRoom.pinMode == 'auto' ? 300 : 220,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildChatSettingsTab(),
                  _buildViewerTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatSettingsTab() {
    final modelProvider = context.watch<ChatModelSettingsProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSettingRow(
            label: '채팅 모델',
            child: Expanded(
              child: CommonDropdownButton<UnifiedModel>(
                value: modelProvider.selectedModel,
                items: modelProvider.availableModels,
                onChanged: (model) {
                  if (model != null) widget.onModelChanged(model);
                },
                labelBuilder: (model) => model.displayName,
                size: CommonDropdownButtonSize.small,
              ),
            ),
          ),
          const SizedBox(height: 8),
          _buildSettingRow(
            label: '채팅 프롬프트',
            child: Expanded(
              child: CommonDropdownButton<int?>(
                value: widget.chatRoom.selectedChatPromptId,
                items: [null, ...widget.chatPrompts.map((p) => p.id)],
                onChanged: (id) => widget.onPromptChanged(id),
                labelBuilder: (id) {
                  if (id == null) return '없음';
                  return widget.chatPrompts.firstWhere((p) => p.id == id).name;
                },
                size: CommonDropdownButtonSize.small,
              ),
            ),
          ),
          const SizedBox(height: 8),
          _buildSettingRow(
            label: '페르소나',
            child: Expanded(
              child: CommonDropdownButton<int?>(
                value: widget.chatRoom.selectedPersonaId,
                items: [null, ...widget.personas.map((p) => p.id)],
                onChanged: (id) => widget.onPersonaChanged(id),
                labelBuilder: (id) {
                  if (id == null) return '없음';
                  return widget.personas.firstWhere((p) => p.id == id).name;
                },
                size: CommonDropdownButtonSize.small,
              ),
            ),
          ),
          const SizedBox(height: 8),
          _buildSettingRow(
            label: '핀 모드',
            child: Expanded(
              child: CommonDropdownButton<String>(
                value: widget.chatRoom.pinMode,
                items: const ['auto', 'manual'],
                onChanged: (mode) {
                  if (mode != null) widget.onPinModeChanged(mode);
                },
                labelBuilder: (mode) => mode == 'auto' ? '자동' : '수동',
                size: CommonDropdownButtonSize.small,
              ),
            ),
          ),
          if (widget.chatRoom.pinMode == 'auto') ...[
            const SizedBox(height: 4),
            _buildToggleRow(
              label: '날짜 기준',
              value: widget.chatRoom.autoPinByDate,
              onChanged: widget.onAutoPinByDateChanged,
            ),
            _buildToggleRow(
              label: '장소 기준',
              value: widget.chatRoom.autoPinByLocation,
              onChanged: widget.onAutoPinByLocationChanged,
            ),
            _buildToggleRow(
              label: 'AI 자동',
              value: widget.chatRoom.autoPinByAi,
              onChanged: widget.onAutoPinByAiChanged,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildViewerTab() {
    final viewer = context.watch<ViewerSettingsProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          _buildAdjustRow(
            label: '글자 크기',
            value: '${viewer.fontSize.toInt()}',
            onMinus: () => viewer.adjustFontSize(-1),
            onPlus: () => viewer.adjustFontSize(1),
          ),
          _buildAdjustRow(
            label: '줄 간격',
            value: viewer.lineHeight.toStringAsFixed(1),
            onMinus: () => viewer.adjustLineHeight(-0.2),
            onPlus: () => viewer.adjustLineHeight(0.2),
          ),
          _buildAdjustRow(
            label: '문단 간격',
            value: '${viewer.paragraphSpacing.toInt()}',
            onMinus: () => viewer.adjustParagraphSpacing(-4),
            onPlus: () => viewer.adjustParagraphSpacing(4),
          ),
          _buildAdjustRow(
            label: '문단 너비',
            value: '${viewer.paragraphWidth.toInt()}',
            onMinus: () => viewer.adjustParagraphWidth(-4),
            onPlus: () => viewer.adjustParagraphWidth(4),
          ),
          _buildAlignRow(viewer),
        ],
      ),
    );
  }

  Widget _buildToggleRow({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0),
      child: Row(
        children: [
          const SizedBox(width: 16),
          SizedBox(
            width: 64,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          const Spacer(),
          SizedBox(
            height: 28,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Switch(
                value: value,
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingRow({required String label, required Widget child}) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
        const SizedBox(width: 8),
        child,
      ],
    );
  }

  Widget _buildAdjustRow({
    required String label,
    required String value,
    required VoidCallback onMinus,
    required VoidCallback onPlus,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.remove, size: 18),
            onPressed: onMinus,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
          ),
          SizedBox(
            width: 40,
            child: Text(
              value,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 18),
            onPressed: onPlus,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
          ),
        ],
      ),
    );
  }

  Widget _buildAlignRow(ViewerSettingsProvider viewer) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text('문단 정렬', style: Theme.of(context).textTheme.bodySmall),
          ),
          const Spacer(),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('왼쪽')),
              ButtonSegment(value: true, label: Text('양쪽')),
            ],
            selected: {viewer.isJustified},
            onSelectionChanged: (_) => viewer.toggleTextAlign(),
            style: ButtonStyle(
              visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
              textStyle: WidgetStatePropertyAll(
                Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
