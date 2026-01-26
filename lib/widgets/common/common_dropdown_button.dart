import 'package:flutter/material.dart';

enum CommonDropdownButtonSize {
  medium,
  small,
}

class _DropdownConfig {
  final double borderRadius;
  final EdgeInsets contentPadding;
  final bool isDense;
  final TextStyle? Function(BuildContext) getTextStyle;
  final double menuMaxHeight;

  const _DropdownConfig({
    required this.borderRadius,
    required this.contentPadding,
    required this.isDense,
    required this.getTextStyle,
    required this.menuMaxHeight,
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 6.0),
      isDense: true,
      getTextStyle: (context) => Theme.of(context).textTheme.bodyMedium,
      menuMaxHeight: 300.0,
    ),
    CommonDropdownButtonSize.small: _DropdownConfig(
      borderRadius: 8.0,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      isDense: true,
      getTextStyle: (context) => Theme.of(context).textTheme.bodySmall,
      menuMaxHeight: 250.0,
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
    final isDense = config.isDense;
    final menuMaxHeight = config.menuMaxHeight;

    return DropdownButtonFormField<T>(
      value: value,
      itemHeight: null,
      isExpanded: isExpanded,
      isDense: isDense,
      style: textStyle,
      menuMaxHeight: menuMaxHeight,
      borderRadius: BorderRadius.circular(borderRadius),
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
        isDense: isDense,
      ),
      items: items.map((item) {
        return DropdownMenuItem<T>(
          value: item,
          child: Container(
            height: 40.0, // 48보다 작은 원하는 높이 설정
            alignment: Alignment.centerLeft,
            child: Text(
              labelBuilder(item),
              style: textStyle,
            ),
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}
