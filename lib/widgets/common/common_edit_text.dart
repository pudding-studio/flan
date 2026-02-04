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

class CommonEditText extends StatefulWidget {
  final TextEditingController? controller;
  final String? hintText;
  final int? maxLines;
  final int? minLines;
  final CommonEditTextSize size;
  /// 실시간으로 값이 변경될 때마다 호출 (입력 중에도 호출됨)
  final ValueChanged<String>? onChanged;
  /// 포커스를 잃었을 때 호출 (자동저장에 사용)
  final ValueChanged<String>? onFocusLost;
  final TextInputType? keyboardType;
  final bool expands;
  final TextAlignVertical? textAlignVertical;
  final FormFieldValidator<String>? validator;
  final int? maxLength;
  final bool obscureText;
  final Widget? suffixIcon;
  final bool enabled;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;

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

  final String? initialValue;

  const CommonEditText({
    super.key,
    this.controller,
    this.hintText,
    this.maxLines,
    this.minLines,
    this.size = CommonEditTextSize.medium,
    this.onChanged,
    this.onFocusLost,
    this.keyboardType,
    this.expands = false,
    this.textAlignVertical,
    this.validator,
    this.maxLength,
    this.obscureText = false,
    this.suffixIcon,
    this.enabled = true,
    this.textInputAction,
    this.onFieldSubmitted,
    this.initialValue,
  });

  @override
  State<CommonEditText> createState() => _CommonEditTextState();
}

class _CommonEditTextState extends State<CommonEditText> {
  late FocusNode _focusNode;
  TextEditingController? _internalController;

  TextEditingController get _effectiveController =>
      widget.controller ?? _internalController!;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
    if (widget.controller == null) {
      _internalController = TextEditingController(text: widget.initialValue);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _internalController?.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus && widget.onFocusLost != null) {
      widget.onFocusLost!(_effectiveController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = CommonEditText._configs[widget.size]!;
    final borderRadius = config.borderRadius;
    final contentPadding = config.contentPadding;
    final textStyle = config.getTextStyle(context);
    final isDense = config.isDense;

    return TextFormField(
      controller: _effectiveController,
      focusNode: _focusNode,
      style: textStyle,
      obscureText: widget.obscureText,
      enabled: widget.enabled,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onFieldSubmitted,
      decoration: InputDecoration(
        hintText: widget.hintText,
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
        suffixIcon: widget.suffixIcon,
        counterText: '',
        isDense: isDense,
      ),
      maxLength: widget.maxLength,
      maxLines: widget.maxLines,
      minLines: widget.minLines,
      expands: widget.expands,
      textAlignVertical: widget.textAlignVertical,
      keyboardType: widget.keyboardType,
      validator: widget.validator,
      onChanged: widget.onChanged,
    );
  }
}
