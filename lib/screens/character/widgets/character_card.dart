import 'package:flutter/material.dart';
import 'tag_chip.dart';

class CharacterCard extends StatelessWidget {
  final String title;
  final String description;
  final List<String> tags;
  final String? imageUrl;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const CharacterCard({
    super.key,
    required this.title,
    required this.description,
    required this.tags,
    this.imageUrl,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth;

        return GestureDetector(
          onTap: onTap,
          onLongPress: onDelete,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20.0),
                child: Container(
                  width: cardWidth,
                  height: cardWidth,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: imageUrl != null
                      ? Image.network(imageUrl!, fit: BoxFit.cover)
                      : Icon(
                          Icons.person,
                          size: cardWidth * 0.4,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 7.0, vertical: 7.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: tags.map((tag) => TagChip(label: tag)).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
