import 'dart:convert';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../../database/database_helper.dart';

/// Web-only backup format: a single JSON file dumping all user tables and a
/// whitelisted subset of SharedPreferences. BLOB columns (e.g. character image
/// bytes) are wrapped as `{"__b64__": "..."}` markers and round-tripped via
/// base64. Not interchangeable with the native ZIP+SQLite backup format.
class WebBackupService {
  static const int _formatVersion = 1;

  /// Whitelisted prefs keys that round-trip through a web backup. API key
  /// related entries are deliberately omitted — users must re-enter keys after
  /// restoring a web backup. See also [_sanitizedCustomJsonKeys].
  static const List<String> prefsKeys = [
    'theme_mode',
    'theme_color',
    'chat_model_provider',
    'chat_model',
    'character_is_grid_view',
    'character_sort_method',
    'custom_models',
    'custom_providers',
  ];

  /// Prefs keys whose values are JSON-encoded lists of objects that each carry
  /// an `apiKey` field. These values are preserved in the backup, but the
  /// `apiKey` field on every entry is stripped before dumping.
  static const Set<String> _sanitizedCustomJsonKeys = {
    'custom_models',
    'custom_providers',
  };

  /// Tables that must not appear in the dump (sqlite internals + leftover backup
  /// metadata from older native backups that may live alongside user data).
  static bool _shouldSkipTable(String name) {
    if (name.startsWith('sqlite_')) return true;
    if (name.startsWith('android_')) return true;
    if (name == '_backup_metadata') return true;
    return false;
  }

  /// Builds a JSON snapshot of every user table + whitelisted prefs.
  /// Returns the raw bytes ready to be downloaded by the browser.
  Future<Uint8List> exportToBytes() async {
    final db = await DatabaseHelper.instance.database;

    final tableRows = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table'",
    );

    final tables = <String, List<Map<String, Object?>>>{};
    for (final row in tableRows) {
      final name = row['name'] as String;
      if (_shouldSkipTable(name)) continue;
      final rows = await db.rawQuery('SELECT * FROM "$name"');
      tables[name] = rows.map(_encodeRow).toList();
    }

    final prefs = await SharedPreferences.getInstance();
    final prefsData = <String, Object?>{};
    for (final key in prefsKeys) {
      final value = prefs.get(key);
      if (value == null) continue;
      if (_sanitizedCustomJsonKeys.contains(key) && value is String) {
        prefsData[key] = _stripApiKeyFromJsonList(value);
      } else {
        prefsData[key] = value;
      }
    }

    final envelope = <String, Object?>{
      'format': 'flan_web_backup',
      'format_version': _formatVersion,
      'schema_version': await db.getVersion(),
      'created_at': DateTime.now().toIso8601String(),
      'tables': tables,
      'preferences': prefsData,
    };

    final jsonStr = jsonEncode(envelope);
    return Uint8List.fromList(utf8.encode(jsonStr));
  }

  /// Restores a snapshot produced by [exportToBytes]. Wipes existing rows in
  /// every dumped table before inserting; preferences in the whitelist are
  /// overwritten in-place.
  Future<RestoreResult> restoreFromBytes(Uint8List bytes) async {
    final Map<String, Object?> envelope;
    try {
      envelope = jsonDecode(utf8.decode(bytes)) as Map<String, Object?>;
    } catch (e) {
      throw const FormatException('백업 파일이 올바른 JSON이 아닙니다.');
    }

    if (envelope['format'] != 'flan_web_backup') {
      throw const FormatException('Flan 웹 백업 파일이 아닙니다.');
    }

    final tables = envelope['tables'] as Map<String, Object?>?;
    if (tables == null) {
      throw const FormatException('백업 파일에 테이블 데이터가 없습니다.');
    }

    final db = await DatabaseHelper.instance.database;
    final dbSchemaVersion = await db.getVersion();
    final backupSchemaVersion = envelope['schema_version'] as int?;

    await db.transaction((txn) async {
      // Wipe each dumped table before reinserting. Existing tables that aren't
      // in the dump are left untouched (forward-compat for newer schemas).
      for (final entry in tables.entries) {
        final tableName = entry.key;
        if (_shouldSkipTable(tableName)) continue;
        // Verify the table exists in the current schema before touching it.
        final exists = await txn.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name = ?",
          [tableName],
        );
        if (exists.isEmpty) continue;

        await txn.delete(tableName);

        final rows = (entry.value as List).cast<Map<String, Object?>>();
        for (final row in rows) {
          final decoded = _decodeRow(row);
          await txn.insert(
            tableName,
            decoded,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
    });

    // Restore SharedPreferences whitelist.
    final prefs = await SharedPreferences.getInstance();
    final prefsMap = envelope['preferences'] as Map<String, Object?>?;
    if (prefsMap != null) {
      for (final entry in prefsMap.entries) {
        if (!prefsKeys.contains(entry.key)) continue;
        final value = entry.value;
        if (value is String) {
          await prefs.setString(entry.key, value);
        } else if (value is int) {
          await prefs.setInt(entry.key, value);
        } else if (value is double) {
          await prefs.setDouble(entry.key, value);
        } else if (value is bool) {
          await prefs.setBool(entry.key, value);
        } else if (value is List) {
          await prefs.setStringList(entry.key, value.cast<String>());
        }
      }
    }

    return RestoreResult(
      backupSchemaVersion: backupSchemaVersion,
      currentSchemaVersion: dbSchemaVersion,
      createdAt: envelope['created_at'] as String?,
      tableCount: tables.length,
    );
  }

  // ── sanitization helpers ───────────────────────────────────────────────────

  /// Parses a JSON-encoded list of objects, removes the `apiKey` field from
  /// every object, and returns the re-encoded string. On parse failure the
  /// original value is dropped (returns empty list) so secrets never leak.
  static String _stripApiKeyFromJsonList(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return raw;
      final sanitized = decoded.map((entry) {
        if (entry is Map<String, dynamic>) {
          return Map<String, dynamic>.from(entry)..remove('apiKey');
        }
        return entry;
      }).toList();
      return jsonEncode(sanitized);
    } catch (_) {
      return jsonEncode(const []);
    }
  }

  // ── encode/decode helpers ──────────────────────────────────────────────────

  static Map<String, Object?> _encodeRow(Map<String, Object?> row) {
    final out = <String, Object?>{};
    row.forEach((key, value) {
      out[key] = _encodeValue(value);
    });
    return out;
  }

  static Object? _encodeValue(Object? value) {
    if (value is Uint8List) {
      return {'__b64__': base64.encode(value)};
    }
    return value;
  }

  static Map<String, Object?> _decodeRow(Map<String, Object?> row) {
    final out = <String, Object?>{};
    row.forEach((key, value) {
      out[key] = _decodeValue(value);
    });
    return out;
  }

  static Object? _decodeValue(Object? value) {
    if (value is Map && value.containsKey('__b64__')) {
      return base64.decode(value['__b64__'] as String);
    }
    return value;
  }
}

class RestoreResult {
  final int? backupSchemaVersion;
  final int currentSchemaVersion;
  final String? createdAt;
  final int tableCount;

  const RestoreResult({
    required this.backupSchemaVersion,
    required this.currentSchemaVersion,
    required this.createdAt,
    required this.tableCount,
  });

  bool get hasSchemaMismatch =>
      backupSchemaVersion != null && backupSchemaVersion != currentSchemaVersion;
}
