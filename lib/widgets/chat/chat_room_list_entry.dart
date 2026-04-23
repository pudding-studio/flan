import 'package:flutter/material.dart';
import '../../database/database_helper.dart';
import '../../l10n/app_localizations.dart';
import '../../models/chat/chat_room_summary.dart';
import '../../utils/chat_room_dialogs.dart';
import '../../utils/chat_room_exporter.dart';
import '../../utils/date_formatter.dart';
import '../../utils/metadata_parser.dart';
import 'chat_room_card.dart';
import 'chat_room_context_menu.dart';

/// Shared list entry for chat rooms.
/// Centralizes tap handling and the long-press context menu (rename/delete)
/// so future actions added here apply to every chat-room list automatically.
class ChatRoomListEntry extends StatelessWidget {
  final ChatRoomSummary data;
  final DatabaseHelper db;
  final VoidCallback onChanged;
  final VoidCallback onTap;
  final bool isEditMode;
  final bool isSelected;

  const ChatRoomListEntry({
    super.key,
    required this.data,
    required this.db,
    required this.onChanged,
    required this.onTap,
    this.isEditMode = false,
    this.isSelected = false,
  });

  void _showContextMenu(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => ChatRoomContextMenu(
        chatRoomName: data.chatRoom.name,
        onRename: () => ChatRoomDialogs.showRename(
          context: context,
          chatRoom: data.chatRoom,
          db: db,
          onSuccess: onChanged,
        ),
        onExport: () => ChatRoomExporter.export(
          context,
          data.chatRoom.id!,
          db,
        ),
        onDelete: () => ChatRoomDialogs.showDelete(
          context: context,
          chatRoom: data.chatRoom,
          db: db,
          onSuccess: onChanged,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GestureDetector(
      onTap: onTap,
      onLongPress: isEditMode ? null : () => _showContextMenu(context),
      child: ChatRoomCard(
        title: data.chatRoom.name,
        lastMessage: data.lastMessage != null
            ? MetadataParser.removeMetadataTags(data.lastMessage!.content)
            : l10n.chatNoMessages,
        date: DateFormatter.formatRelativeDate(data.chatRoom.updatedAt, l10n),
        imageData: data.coverImage?.imageData,
        messageCount: data.messageCount,
        tokenCount: data.tokenCount,
        isEditMode: isEditMode,
        isSelected: isSelected,
      ),
    );
  }
}
