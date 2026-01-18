import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'tag_chip.dart';

class CharacterCard extends StatelessWidget {
  final String title;
  final String description;
  final List<String> tags;
  final Uint8List? imageData;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final VoidCallback? onExport;
  final bool isEditMode;
  final bool isSelected;

  const CharacterCard({
    super.key,
    required this.title,
    required this.description,
    required this.tags,
    this.imageData,
    this.onTap,
    this.onDelete,
    this.onEdit,
    this.onExport,
    this.isEditMode = false,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth;

        return GestureDetector(
          onTap: onTap,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20.0),
                      child: Container(
                        width: cardWidth,
                        height: cardWidth,
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
                        child: imageData != null
                            ? Image.memory(
                                imageData!,
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
                  ],
                ),
              if (isEditMode)
                Positioned(
                  top: 8,
                  right: 8,
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
                  top: -4,
                  right: -4,
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
                        value: 'export',
                        onTap: onExport,
                        child: const Row(
                          children: [
                            Icon(Icons.upload_outlined, size: 20),
                            SizedBox(width: 12),
                            Text('내보내기'),
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
      },
    );
  }
}
