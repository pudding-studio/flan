import 'package:flutter/material.dart';

class CustomIndicatorShape extends ShapeBorder {
  final double width;
  final double height;
  final BorderRadius borderRadius;
  final double offsetY;

  const CustomIndicatorShape({
    this.width = 64,
    this.height = 12,
    this.borderRadius = const BorderRadius.all(Radius.circular(15)),
    this.offsetY = 0,
  });

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return getOuterPath(rect, textDirection: textDirection);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final customRect = Rect.fromCenter(
      center: Offset(rect.center.dx, rect.center.dy + offsetY),
      width: width,
      height: height,
    );
    return Path()..addRRect(borderRadius.toRRect(customRect));
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}

  @override
  ShapeBorder scale(double t) {
    return CustomIndicatorShape(
      width: width * t,
      height: height * t,
      borderRadius: borderRadius * t,
      offsetY: offsetY * t,
    );
  }
}
