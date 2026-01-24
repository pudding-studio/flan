import 'package:flutter/material.dart';

enum CommonEditTextSize {
  medium,
  small,
}

class _EditTextConfig {
  final double borderRadius;
  final EdgeInsets contentPadding;
  final bool isDense;
  final TextStyle? Function(BuildContext) getTextStyle;

  const _EditTextConfig({
    required this.borderRadius,
    required this.contentPadding,
    required this.isDense,
    required this.getTextStyle,
  });
}

class CommonEditText extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final int? maxLines;
  final int? minLines;
  final CommonEditTextSize size;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final bool expands;
  final TextAlignVertical? textAlignVertical;
  final FormFieldValidator<String>? validator;
  final int? maxLength;
  final bool obscureText;
  final Widget? suffixIcon;

  static final Map<CommonEditTextSize, _EditTextConfig> _configs = {
    CommonEditTextSize.medium: _EditTextConfig(
      borderRadius: 10.0,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 10.0),
      isDense: false,
      getTextStyle: (context) => Theme.of(context).textTheme.bodyMedium,
    ),
    CommonEditTextSize.small: _EditTextConfig(
      borderRadius: 8.0,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      isDense: true,
      getTextStyle: (context) => Theme.of(context).textTheme.bodySmall,
    ),
  };

  const CommonEditText({
    super.key,
    this.controller,
    this.hintText,
    this.maxLines,
    this.minLines,
    this.size = CommonEditTextSize.medium,
    this.onChanged,
    this.keyboardType,
    this.expands = false,
    this.textAlignVertical,
    this.validator,
    this.maxLength,
    this.obscureText = false,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    final config = _configs[size]!;
    final borderRadius = config.borderRadius;
    final contentPadding = config.contentPadding;
    final textStyle = config.getTextStyle(context);
    final isDense = config.isDense;

    return TextFormField(
      controller: controller,
      style: textStyle,
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: textStyle?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        contentPadding: contentPadding,
        suffixIcon: suffixIcon,
        counterText: '',
        isDense: isDense,
      ),
      maxLength: maxLength,
      maxLines: maxLines,
      minLines: minLines,
      expands: expands,
      textAlignVertical: textAlignVertical,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
    );
  }
}
