import 'package:flutter/material.dart';
import 'package:flan/constants/ui_constants.dart';

class LabelWithHelp extends StatelessWidget {
  final String label;
  final String helpMessage;
  final TextStyle? labelStyle;

  const LabelWithHelp({
    super.key,
    required this.label,
    required this.helpMessage,
    this.labelStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: labelStyle ??
              Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
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
