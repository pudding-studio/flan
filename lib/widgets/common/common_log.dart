import 'package:flutter/material.dart';

/// 로그 상세 화면의 정보 행
class CommonLogInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const CommonLogInfoRow({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

/// 로그 상세 화면의 섹션 카드 헤더
class CommonLogSectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onCopy;
  final bool showFormatToggle;
  final bool formatEnabled;
  final ValueChanged<bool>? onFormatChanged;

  const CommonLogSectionHeader({
    super.key,
    required this.title,
    required this.onCopy,
    this.showFormatToggle = true,
    this.formatEnabled = false,
    this.onFormatChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.copy, size: 20),
          onPressed: onCopy,
          tooltip: '복사',
        ),
        if (showFormatToggle) ...[
          Switch(
            value: formatEnabled,
            onChanged: onFormatChanged,
          ),
          Text('포맷', style: Theme.of(context).textTheme.bodySmall),
        ],
      ],
    );
  }
}

/// 로그 상세 화면의 코드 블록
class CommonLogCodeBlock extends StatelessWidget {
  final String content;

  const CommonLogCodeBlock({
    super.key,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: SelectableText(
        content,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontFamily: 'monospace',
            ),
      ),
    );
  }
}
