import 'package:flutter/material.dart';
import 'tag_chip.dart';

class CharacterListItem extends StatelessWidget {
  final String title;
  final String description;
  final List<String> tags;
  final String? imageUrl;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const CharacterListItem({
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
    final screenWidth = MediaQuery.of(context).size.width;
    final imageSize = (screenWidth * 0.45) * 0.6;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onDelete,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20.0),
            child: Container(
              width: imageSize,
              height: imageSize,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: imageUrl != null
                  ? Image.network(imageUrl!, fit: BoxFit.cover)
                  : Icon(
                      Icons.person,
                      size: imageSize * 0.4,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
          ),
        ],
      ),
    );
  }
}
