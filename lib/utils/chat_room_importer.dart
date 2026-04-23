import 'dart:convert';
import 'package:universal_io/io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../l10n/app_localizations.dart';
import '../models/character/character.dart';
import '../models/chat/chat_message.dart';
import '../models/chat/chat_message_metadata.dart';
import '../models/chat/chat_room.dart';
import 'chat_room_exporter.dart';
import 'common_dialog.dart';

/// Imports a chat room JSON file (produced by [ChatRoomExporter]) into a
/// target character.
class ChatRoomImporter {
  ChatRoomImporter._();

  /// Imports into a specific character. Returns true on success.
  static Future<bool> importToCharacter(
    BuildContext context,
    DatabaseHelper db,
    int characterId,
  ) async {
    return _import(context, db, characterId);
  }

  /// Prompts the user to pick a character first, then imports. Returns true on
  /// success.
  static Future<bool> importWithCharacterPicker(
    BuildContext context,
    DatabaseHelper db,
  ) async {
    final characters = await db.readAllCharacters();
    final selectable = characters.where((c) => !c.isDraft).toList();
    if (!context.mounted) return false;

    if (selectable.isEmpty) {
      CommonDialog.showSnackBar(
        context: context,
        message: AppLocalizations.of(context).chatRoomImportNoCharacters,
      );
      return false;
    }

    final selected = await _showCharacterPicker(context, selectable);
    if (selected == null || !context.mounted) return false;
    return _import(context, db, selected.id!);
  }

  static Future<Character?> _showCharacterPicker(
    BuildContext context,
    List<Character> characters,
  ) async {
    final l10n = AppLocalizations.of(context);
    return showDialog<Character>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.chatRoomImportSelectCharacter),
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: characters.length,
            itemBuilder: (_, i) => ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(characters[i].name),
              onTap: () => Navigator.pop(ctx, characters[i]),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.commonCancel),
          ),
        ],
      ),
    );
  }

  static Future<bool> _import(
    BuildContext context,
    DatabaseHelper db,
    int characterId,
  ) async {
    bool loadingShown = false;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null || result.files.isEmpty) return false;

      if (!context.mounted) return false;
      final l10n = AppLocalizations.of(context);
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const PopScope(
          canPop: false,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
      loadingShown = true;

      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();
      final data = json.decode(jsonString) as Map<String, dynamic>;

      if (data['format'] != ChatRoomExporter.formatVersion) {
        throw const FormatException('Unsupported file format');
      }

      final roomMap = Map<String, dynamic>.from(data['chatRoom'] as Map)
        ..['character_id'] = characterId
        ..['id'] = null
        ..remove('selected_chat_prompt_id')
        ..remove('selected_persona_id')
        ..remove('selected_start_scenario_id')
        ..remove('selected_condition_preset_id');

      final chatRoom = ChatRoom.fromMap(roomMap);
      final chatRoomId = await db.createChatRoom(chatRoom);

      final messagesList = data['messages'] as List? ?? const [];
      for (final raw in messagesList) {
        final msgMap = Map<String, dynamic>.from(raw as Map);
        final metadataMap = msgMap.remove('metadata');
        msgMap['chat_room_id'] = chatRoomId;
        msgMap['id'] = null;

        final message = ChatMessage.fromMap(msgMap);
        final messageId = await db.createChatMessage(message);

        if (metadataMap is Map) {
          final mdMap = Map<String, dynamic>.from(metadataMap)
            ..['chat_room_id'] = chatRoomId
            ..['chat_message_id'] = messageId
            ..['id'] = null;
          await db.createChatMessageMetadata(ChatMessageMetadata.fromMap(mdMap));
        }
      }

      if (context.mounted) {
        Navigator.pop(context);
        loadingShown = false;
        CommonDialog.showSnackBar(
          context: context,
          message: l10n.chatRoomImportSuccess,
        );
      }
      return true;
    } catch (e) {
      if (context.mounted) {
        if (loadingShown) Navigator.pop(context);
        CommonDialog.showSnackBar(
          context: context,
          message: AppLocalizations.of(context)
              .chatRoomImportFailed(e.toString()),
        );
      }
      return false;
    }
  }
}
