import 'package:flutter/material.dart';

/// 라벨 + 위젯 + 하단 간격으로 구성된 필드 섹션
class CommonFieldSection extends StatelessWidget {
  /// 필드 라벨
  final String label;

  /// 필드 내용 위젯
  final Widget child;

  /// 하단 간격 (기본 12.0)
  final double bottomSpacing;

  /// 라벨과 위젯 사이 간격 (기본 2.0)
  final double labelSpacing;

  const CommonFieldSection({
    super.key,
    required this.label,
    required this.child,
    this.bottomSpacing = 12.0,
    this.labelSpacing = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        SizedBox(height: labelSpacing),
        child,
        if (bottomSpacing > 0) SizedBox(height: bottomSpacing),
      ],
    );
  }
}
