import 'package:flutter/material.dart';

class CustomTextField extends StatefulWidget {
  // 스타일 상수
  static const double borderRadius = 10;
  static const double borderOpacity = 0.3;
  static const double horizontalPadding = 18;
  static const double verticalPadding = 10;
  static const double labelHorizontalPadding = 5;
  static const double labelBottomSpacing = 8;
  static const double labelIconSpacing = 4;
  static const double helpIconSize = 16;

  final TextEditingController? controller;
  final String? hintText;
  final int? maxLength;
  final int? maxLines;
  final FormFieldValidator<String>? validator;
  final String? label;
  final String? helpText;
  final bool showCounter;
  final bool obscureText;
  final bool enableObscureToggle;

  const CustomTextField({
    super.key,
    this.controller,
    this.hintText,
    this.maxLength,
    this.maxLines,
    this.validator,
    this.label,
    this.helpText,
    this.showCounter = false,
    this.obscureText = false,
    this.enableObscureToggle = false,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  int _currentLength = 0;
  late bool _isObscured;

  @override
  void initState() {
    super.initState();
    _isObscured = widget.obscureText;
    widget.controller?.addListener(_updateLength);
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_updateLength);
    super.dispose();
  }

  void _updateLength() {
    setState(() {
      _currentLength = widget.controller?.text.length ?? 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: CustomTextField.labelHorizontalPadding),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  widget.label!,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (widget.helpText != null) ...[
                  const SizedBox(width: CustomTextField.labelIconSpacing),
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          content: Text(widget.helpText!),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('확인'),
                            ),
                          ],
                        ),
                      );
                    },
                    child: Icon(
                      Icons.help_outline,
                      size: CustomTextField.helpIconSize,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const Spacer(),
                if (widget.showCounter)
                  Text(
                    '$_currentLength',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        if (widget.label != null) const SizedBox(height: CustomTextField.labelBottomSpacing),
        TextFormField(
          controller: widget.controller,
          style: textTheme.bodyMedium,
          obscureText: _isObscured,
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(CustomTextField.borderRadius),
              borderSide: BorderSide(
                color: colorScheme.outline.withValues(alpha: CustomTextField.borderOpacity),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(CustomTextField.borderRadius),
              borderSide: BorderSide(
                color: colorScheme.outline.withValues(alpha: CustomTextField.borderOpacity),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(CustomTextField.borderRadius),
              borderSide: BorderSide(
                color: colorScheme.primary,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: CustomTextField.horizontalPadding,
              vertical: CustomTextField.verticalPadding,
            ),
            suffixIcon: widget.enableObscureToggle
                ? IconButton(
                    icon: Icon(_isObscured ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _isObscured = !_isObscured),
                  )
                : null,
            counterText: '',
            isDense: true,
          ),
          maxLength: widget.maxLength,
          maxLines: widget.maxLines,
          validator: widget.validator,
        ),
      ],
    );
  }
}
