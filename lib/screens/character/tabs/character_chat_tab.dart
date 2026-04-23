import 'package:flutter/material.dart';
import '../../../database/database_helper.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/chat/chat_room_summary.dart';
import '../../../widgets/chat/chat_room_list_entry.dart';
import '../../../widgets/common/common_button.dart';

class CharacterChatTab extends StatelessWidget {
  final List<ChatRoomSummary> chatRooms;
  final bool hasMoreChats;
  final ScrollController scrollController;
  final DatabaseHelper db;
  final VoidCallback onChatRoomsChanged;
  final VoidCallback onNewChat;
  final void Function(ChatRoomSummary) onChatRoomTap;

  const CharacterChatTab({
    super.key,
    required this.chatRooms,
    required this.hasMoreChats,
    required this.scrollController,
    required this.db,
    required this.onChatRoomsChanged,
    required this.onNewChat,
    required this.onChatRoomTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (chatRooms.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 80,
              color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.characterViewNoChats,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.characterViewStartNewChat,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth * 0.05;

    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            controller: scrollController,
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16.0),
            itemCount: chatRooms.length + (hasMoreChats ? 1 : 0),
            separatorBuilder: (context, index) => const SizedBox(height: 20.0),
            itemBuilder: (context, index) {
              if (index >= chatRooms.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              final data = chatRooms[index];
              return ChatRoomListEntry(
                data: data,
                db: db,
                onChanged: onChatRoomsChanged,
                onTap: () => onChatRoomTap(data),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: CommonButton.filled(
              onPressed: onNewChat,
              icon: Icons.chat_bubble_outline,
              label: l10n.characterViewNewChat,
            ),
          ),
        ),
      ],
    );
  }
}
