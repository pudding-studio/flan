import 'package:flutter/material.dart';

enum CommonButtonSize {
  small,
  medium,
}

class CommonButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData? icon;
  final String label;
  final _CommonButtonType _type;
  final CommonButtonSize size;
  final double? iconSize;

  const CommonButton._({
    required this.onPressed,
    required this.icon,
    required this.label,
    required _CommonButtonType type,
    this.size = CommonButtonSize.medium,
    this.iconSize,
  }) : _type = type;

  factory CommonButton.filled({
    required VoidCallback? onPressed,
    IconData? icon,
    required String label,
    CommonButtonSize size = CommonButtonSize.medium,
    double? iconSize,
  }) {
    return CommonButton._(
      onPressed: onPressed,
      icon: icon,
      label: label,
      type: _CommonButtonType.filled,
      size: size,
      iconSize: iconSize,
    );
  }

  factory CommonButton.outlined({
    required VoidCallback? onPressed,
    IconData? icon,
    required String label,
    CommonButtonSize size = CommonButtonSize.medium,
    double? iconSize,
  }) {
    return CommonButton._(
      onPressed: onPressed,
      icon: icon,
      label: label,
      type: _CommonButtonType.outlined,
      size: size,
      iconSize: iconSize,
    );
  }

  static const EdgeInsets _mediumPadding = EdgeInsets.symmetric(vertical: 12);
  static const EdgeInsets _smallPadding = EdgeInsets.symmetric(vertical: 8);

  EdgeInsets get _buttonPadding {
    switch (size) {
      case CommonButtonSize.small:
        return _smallPadding;
      case CommonButtonSize.medium:
        return _mediumPadding;
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_type) {
      case _CommonButtonType.filled:
        if (icon != null) {
          return FilledButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, size: iconSize),
            label: Text(label),
            style: FilledButton.styleFrom(padding: _buttonPadding),
          );
        }
        return FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(padding: _buttonPadding),
          child: Text(label),
        );

      case _CommonButtonType.outlined:
        if (icon != null) {
          return OutlinedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, size: iconSize),
            label: Text(label),
            style: OutlinedButton.styleFrom(padding: _buttonPadding),
          );
        }
        return OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(padding: _buttonPadding),
          child: Text(label),
        );
    }
  }
}

enum _CommonButtonType {
  filled,
  outlined,
}
