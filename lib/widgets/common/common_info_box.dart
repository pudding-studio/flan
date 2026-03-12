import 'package:flutter/material.dart';
import '../../constants/ui_constants.dart';

/// 정보/안내 메시지를 표시하는 박스
class CommonInfoBox extends StatelessWidget {
  /// 메시지 텍스트
  final String message;

  /// 아이콘 (기본 info_outline)
  final IconData icon;

  /// 아이콘 색상 (null이면 primary)
  final Color? iconColor;

  const CommonInfoBox({
    super.key,
    required this.message,
    this.icon = Icons.info_outline,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(UIConstants.spacing16),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: UIConstants.opacityMedium),
        borderRadius: BorderRadius.circular(UIConstants.borderRadiusMedium),
        border: Border.all(
          color: Theme.of(context)
              .colorScheme
              .outline
              .withValues(alpha: UIConstants.opacityLow),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: UIConstants.iconSizeLarge,
            color: iconColor ?? Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: UIConstants.spacing12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
