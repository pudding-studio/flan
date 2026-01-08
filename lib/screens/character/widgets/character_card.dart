import 'package:flutter/material.dart';
import 'dart:io';
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
                  child: imageUrl != null && imageUrl!.isNotEmpty
                      ? Image.file(
                          File(imageUrl!),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.person,
                            size: cardWidth * 0.4,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        )
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
                    SizedBox(
                      height: 44, // 2줄 높이: (TagChip 높이 ~20px * 2) + (runSpacing 4px)
                      child: ClipRect(
                        child: Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: tags.map((tag) => TagChip(label: tag)).toList(),
                        ),
                      ),
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
