import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';

/// AppBar shown while the chat room is in message-search mode.
///
/// Displays a back button, the search field, the current/total match
/// counter, and prev/next navigation. The host owns the controller,
/// focus node, match counts, and all callbacks.
class ChatRoomSearchAppBar extends StatelessWidget implements PreferredSizeWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final int currentIndex;
  final int totalMatches;
  final VoidCallback onClose;
  final ValueChanged<String> onChanged;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const ChatRoomSearchAppBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.currentIndex,
    required this.totalMatches,
    required this.onClose,
    required this.onChanged,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppBar(
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      title: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: onClose,
            padding: const EdgeInsets.only(left: 16),
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              decoration: InputDecoration(
                hintText: l10n.chatRoomMessageSearch,
                border: InputBorder.none,
              ),
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
            ),
          ),
          if (totalMatches > 0)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text(
                '${currentIndex + 1}/$totalMatches',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_up),
            onPressed: onPrev,
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down),
            onPressed: onNext,
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}
