import 'package:flutter/material.dart';
import 'package:flan/constants/ui_constants.dart';

enum TextFieldSize { small, large }

class CommonTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String? helpMessage;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final bool readOnly;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final TextFieldSize size;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final bool enabled;

  const CommonTextField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.helpMessage,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.keyboardType,
    this.readOnly = false,
    this.onTap,
    this.onChanged,
    this.size = TextFieldSize.small,
    this.suffixIcon,
    this.prefixIcon,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = size == TextFieldSize.small
        ? UIConstants.borderRadiusSmall
        : UIConstants.borderRadiusMedium;

    final contentPadding = size == TextFieldSize.small
        ? UIConstants.textFieldPaddingSmall
        : UIConstants.textFieldPaddingLarge;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (labelText != null) ...[
          if (helpMessage != null)
            Row(
              children: [
                Text(
                  labelText!,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
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
            )
          else
            Text(
              labelText!,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          const SizedBox(height: UIConstants.spacing8),
        ],
        TextField(
          controller: controller,
          maxLines: maxLines,
          minLines: minLines,
          maxLength: maxLength,
          keyboardType: keyboardType,
          readOnly: readOnly,
          onTap: onTap,
          onChanged: onChanged,
          enabled: enabled,
          decoration: InputDecoration(
            hintText: hintText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: BorderSide(
                color: Theme.of(context)
                    .colorScheme
                    .outline
                    .withValues(alpha: UIConstants.opacityMedium),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: BorderSide(
                color: Theme.of(context)
                    .colorScheme
                    .outline
                    .withValues(alpha: UIConstants.opacityMedium),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            contentPadding: contentPadding,
            isDense: true,
            suffixIcon: suffixIcon,
            prefixIcon: prefixIcon,
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
