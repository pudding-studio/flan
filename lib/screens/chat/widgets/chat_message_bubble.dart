import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/chat/chat_message.dart';
import '../../../models/chat/chat_message_metadata.dart';
import '../../../providers/viewer_settings_provider.dart';
import '../../../utils/metadata_parser.dart';
import '../../../widgets/common/common_character_card.dart';
import '../../../widgets/common/common_edit_text.dart';
import '../../../widgets/common/markdown_text.dart';

/// Single message row in the chat room conversation list.
///
/// Renders the (optional) date/time/location header, the message body —
/// either a markdown view or an inline edit field — character cards parsed
/// from the body, the per-message action toolbar, and the divider beneath.
///
/// All callbacks are required so the host owns the actual mutations
/// (DB writes, regeneration, branching, etc).
class ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final int index;
  final bool isLastMessage;

  /// Pre-processed text shown by the markdown view (image rewrites,
  /// regex rules, metadata tags stripped). The widget does not transform
  /// [message.content] itself, so the host can apply chat-room-specific
  /// rules consistently with search.
  final String displayContent;

  final ChatMessageMetadata? metadata;

  final bool isEditing;
  final TextEditingController? editController;

  final bool isSummaryThreshold;
  final bool isSummarized;

  final bool isSearchMatch;
  final bool isCurrentSearchMatch;
  final int currentOccurrenceInMsg;
  final String? searchQuery;
  final GlobalKey? searchHighlightKey;

  final VoidCallback onTogglePin;
  final VoidCallback onShowUsage;
  final VoidCallback onCancelEdit;
  final VoidCallback onSaveEdit;
  final VoidCallback onStartEdit;
  final VoidCallback onCreateBranch;
  final VoidCallback onDelete;
  final VoidCallback onResendOrRegenerate;

  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.index,
    required this.isLastMessage,
    required this.displayContent,
    required this.metadata,
    required this.isEditing,
    required this.editController,
    required this.isSummaryThreshold,
    required this.isSummarized,
    required this.isSearchMatch,
    required this.isCurrentSearchMatch,
    required this.currentOccurrenceInMsg,
    required this.searchQuery,
    required this.searchHighlightKey,
    required this.onTogglePin,
    required this.onShowUsage,
    required this.onCancelEdit,
    required this.onSaveEdit,
    required this.onStartEdit,
    required this.onCreateBranch,
    required this.onDelete,
    required this.onResendOrRegenerate,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;
    final hasUsageMetadata = !isUser && message.usageMetadata != null;
    final hasMetadata = !isUser &&
        metadata != null &&
        (metadata!.date != null ||
            metadata!.time != null ||
            metadata!.location != null);
    final viewer = context.watch<ViewerSettingsProvider>();
    final theme = Theme.of(context);
    final characterTags = MetadataParser.parseCharacterTags(message.content);

    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: 16 + viewer.paragraphWidth,
            vertical: 0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasMetadata)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: ChatMessageMetadataHeader(metadata: metadata!),
                ),
              if (isEditing)
                CommonEditText(
                  controller: editController,
                  size: CommonEditTextSize.small,
                  maxLines: null,
                )
              else ...[
                MarkdownText(
                  text: displayContent,
                  baseStyle: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: viewer.fontSize,
                    height: viewer.lineHeight,
                  ),
                  textAlign: viewer.textAlign,
                  paragraphSpacing: viewer.paragraphSpacing,
                  highlightQuery: isSearchMatch ? searchQuery : null,
                  highlightColor: isSearchMatch
                      ? theme.colorScheme.tertiary.withValues(alpha: 0.35)
                      : null,
                  currentHighlightColor: isCurrentSearchMatch
                      ? theme.colorScheme.tertiary.withValues(alpha: 0.7)
                      : null,
                  currentOccurrence: currentOccurrenceInMsg,
                  highlightKey: isCurrentSearchMatch ? searchHighlightKey : null,
                ),
                if (characterTags.isNotEmpty) const SizedBox(height: 4),
                ...characterTags.map(
                  (tag) => CommonCharacterCard(tag: tag, fontSize: viewer.fontSize),
                ),
              ],
              const SizedBox(height: 0),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (hasUsageMetadata)
                    _CompactIconButton(
                      icon: Icons.bar_chart,
                      onPressed: onShowUsage,
                    ),
                  if (hasMetadata)
                    _CompactIconButton(
                      icon: metadata!.isPinned
                          ? Icons.push_pin
                          : Icons.push_pin_outlined,
                      color: metadata!.isPinned
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.4),
                      onPressed: onTogglePin,
                    ),
                  const Spacer(),
                  if (isEditing) ...[
                    _CompactIconButton(icon: Icons.close, onPressed: onCancelEdit),
                    _CompactIconButton(icon: Icons.check, onPressed: onSaveEdit),
                  ] else ...[
                    _CompactIconButton(
                      icon: Icons.copy_outlined,
                      onPressed: () => Clipboard.setData(
                        ClipboardData(text: message.content),
                      ),
                    ),
                    _CompactIconButton(
                      icon: Icons.edit_outlined,
                      onPressed: onStartEdit,
                    ),
                    _CompactIconButton(
                      icon: Icons.call_split,
                      onPressed: onCreateBranch,
                    ),
                    _CompactIconButton(
                      icon: Icons.delete_outline,
                      onPressed: onDelete,
                    ),
                    if (isLastMessage)
                      _CompactIconButton(
                        icon: Icons.refresh,
                        onPressed: onResendOrRegenerate,
                      ),
                  ],
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 0, bottom: 8),
          child: Divider(
            height: 1,
            thickness: isSummaryThreshold ? 1.5 : 1,
            color: isSummaryThreshold
                ? theme.colorScheme.primary
                : isSummarized
                    ? theme.colorScheme.secondary
                    : theme.colorScheme.outlineVariant,
          ),
        ),
      ],
    );
  }
}

/// Date / time / location label rendered above an AI message that has
/// metadata attached. Splits a comma-separated location into main /
/// secondary lines so the right-hand column doesn't overflow.
class ChatMessageMetadataHeader extends StatelessWidget {
  final ChatMessageMetadata metadata;

  const ChatMessageMetadataHeader({super.key, required this.metadata});

  static List<String> _localizedDayNames(AppLocalizations l10n) => [
        l10n.chatRoomDayMon,
        l10n.chatRoomDayTue,
        l10n.chatRoomDayWed,
        l10n.chatRoomDayThu,
        l10n.chatRoomDayFri,
        l10n.chatRoomDaySat,
        l10n.chatRoomDaySun,
      ];

  static String _formatDateTime(
    AppLocalizations l10n,
    String? date,
    String? time,
  ) {
    final dayNames = _localizedDayNames(l10n);
    final parts = <String>[];
    if (date != null) {
      final segments = date.split('.');
      if (segments.length == 3) {
        final year = int.tryParse(segments[0]);
        final month = int.tryParse(segments[1]);
        final day = int.tryParse(segments[2]);
        if (year != null && month != null && day != null) {
          final dt = DateTime(year, month, day);
          final dayName = dayNames[dt.weekday - 1];
          parts.add('$date($dayName)');
        } else {
          parts.add(date);
        }
      } else {
        parts.add(date);
      }
    }
    if (time != null) {
      final timeParts = time.split(':');
      if (timeParts.length == 2) {
        final hour = int.tryParse(timeParts[0]);
        if (hour != null) {
          final period =
              (hour >= 6 && hour < 18) ? l10n.chatRoomDay : l10n.chatRoomNight;
          parts.add('$time($period)');
        } else {
          parts.add(time);
        }
      } else {
        parts.add(time);
      }
    }
    return parts.join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final metaStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    final hasDateTime = metadata.date != null || metadata.time != null;
    final location = metadata.location;

    String? locationMain;
    String? locationSub;
    if (location != null) {
      final commaIndex = location.indexOf(',');
      if (commaIndex != -1) {
        locationMain = location.substring(0, commaIndex).trim();
        locationSub = location.substring(commaIndex + 1).trim();
      } else {
        locationMain = location;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (hasDateTime)
              Text(
                _formatDateTime(l10n, metadata.date, metadata.time),
                style: metaStyle,
              )
            else
              const SizedBox.shrink(),
            if (locationMain != null)
              Flexible(
                child: Text(
                  locationMain,
                  style: metaStyle,
                  textAlign: TextAlign.end,
                ),
              ),
          ],
        ),
        if (locationSub != null)
          Align(
            alignment: Alignment.centerRight,
            child: Text(locationSub, style: metaStyle),
          ),
      ],
    );
  }
}

class _CompactIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;

  const _CompactIconButton({
    required this.icon,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 18, color: color),
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
    );
  }
}
