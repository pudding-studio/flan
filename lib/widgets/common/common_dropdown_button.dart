import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';

enum CommonDropdownButtonSize {
  medium,
  small,
}

class _DropdownConfig {
  final double borderRadius;
  final EdgeInsets contentPadding;
  final TextStyle? Function(BuildContext) getTextStyle;
  final double menuMaxHeight;
  final double itemHeight;

  const _DropdownConfig({
    required this.borderRadius,
    required this.contentPadding,
    required this.getTextStyle,
    required this.menuMaxHeight,
    required this.itemHeight,
  });
}

class CommonDropdownButton<T> extends StatelessWidget {
  final T? value;
  final List<T> items;
  final ValueChanged<T?>? onChanged;
  final String Function(T) labelBuilder;
  final String? hintText;
  final CommonDropdownButtonSize size;
  final bool isExpanded;

  static final Map<CommonDropdownButtonSize, _DropdownConfig> _configs = {
    CommonDropdownButtonSize.medium: _DropdownConfig(
      borderRadius: 10.0,
      contentPadding: const EdgeInsets.only(right: 8, top: 10, bottom: 10),
      getTextStyle: (context) => Theme.of(context).textTheme.bodyMedium,
      menuMaxHeight: 300.0,
      itemHeight: 32.0,
    ),
    CommonDropdownButtonSize.small: _DropdownConfig(
      borderRadius: 8.0,
      contentPadding: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
      getTextStyle: (context) => Theme.of(context).textTheme.bodySmall,
      menuMaxHeight: 250.0,
      itemHeight: 32.0,
    ),
  };

  const CommonDropdownButton({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.labelBuilder,
    this.hintText,
    this.size = CommonDropdownButtonSize.medium,
    this.isExpanded = true,
  });

  @override
  Widget build(BuildContext context) {
    final config = _configs[size]!;
    final borderRadius = config.borderRadius;
    final contentPadding = config.contentPadding;
    final textStyle = config.getTextStyle(context);
    final menuMaxHeight = config.menuMaxHeight;
    final itemHeight = config.itemHeight;

    return DropdownButtonFormField2<T>(
      value: value,
      isExpanded: isExpanded,
      style: textStyle,
      hint: hintText != null
          ? Text(
              hintText!,
              style: textStyle?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
          : null,
      decoration: InputDecoration(
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
        isDense: true,
      ),
      dropdownStyleData: DropdownStyleData(
        maxHeight: menuMaxHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          color: Theme.of(context).colorScheme.surface,
        ),
      ),
      menuItemStyleData: MenuItemStyleData(
        height: itemHeight,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
      ),
      items: items.map((item) {
        return DropdownMenuItem<T>(
          value: item,
          child: Text(
            labelBuilder(item),
            style: textStyle,
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}
