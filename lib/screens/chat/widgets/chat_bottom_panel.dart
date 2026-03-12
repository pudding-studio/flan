import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/viewer_settings_provider.dart';

class ChatBottomPanel extends StatelessWidget {
  const ChatBottomPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final viewer = context.watch<ViewerSettingsProvider>();

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
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '뷰어',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(
              height: 220,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  children: [
                    _buildAdjustRow(
                      context: context,
                      label: '글자 크기',
                      value: '${viewer.fontSize.toInt()}',
                      onMinus: () => viewer.adjustFontSize(-1),
                      onPlus: () => viewer.adjustFontSize(1),
                    ),
                    _buildAdjustRow(
                      context: context,
                      label: '줄 간격',
                      value: viewer.lineHeight.toStringAsFixed(1),
                      onMinus: () => viewer.adjustLineHeight(-0.2),
                      onPlus: () => viewer.adjustLineHeight(0.2),
                    ),
                    _buildAdjustRow(
                      context: context,
                      label: '문단 간격',
                      value: '${viewer.paragraphSpacing.toInt()}',
                      onMinus: () => viewer.adjustParagraphSpacing(-4),
                      onPlus: () => viewer.adjustParagraphSpacing(4),
                    ),
                    _buildAdjustRow(
                      context: context,
                      label: '문단 너비',
                      value: '${viewer.paragraphWidth.toInt()}',
                      onMinus: () => viewer.adjustParagraphWidth(-4),
                      onPlus: () => viewer.adjustParagraphWidth(4),
                    ),
                    _buildAlignRow(context, viewer),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdjustRow({
    required BuildContext context,
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

  Widget _buildAlignRow(BuildContext context, ViewerSettingsProvider viewer) {
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
