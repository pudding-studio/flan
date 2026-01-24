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
class CommonTitleMedium extends StatelessWidget {
  final String text;

  const CommonTitleMedium({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return _BaseTitleMediumText(text: text);
  }
}

/// 도움말 아이콘이 있는 제목 텍스트 위젯
///
/// 제목 + 도움말 아이콘 조합
class CommonTitleMediumWithHelp extends StatelessWidget {
  final String label;
  final String helpMessage;
  final TextStyle? labelStyle;

  const CommonTitleMediumWithHelp({
    super.key,
    required this.label,
    required this.helpMessage,
    this.labelStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _BaseTitleMediumText(
          text: label,
          style: labelStyle,
        ),
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(helpMessage),
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
