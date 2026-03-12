import 'package:flutter/material.dart';
import 'package:flan/constants/ui_constants.dart';

class CommonExpandableListItem extends StatefulWidget {
  final Widget titleIcon;
  final String title;
  final Widget content;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool initiallyExpanded;
  final String? subtitle;

  const CommonExpandableListItem({
    super.key,
    required this.titleIcon,
    required this.title,
    required this.content,
    this.onEdit,
    this.onDelete,
    this.initiallyExpanded = false,
    this.subtitle,
  });

  @override
  State<CommonExpandableListItem> createState() => _CommonExpandableListItemState();
}

class _CommonExpandableListItemState extends State<CommonExpandableListItem> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: UIConstants.opacityMedium),
        borderRadius: BorderRadius.circular(UIConstants.borderRadiusMedium),
        border: Border.all(
          color: Theme.of(context)
              .colorScheme
              .outline
              .withValues(alpha: UIConstants.opacityLow),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: _toggleExpanded,
            overlayColor: WidgetStateProperty.all(Colors.transparent),
            borderRadius:
                BorderRadius.circular(UIConstants.borderRadiusMedium),
            child: Container(
              padding: UIConstants.containerPadding,
              child: Row(
                children: [
                  widget.titleIcon,
                  const SizedBox(width: UIConstants.spacing12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: Theme.of(context).textTheme.titleSmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (widget.subtitle != null) ...[
                          const SizedBox(height: UIConstants.spacing4),
                          Text(
                            widget.subtitle!,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (widget.onEdit != null)
                    IconButton(
                      icon: const Icon(Icons.edit),
                      iconSize: UIConstants.iconSizeLarge,
                      onPressed: widget.onEdit,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  if (widget.onDelete != null)
                    IconButton(
                      icon: const Icon(Icons.delete),
                      iconSize: UIConstants.iconSizeLarge,
                      onPressed: widget.onDelete,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded) ...[
            Divider(
              height: 1,
              color: Theme.of(context)
                  .colorScheme
                  .outline
                  .withValues(alpha: UIConstants.opacityLow),
            ),
            Padding(
              padding: const EdgeInsets.all(6),
              child: widget.content,
            ),
          ],
        ],
      ),
    );
  }
}
