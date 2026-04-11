import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';

/// Floating overlay shown above the message list:
///   - When [hasNewMessage] is true, a "new messages" chip pinned to the
///     bottom that jumps to the latest message on tap.
///   - Otherwise, when [showScrollButtons] is true, two small FABs in the
///     bottom-right that scroll to the top/bottom of the conversation.
///
/// Renders nothing when neither flag is set, so callers can drop it into a
/// [Stack] unconditionally.
class ChatRoomScrollButtons extends StatelessWidget {
  final bool hasNewMessage;
  final bool showScrollButtons;
  final VoidCallback onJumpToLatest;
  final VoidCallback onScrollToTop;
  final VoidCallback onScrollToBottom;

  const ChatRoomScrollButtons({
    super.key,
    required this.hasNewMessage,
    required this.showScrollButtons,
    required this.onJumpToLatest,
    required this.onScrollToTop,
    required this.onScrollToBottom,
  });

  @override
  Widget build(BuildContext context) {
    if (hasNewMessage) {
      final l10n = AppLocalizations.of(context);
      return Positioned.fill(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: onJumpToLatest,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.chatRoomNewMessages,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.keyboard_arrow_down,
                      color: Theme.of(context).colorScheme.onPrimary,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (!showScrollButtons) {
      return const SizedBox.shrink();
    }

    return Positioned(
      right: 12,
      bottom: 12,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ScrollFab(icon: Icons.keyboard_arrow_up, onPressed: onScrollToTop),
          const SizedBox(height: 8),
          _ScrollFab(icon: Icons.keyboard_arrow_down, onPressed: onScrollToBottom),
        ],
      ),
    );
  }
}

class _ScrollFab extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _ScrollFab({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: FloatingActionButton.small(
        heroTag: null,
        onPressed: onPressed,
        elevation: 2,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        shape: const CircleBorder(),
        child: Icon(icon, size: 20),
      ),
    );
  }
}
