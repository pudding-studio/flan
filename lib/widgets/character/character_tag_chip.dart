import 'package:flutter/material.dart';

class CharacterTagChip extends StatelessWidget {
  final String label;

  const CharacterTagChip({
    super.key,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 10,
              color: Theme.of(context).colorScheme.onSecondaryContainer,
            ),
      ),
    );
  }
}
