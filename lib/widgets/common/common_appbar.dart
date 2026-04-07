import 'package:flutter/material.dart';

/// 앱 전체에서 사용하는 공통 AppBar
///
/// 모든 화면에서 일관된 레이아웃과 간격을 제공합니다:
/// - 왼쪽 버튼 (백/클로즈): padding left 16
/// - 버튼-타이틀 간격: 12
/// - 타이틀-오른쪽 버튼 간격: 자동
/// - 오른쪽 버튼-끝 간격: 16
class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Widget? titleWidget; // 커스텀 타이틀 (예: 아바타 + 이름)
  final List<Widget>? actions;
  final bool showBackButton;
  final bool showCloseButton;
  final VoidCallback? onBackPressed; // 뒤로가기 버튼 콜백
  final VoidCallback? onClosePressed; // 닫기 버튼 콜백
  final PreferredSizeWidget? bottom; // TabBar 등을 위한 bottom

  const CommonAppBar({
    super.key,
    required this.title,
    this.titleWidget,
    this.actions,
    this.showBackButton = true,
    this.showCloseButton = false,
    this.onBackPressed,
    this.onClosePressed,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      title: Row(
        children: [
          // 왼쪽 버튼 (백 또는 클로즈)
          if (showBackButton || showCloseButton)
            IconButton(
              icon: Icon(showCloseButton ? Icons.close : Icons.arrow_back),
              onPressed: showCloseButton
                  ? (onClosePressed ?? () => Navigator.pop(context))
                  : (onBackPressed ?? () => Navigator.pop(context)),
              padding: const EdgeInsets.only(left: 16),
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(),
            ),

          // 버튼이 있을 때만 간격 추가
          if (showBackButton || showCloseButton)
            const SizedBox(width: 12),

          // 버튼이 없을 때는 왼쪽 여백 추가
          if (!showBackButton && !showCloseButton)
            const SizedBox(width: 16),

          // 타이틀 (커스텀 위젯 또는 텍스트)
          Expanded(
            child: titleWidget ?? Text(
              title,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // 오른쪽 액션 버튼들
          if (actions != null) ...actions!,
          const SizedBox(width: 16),
        ],
      ),
      bottom: bottom,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
    kToolbarHeight + (bottom?.preferredSize.height ?? 0),
  );
}

/// AppBar의 액션 버튼들에 공통으로 적용되는 위젯
/// Transform.translate를 사용하여 일관된 여백을 제공합니다.
class CommonAppBarIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double? offsetX;

  const CommonAppBarIconButton({
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
class CommonAppBarTextButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final double fontSize;
  final FontWeight fontWeight;

  const CommonAppBarTextButton({
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
class CommonAppBarPopupMenuButton<T> extends StatelessWidget {
  final IconData icon;
  final String? tooltip;
  final double offsetX;
  final void Function(T)? onSelected;
  final List<PopupMenuEntry<T>> Function(BuildContext) itemBuilder;
  final ShapeBorder? shape;

  const CommonAppBarPopupMenuButton({
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
