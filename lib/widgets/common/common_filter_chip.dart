import 'package:flutter/material.dart';

class CommonFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool>? onSelected;
  final bool showCheckmark;

  const CommonFilterChip({
    super.key,
    required this.label,
    required this.selected,
    this.onSelected,
    this.showCheckmark = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return FilterChip(
      selected: selected,
      label: Text(label),
      labelStyle: textTheme.bodyMedium?.copyWith(
        color: selected ? colorScheme.onSecondaryContainer : colorScheme.onSurface,
      ),
      backgroundColor: colorScheme.surface,
      selectedColor: colorScheme.secondaryContainer,
      checkmarkColor: colorScheme.onSecondaryContainer,
      showCheckmark: showCheckmark,
      side: BorderSide(
        color: colorScheme.outline.withValues(alpha: 0.2),
      ),
      onSelected: onSelected,
    );
  }
}
