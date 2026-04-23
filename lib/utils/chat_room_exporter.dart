import 'dart:convert';
import 'package:universal_io/io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../database/database_helper.dart';
import '../l10n/app_localizations.dart';
import '../models/chat/chat_message.dart';
import '../models/chat/chat_message_metadata.dart';
import '../models/chat/chat_room.dart';
import 'common_dialog.dart';

/// Exports a chat room (room settings + messages) as JSON or TXT.
///
/// JSON format is round-trippable via [ChatRoomImporter].
/// TXT is a human-readable transcript only.
class ChatRoomExporter {
  ChatRoomExporter._();

  /// Bumped when the on-disk format changes in an incompatible way.
  static const String formatVersion = 'flan_chatroom_v1';

  static Future<void> export(
    BuildContext context,
    int chatRoomId,
    DatabaseHelper db,
  ) async {
    final format = await _showFormatDialog(context);
    if (format == null || !context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: Center(child: CircularProgressIndicator()),
      ),
    );

    try {
      final chatRoom = await db.readChatRoom(chatRoomId);
      if (chatRoom == null) throw Exception('Chat room not found');
      final character = await db.readCharacter(chatRoom.characterId);
      final messages = await db.readChatMessagesByChatRoom(chatRoomId);
      final metadataList = await db.readChatMessageMetadataByChatRoom(chatRoomId);

      final metadataByMessageId = <int, ChatMessageMetadata>{
        for (final md in metadataList)
          if (md.chatMessageId != 0) md.chatMessageId: md,
      };

      if (!context.mounted) return;

      switch (format) {
        case 'json':
          await _exportJson(context, chatRoom, character?.name, messages, metadataByMessageId);
        case 'txt':
          await _exportTxt(context, chatRoom, character?.name, messages, metadataByMessageId);
      }
    } catch (e) {
      if (context.mounted) {
        CommonDialog.showSnackBar(
          context: context,
          message:
              AppLocalizations.of(context).chatRoomExportFailed(e.toString()),
        );
      }
    } finally {
      if (context.mounted) Navigator.pop(context);
    }
  }

  static Future<String?> _showFormatDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.chatRoomExportFormatTitle),
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('JSON'),
              subtitle: Text(l10n.chatRoomExportJsonSubtitle),
              onTap: () => Navigator.pop(ctx, 'json'),
            ),
            ListTile(
              title: const Text('TXT'),
              subtitle: Text(l10n.chatRoomExportTxtSubtitle),
              onTap: () => Navigator.pop(ctx, 'txt'),
            ),
          ],
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

  static Future<void> _exportJson(
    BuildContext context,
    ChatRoom chatRoom,
    String? characterName,
    List<ChatMessage> messages,
    Map<int, ChatMessageMetadata> metadataByMessageId,
  ) async {
    final roomMap = chatRoom.toMap()
      ..remove('id')
      ..remove('character_id')
      ..remove('selected_chat_prompt_id')
      ..remove('selected_persona_id')
      ..remove('selected_start_scenario_id')
      ..remove('selected_condition_preset_id');

    final messagesJson = messages.map((m) {
      final map = m.toMap()
        ..remove('id')
        ..remove('chat_room_id');
      final md = m.id != null ? metadataByMessageId[m.id!] : null;
      if (md != null) {
        final mdMap = md.toMap()
          ..remove('id')
          ..remove('chat_message_id')
          ..remove('chat_room_id');
        map['metadata'] = mdMap;
      }
      return map;
    }).toList();

    final payload = {
      'format': formatVersion,
      'characterName': characterName,
      'exportedAt': DateTime.now().toIso8601String(),
      'chatRoom': roomMap,
      'messages': messagesJson,
    };

    await _saveTextFile(
      context,
      '${_sanitizeFileName(chatRoom.name)}.json',
      const JsonEncoder.withIndent('  ').convert(payload),
    );
  }

  static Future<void> _exportTxt(
    BuildContext context,
    ChatRoom chatRoom,
    String? characterName,
    List<ChatMessage> messages,
    Map<int, ChatMessageMetadata> metadataByMessageId,
  ) async {
    final buffer = StringBuffer();
    buffer.writeln('# Chat Room: ${chatRoom.name}');
    if (characterName != null) {
      buffer.writeln('# Character: $characterName');
    }
    buffer.writeln('# Exported: ${DateTime.now().toIso8601String()}');
    buffer.writeln();

    for (final m in messages) {
      final role = m.role == MessageRole.user ? 'User' : 'Assistant';
      buffer.writeln('[$role - ${m.createdAt.toIso8601String()}]');
      final md = m.id != null ? metadataByMessageId[m.id!] : null;
      if (md != null) {
        final parts = <String>[];
        if (md.location != null && md.location!.isNotEmpty) parts.add('📍${md.location}');
        if (md.date != null && md.date!.isNotEmpty) parts.add('📅${md.date}');
        if (md.time != null && md.time!.isNotEmpty) parts.add('🕰${md.time}');
        if (parts.isNotEmpty) buffer.writeln('(${parts.join(' · ')})');
      }
      buffer.writeln(m.content);
      buffer.writeln();
    }

    await _saveTextFile(
      context,
      '${_sanitizeFileName(chatRoom.name)}.txt',
      buffer.toString(),
    );
  }

  static String _sanitizeFileName(String name) {
    final sanitized = name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
    return sanitized.isEmpty ? 'chat_room' : sanitized;
  }

  static Future<void> _saveTextFile(
    BuildContext context,
    String fileName,
    String content,
  ) async {
    if (Platform.isAndroid) {
      const platform = MethodChannel('com.flanapp.flan/file_saver');
      final ok = await platform.invokeMethod<bool>('saveToDownloads', {
        'fileName': fileName,
        'content': content,
      });
      if (context.mounted) {
        final l10n = AppLocalizations.of(context);
        CommonDialog.showSnackBar(
          context: context,
          message: ok == true
              ? l10n.chatRoomExportSuccessAndroid(fileName)
              : l10n.chatRoomExportSaveFailed,
        );
      }
    } else if (Platform.isIOS) {
      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/$fileName';
      await File(path).writeAsString(content);
      if (context.mounted) {
        CommonDialog.showSnackBar(
          context: context,
          message: AppLocalizations.of(context).chatRoomExportSuccess(path),
        );
      }
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      final savePath = await FilePicker.platform.saveFile(
        dialogTitle: fileName,
        fileName: fileName,
        lockParentWindow: true,
      );
      if (savePath == null) return;
      await File(savePath).writeAsString(content);
      if (context.mounted) {
        CommonDialog.showSnackBar(
          context: context,
          message: AppLocalizations.of(context).chatRoomExportSuccess(savePath),
        );
      }
    }
  }
}
