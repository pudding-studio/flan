import 'package:flutter/material.dart';

class SettingsPromptListItem extends StatelessWidget {
  final String title;
  final String description;
  final bool isSelected;
  final bool isDefault;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final VoidCallback? onExport;
  final VoidCallback? onCopy;
  final VoidCallback? onRadioTap;

  const SettingsPromptListItem({
    super.key,
    required this.title,
    required this.description,
    this.isSelected = false,
    this.isDefault = false,
    this.onTap,
    this.onDelete,
    this.onEdit,
    this.onExport,
    this.onCopy,
    this.onRadioTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5.0),
      child: Container(
        decoration: isDefault
            ? BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 3,
                  ),
                ),
              )
            : null,
        padding: isDefault ? const EdgeInsets.only(left: 8) : null,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            GestureDetector(
              onTap: onTap,
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: onRadioTap,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(
                        isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                        color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                title,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isDefault) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '기본',
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.color
                                    ?.withValues(alpha: 0.7),
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
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
                  if (!isDefault)
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
                    value: 'copy',
                    onTap: onCopy,
                    child: const Row(
                      children: [
                        Icon(Icons.copy_outlined, size: 20),
                        SizedBox(width: 12),
                        Text('복사하기'),
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
                  if (!isDefault)
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
      ),
    );
  }
}
