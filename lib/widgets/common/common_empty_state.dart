import 'package:flutter/material.dart';

/// 빈 상태를 표시하는 위젯
class CommonEmptyState extends StatelessWidget {
  /// 아이콘 (선택사항)
  final IconData? icon;

  /// 메시지 텍스트
  final String message;

  /// 아이콘 크기 (기본 64)
  final double iconSize;

  /// 아이콘 투명도 (기본 0.3)
  final double iconOpacity;

  /// 텍스트 투명도 (기본 0.5)
  final double textOpacity;

  const CommonEmptyState({
    super.key,
    this.icon,
    required this.message,
    this.iconSize = 64,
    this.iconOpacity = 0.3,
    this.textOpacity = 0.5,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: iconSize,
              color: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.color
                  ?.withValues(alpha: iconOpacity),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.color
                      ?.withValues(alpha: textOpacity),
                ),
          ),
        ],
      ),
    );
  }
}
