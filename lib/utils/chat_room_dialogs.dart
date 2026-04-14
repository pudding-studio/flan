import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../l10n/app_localizations.dart';
import '../models/chat/chat_room.dart';
import '../widgets/common/common_edit_text.dart';
import 'common_dialog.dart';

class ChatRoomDialogs {
  static Future<void> showRename({
    required BuildContext context,
    required ChatRoom chatRoom,
    required DatabaseHelper db,
    required VoidCallback onSuccess,
  }) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(text: chatRoom.name);

    try {
      final result = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.chatRoomRenameTitle),
          content: CommonEditText(
            controller: controller,
            hintText: l10n.chatRoomRenameHint,
            size: CommonEditTextSize.medium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: Text(l10n.commonCancel),
            ),
            TextButton(
              onPressed: () {
                final newName = controller.text.trim();
                if (newName.isEmpty) {
                  Navigator.pop(context, null);
                } else {
                  Navigator.pop(context, newName);
                }
              },
              child: Text(l10n.commonConfirm),
            ),
          ],
        ),
      );

      if (result != null && result.isNotEmpty && result != chatRoom.name) {
        final updatedChatRoom = chatRoom.copyWith(
          name: result,
        );
        await db.updateChatRoom(updatedChatRoom);
        onSuccess();
      }
    } catch (e) {
      debugPrint('Error renaming chat room: $e');
      if (!context.mounted) return;
      CommonDialog.showSnackBar(
        context: context,
        message: l10n.chatRoomRenameFailed,
      );
    } finally {
      controller.dispose();
    }
  }

  static Future<void> showDelete({
    required BuildContext context,
    required ChatRoom chatRoom,
    required DatabaseHelper db,
    required VoidCallback onSuccess,
  }) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await CommonDialog.showConfirmation(
      context: context,
      title: l10n.chatRoomDeleteTitle,
      content: l10n.chatRoomDeleteOneContent(chatRoom.name),
      confirmText: l10n.commonDelete,
      isDestructive: true,
    );

    if (confirmed == true) {
      try {
        await db.deleteChatRoom(chatRoom.id!);
        onSuccess();
        if (!context.mounted) return;
        CommonDialog.showSnackBar(
          context: context,
          message: l10n.chatRoomDeleted,
        );
      } catch (e) {
        debugPrint('Error deleting chat room: $e');
        if (!context.mounted) return;
        CommonDialog.showSnackBar(
          context: context,
          message: l10n.chatRoomDeleteFailed,
        );
      }
    }
  }
}
