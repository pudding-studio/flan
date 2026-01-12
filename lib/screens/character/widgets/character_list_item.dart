import 'package:flutter/material.dart';
import 'dart:io';
import 'tag_chip.dart';

class CharacterListItem extends StatelessWidget {
  final String title;
  final String description;
  final List<String> tags;
  final String? imageUrl;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final bool isEditMode;
  final bool isSelected;

  const CharacterListItem({
    super.key,
    required this.title,
    required this.description,
    required this.tags,
    this.imageUrl,
    this.onTap,
    this.onDelete,
    this.isEditMode = false,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final imageSize = (screenWidth * 0.45) * 0.6;

    return GestureDetector(
      onTap: onTap,
      onLongPress: isEditMode ? null : onDelete,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20.0),
                child: Container(
                  width: imageSize,
                  height: imageSize,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    border: isEditMode && isSelected
                      ? Border.all(
                          color: Theme.of(context).colorScheme.primary,
                          width: 3,
                        )
                      : null,
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: imageUrl != null && imageUrl!.isNotEmpty
                      ? Image.file(
                          File(imageUrl!),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.person,
                            size: imageSize * 0.4,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        )
                      : Icon(
                          Icons.person,
                          size: imageSize * 0.4,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                ),
              ),
              if (isEditMode)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.check,
                      size: 20,
                      color: isSelected ? Colors.white : Colors.transparent,
                    ),
                  ),
                ),
            ],
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
                          color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
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
