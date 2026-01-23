import 'package:flutter/material.dart';

/// AppBar의 액션 버튼들에 공통으로 적용되는 위젯
/// Transform.translate를 사용하여 일관된 여백을 제공합니다.
class AppBarIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double? offsetX;

  const AppBarIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.offsetX,
  });

  @override
  Widget build(BuildContext context) {
    // 편집 버튼은 30.0, 삭제 버튼은 16.0, 나머지는 20.0
    final double effectiveOffsetX = offsetX ??
      (icon == Icons.edit_outlined ? 14.0 :
       icon == Icons.delete_outline ? 0.0 : 4.0);

    return Transform.translate(
      offset: Offset(effectiveOffsetX, 0),
      child: IconButton(
        icon: Icon(icon),
        onPressed: onPressed,
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        constraints: const BoxConstraints(),
      ),
    );
  }
}

/// AppBar의 텍스트 버튼을 위한 공통 위젯
class AppBarTextButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final double fontSize;
  final FontWeight fontWeight;

  const AppBarTextButton({
    super.key,
    required this.text,
    this.onPressed,
    this.fontSize = 6,
    this.fontWeight = FontWeight.w600,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(4.0, 0),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
          ),
        ),
      ),
    );
  }
}

/// AppBar의 PopupMenuButton을 위한 공통 위젯
class AppBarPopupMenuButton<T> extends StatelessWidget {
  final IconData icon;
  final String? tooltip;
  final double offsetX;
  final void Function(T)? onSelected;
  final List<PopupMenuEntry<T>> Function(BuildContext) itemBuilder;
  final ShapeBorder? shape;

  const AppBarPopupMenuButton({
    super.key,
    this.icon = Icons.more_vert,
    this.tooltip,
    this.offsetX = 4.0,
    this.onSelected,
    required this.itemBuilder,
    this.shape,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(offsetX, 0),
      child: PopupMenuButton<T>(
        icon: Icon(icon),
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        shape: shape ?? RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        onSelected: onSelected,
        itemBuilder: itemBuilder,
      ),
    );
  }
}
