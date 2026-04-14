import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/chat/chat_room.dart';
import '../../../models/chat/chat_room_summary.dart';
import '../../../utils/date_formatter.dart';
import '../../../utils/metadata_parser.dart';
import '../../../widgets/chat/chat_room_card.dart';
import '../../../widgets/chat/chat_room_context_menu.dart';
import '../../../widgets/common/common_button.dart';

class CharacterChatTab extends StatelessWidget {
  final List<ChatRoomSummary> chatRooms;
  final bool hasMoreChats;
  final ScrollController scrollController;
  final VoidCallback onNewChat;
  final void Function(ChatRoomSummary) onChatRoomTap;
  final void Function(ChatRoom) onRename;
  final void Function(ChatRoom) onDelete;

  const CharacterChatTab({
    super.key,
    required this.chatRooms,
    required this.hasMoreChats,
    required this.scrollController,
    required this.onNewChat,
    required this.onChatRoomTap,
    required this.onRename,
    required this.onDelete,
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
              return GestureDetector(
                onTap: () => onChatRoomTap(data),
                onLongPress: () {
                  showDialog(
                    context: context,
                    builder: (_) => ChatRoomContextMenu(
                      chatRoomName: data.chatRoom.name,
                      onRename: () => onRename(data.chatRoom),
                      onDelete: () => onDelete(data.chatRoom),
                    ),
                  );
                },
                child: ChatRoomCard(
                  title: data.chatRoom.name,
                  lastMessage: data.lastMessage != null
                      ? MetadataParser.removeMetadataTags(data.lastMessage!.content)
                      : l10n.chatNoMessages,
                  date: DateFormatter.formatRelativeDate(data.chatRoom.updatedAt, l10n),
                  imageData: data.coverImage?.imageData,
                  messageCount: data.messageCount,
                  tokenCount: data.tokenCount,
                  isEditMode: false,
                  isSelected: false,
                ),
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
