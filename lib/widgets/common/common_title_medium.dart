import 'package:flutter/material.dart';
import '../../constants/ui_constants.dart';

/// titleSmall 스타일의 기본 텍스트 위젯
///
/// 모든 제목/라벨 텍스트의 기본 형태
class _BaseTitleMediumText extends StatelessWidget {
  final String text;
  final TextStyle? style;

  const _BaseTitleMediumText({
    required this.text,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: style ?? Theme.of(context).textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

/// titleSmall 스타일의 제목 텍스트 위젯
///
/// 라벨이나 섹션 제목으로 사용
/// helpMessage가 제공되면 도움말 아이콘이 함께 표시됨
/// 색상은 onSurface로 고정됨
class CommonTitleMedium extends StatelessWidget {
  final String text;
  final String? helpMessage;
  final TextStyle? style;

  const CommonTitleMedium({
    super.key,
    required this.text,
    this.helpMessage,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = style ?? Theme.of(context).textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w600,
      color: Theme.of(context).colorScheme.onSurface,
    );

    if (helpMessage == null) {
      return _BaseTitleMediumText(text: text, style: effectiveStyle);
    }

    return Row(
      children: [
        _BaseTitleMediumText(text: text, style: effectiveStyle),
        const SizedBox(width: UIConstants.spacing4),
        GestureDetector(
          onTap: () => _showHelpDialog(context),
          child: Icon(
            Icons.help_outline,
            size: UIConstants.helpIconSize,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  void _showHelpDialog(BuildContext context) {
    if (helpMessage == null) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(helpMessage!),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}
