import 'package:flutter/material.dart';

class CommonSettingRow extends StatelessWidget {
  final String label;
  final Widget child;

  const CommonSettingRow({
    super.key,
    required this.label,
    required this.child,
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
                fontSize: 14,
              ),
        ),
        const SizedBox(height: 4),
        child,
      ],
    );
  }
}
