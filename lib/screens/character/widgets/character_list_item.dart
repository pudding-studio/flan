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
  final VoidCallback? onEdit;
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
    this.onEdit,
    this.isEditMode = false,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final imageSize = 70.0;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
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
                      SizedBox(
                        height: 24,
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
              ),
            ],
          ),
          if (isEditMode)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                width: 24,
                height: 24,
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
                  size: 16,
                  color: isSelected ? Colors.white : Colors.transparent,
                ),
              ),
            ),
          if (!isEditMode)
            Positioned(
              top: -8,
              right: -8,
              child: PopupMenuButton<String>(
                icon: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.more_vert,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                offset: const Offset(-8, 36),
                itemBuilder: (context) => [
                  PopupMenuItem<String>(
                    value: 'edit',
                    onTap: onEdit,
                    child: const Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 20),
                        SizedBox(width: 12),
                        Text('수정'),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'delete',
                    onTap: onDelete,
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 20, color: Theme.of(context).colorScheme.error),
                        const SizedBox(width: 12),
                        Text('삭제', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
