import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/community/community_comment.dart';
import '../../../models/community/community_post.dart';
import '../../../utils/date_formatter.dart';

class CommunityPostCard extends StatelessWidget {
  final CommunityPost post;
  final bool isNew;
  final Set<int> newCommentIds;
  final VoidCallback onToggleFavorite;
  final VoidCallback onDelete;
  final VoidCallback onWriteComment;
  final void Function(CommunityComment) onDeleteComment;

  const CommunityPostCard({
    super.key,
    required this.post,
    required this.isNew,
    required this.newCommentIds,
    required this.onToggleFavorite,
    required this.onDelete,
    required this.onWriteComment,
    required this.onDeleteComment,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Card(
        color: isNew
            ? Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.1)
            : Theme.of(context).colorScheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isNew
                ? Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.5)
                : Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 8),
              Text(
                post.title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                post.content,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              if (post.comments.isNotEmpty) ...[
                const SizedBox(height: 10),
                Divider(
                  height: 1,
                  color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4),
                ),
                const SizedBox(height: 8),
                ...post.comments.map((c) => _buildComment(context, c)),
              ],
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: Icon(Icons.comment_outlined,
                      size: 14,
                      color: Theme.of(context).colorScheme.secondary),
                  label: Text(
                    l10n.communityCommentLabel,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: onWriteComment,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final secondaryContainer = Theme.of(context).colorScheme.secondaryContainer;
    final onSecondaryContainer = Theme.of(context).colorScheme.onSecondaryContainer;

    return Row(
      children: [
        InkWell(
          onTap: onToggleFavorite,
          borderRadius: BorderRadius.circular(4),
          child: Icon(
            post.isFavorited ? Icons.star : Icons.star_border,
            size: 18,
            color: post.favoriteUsed
                ? Theme.of(context).colorScheme.tertiary
                : post.isFavorited
                    ? Colors.amber
                    : Theme.of(context).colorScheme.outline,
          ),
        ),
        const SizedBox(width: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: secondaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            post.author,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: onSecondaryContainer,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        const Spacer(),
        Text(
          DateFormatter.formatDateTime(post.time),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: onDelete,
          borderRadius: BorderRadius.circular(4),
          child: Icon(
            Icons.delete_outline,
            size: 18,
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      ],
    );
  }

  Widget _buildComment(BuildContext context, CommunityComment comment) {
    final isNewComment = comment.id != null && newCommentIds.contains(comment.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: isNewComment ? const EdgeInsets.all(6) : EdgeInsets.zero,
      decoration: isNewComment
          ? BoxDecoration(
              color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            )
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.subdirectory_arrow_right,
            size: 14,
            color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.author,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      DateFormatter.formatDateTime(comment.time),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () => onDeleteComment(comment),
                      borderRadius: BorderRadius.circular(4),
                      child: Icon(
                        Icons.delete_outline,
                        size: 14,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ],
                ),
                Text(comment.content, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
