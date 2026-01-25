import 'package:flutter/material.dart';

import '../../constants/ui_constants.dart';

class CommonSegmentedButton<T extends Object> extends StatelessWidget {
  final List<T> values;
  final T selected;
  final ValueChanged<T> onSelectionChanged;
  final String Function(T) labelBuilder;

  const CommonSegmentedButton({
    super.key,
    required this.values,
    required this.selected,
    required this.onSelectionChanged,
    required this.labelBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<T>(
        showSelectedIcon: false,
        segments: values
            .map((value) => ButtonSegment(
                  value: value,
                  label: Text(
                    labelBuilder(value),
                    style: const TextStyle(fontSize: 13),
                  ),
                ))
            .toList(),
        selected: {selected},
        onSelectionChanged: (Set<T> newSelection) {
          onSelectionChanged(newSelection.first);
        },
        style: ButtonStyle(
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(UIConstants.borderRadiusSmall),
            ),
          ),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: const VisualDensity(horizontal: 0, vertical: -2),
        ),
      ),
    );
  }
}
