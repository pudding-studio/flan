import 'dart:convert';
import 'package:universal_io/io.dart';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../../database/database_helper.dart';
import '../../l10n/app_localizations.dart';
import '../../services/backup/web_backup_service.dart';
import '../../services/backup/web_download.dart';
import '../../utils/common_dialog.dart';
import '../../utils/streaming_zip_writer.dart';
import '../../widgets/common/common_appbar.dart';

// Isolate entry-point: extract backup.db from ZIP to temp path.
// Returns true on success, false if backup.db not found in archive.
Future<bool> _extractBackupDbIsolate(List<String> args) async {
  final zipPath = args[0];
  final dbOutPath = args[1];
  final input = InputFileStream(zipPath);
  final archive = ZipDecoder().decodeStream(input);
  final dbEntry = archive.findFile('backup.db');
  if (dbEntry == null) {
    archive.clearSync();
    input.closeSync();
    return false;
  }
  final out = OutputFileStream(dbOutPath);
  dbEntry.writeContent(out);
  out.closeSync();
  archive.clearSync();
  input.closeSync();
  return true;
}

// Isolate entry-point: extract character files from ZIP.
// Returns total number of extracted files.
Future<int> _extractCharacterFilesIsolate(List<String> args) async {
  final zipPath = args[0];
  final appDocPath = args[1];
  final input = InputFileStream(zipPath);
  final archive = ZipDecoder().decodeStream(input);
  int count = 0;
  for (final entry in archive) {
    if (!entry.isFile || !entry.name.startsWith('characters/')) {
      continue;
    }
    final outPath = p.join(appDocPath, entry.name);
    Directory(p.dirname(outPath)).createSync(recursive: true);
    final out = OutputFileStream(outPath);
    entry.writeContent(out);
    out.closeSync();
    entry.clear();
    count++;
  }
  archive.clearSync();
  input.closeSync();
  return count;
}

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  bool _isProcessing = false;
  String _progressText = '';

  void _updateProgress(String text) {
    if (mounted) setState(() => _progressText = text);
  }

  static const _prefsKeys = [
    'api_key_google',
    'api_key_openai',
    'api_key_anthropic',
    'api_keys_google',
    'api_keys_openai',
    'api_keys_anthropic',
    'api_key_active_google',
    'api_key_active_openai',
    'api_key_active_anthropic',
    'api_key',
    'theme_mode',
    'theme_color',
    'chat_model_provider',
    'chat_model',
    'character_is_grid_view',
    'character_sort_method',
    'custom_models',
    'custom_providers',
  ];

  Future<void> _createBackup() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _isProcessing = true);

    try {
      if (kIsWeb) {
        await _createBackupWeb(l10n);
        return;
      }

      _updateProgress(l10n.backupProgressDb);

      final dbPath = await _db.getDatabaseFilePath();
      final appDocDir = await getApplicationDocumentsDirectory();
      final now = DateTime.now();
      final timestamp =
          '${now.year}${_pad(now.month)}${_pad(now.day)}_${_pad(now.hour)}${_pad(now.minute)}${_pad(now.second)}';
      final fileName = 'flan_backup_$timestamp.zip';

      final tempDir = await getTemporaryDirectory();
      final tempDbPath = '${tempDir.path}/backup.db';

      // Copy DB file to temp
      await File(dbPath).copy(tempDbPath);

      // Open the copy and embed preferences + app path into it
      final backupDb = await openDatabase(tempDbPath, singleInstance: false);
      await backupDb.execute('''
        CREATE TABLE IF NOT EXISTS _backup_metadata (
          key TEXT PRIMARY KEY,
          value TEXT
        )
      ''');

      final prefs = await SharedPreferences.getInstance();
      final prefsData = <String, dynamic>{};
      for (final key in _prefsKeys) {
        final value = prefs.get(key);
        if (value != null) prefsData[key] = value;
      }

      await backupDb.insert('_backup_metadata', {
        'key': 'preferences',
        'value': jsonEncode(prefsData),
      });
      await backupDb.insert('_backup_metadata', {
        'key': 'created_at',
        'value': now.toIso8601String(),
      });
      await backupDb.insert('_backup_metadata', {
        'key': 'app_doc_path',
        'value': appDocDir.path,
      });
      await backupDb.close();

      // Build ZIP: stream entries one at a time to avoid OOM
      final tempZipPath = '${tempDir.path}/$fileName';
      final zipWriter = await StreamingZipWriter.open(tempZipPath);

      final dbBytes = await File(tempDbPath).readAsBytes();
      await zipWriter.addFile('backup.db', dbBytes);
      await File(tempDbPath).delete();

      final charsDir = Directory(p.join(appDocDir.path, 'characters'));
      if (await charsDir.exists()) {
        // Count total files first for progress
        final charFiles = <File>[];
        await for (final entity in charsDir.list(recursive: true)) {
          if (entity is File) charFiles.add(entity);
        }

        for (var i = 0; i < charFiles.length; i++) {
          _updateProgress(l10n.backupProgressFiles(i + 1, charFiles.length));
          final entity = charFiles[i];
          final relativePath = p.relative(entity.path, from: appDocDir.path);
          final fileBytes = await entity.readAsBytes();
          await zipWriter.addFile(relativePath, fileBytes);
        }
      }

      await zipWriter.close();

      _updateProgress(l10n.backupProgressSaving);

      if (Platform.isAndroid) {
        const platform = MethodChannel('com.flanapp.flan/file_saver');
        final result = await platform.invokeMethod('copyFileToDownloads', {
          'sourcePath': tempZipPath,
          'fileName': fileName,
        });
        await File(tempZipPath).delete();

        if (result == true && mounted) {
          CommonDialog.showSnackBar(
            context: context,
            message: l10n.backupSuccessDownloads(fileName),
          );
        } else if (mounted) {
          CommonDialog.showSnackBar(
            context: context,
            message: l10n.backupSaveFailed,
          );
        }
      } else if (Platform.isIOS) {
        final docsDir = await getApplicationDocumentsDirectory();
        await File(tempZipPath).copy('${docsDir.path}/$fileName');
        await File(tempZipPath).delete();

        if (mounted) {
          CommonDialog.showSnackBar(
            context: context,
            message: l10n.backupSuccessIos(fileName),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        CommonDialog.showSnackBar(
          context: context,
          message: l10n.backupFailed(e.toString()),
        );
      }
    } finally {
      if (mounted) setState(() { _isProcessing = false; _progressText = ''; });
    }
  }

  Future<void> _restoreBackup() async {
    final l10n = AppLocalizations.of(context);

    if (kIsWeb) {
      await _restoreBackupWeb(l10n);
      return;
    }

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );

      if (result == null || result.files.single.path == null) return;

      final file = result.files.single;
      final selectedPath = file.path!;
      final originalName = file.name;
      final isZip = originalName.endsWith('.zip');
      final isDb = originalName.endsWith('.db');

      setState(() => _isProcessing = true);
      _updateProgress(l10n.backupRestoreProgressReading);

      if (!isZip && !isDb) {
        if (mounted) {
          setState(() { _isProcessing = false; _progressText = ''; });
          CommonDialog.showSnackBar(
            context: context,
            message: l10n.backupInvalidFile,
          );
        }
        return;
      }

      // Resolve the DB path from ZIP or use directly
      String dbPathToRead = selectedPath;
      if (isZip) {
        final tempDir = await getTemporaryDirectory();
        dbPathToRead = '${tempDir.path}/backup_restore.db';

        // Run ZIP decode + backup.db extraction in background isolate
        final found = await compute(
          _extractBackupDbIsolate,
          [selectedPath, dbPathToRead],
        );
        if (!found) {
          if (mounted) {
            setState(() { _isProcessing = false; _progressText = ''; });
            CommonDialog.showSnackBar(
              context: context,
              message: l10n.backupZipNoDb,
            );
          }
          return;
        }
      }

      // Hide loading overlay before showing confirmation dialog
      if (mounted) setState(() { _isProcessing = false; _progressText = ''; });

      // Read backup metadata to show info
      String createdAt = l10n.backupCreatedAtUnknown;
      try {
        final backupDb = await openDatabase(dbPathToRead, readOnly: true, singleInstance: false);
        final tables = await backupDb.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='_backup_metadata'",
        );
        if (tables.isNotEmpty) {
          final rows = await backupDb.query(
            '_backup_metadata',
            where: 'key = ?',
            whereArgs: ['created_at'],
          );
          if (rows.isNotEmpty) createdAt = rows.first['value'] as String;
        }
        await backupDb.close();
      } catch (_) {
        // Not a valid backup file or no metadata - still allow restore
      }

      if (!mounted) return;
      final confirm = await CommonDialog.showConfirmation(
        context: context,
        title: l10n.backupRestoreConfirmTitle,
        content: l10n.backupRestoreConfirmContent(createdAt),
        confirmText: l10n.backupRestoreConfirmButton,
        isDestructive: true,
      );

      if (confirm != true) {
        if (isZip) await File(dbPathToRead).delete();
        return;
      }

      setState(() => _isProcessing = true);

      final appDocDir = await getApplicationDocumentsDirectory();

      // Restore character images from ZIP in background isolate
      if (isZip) {
        _updateProgress(l10n.backupRestoreProgressReading);

        // Clear existing characters directory
        final charsDir = Directory(p.join(appDocDir.path, 'characters'));
        if (await charsDir.exists()) {
          await charsDir.delete(recursive: true);
        }

        await compute(
          _extractCharacterFilesIsolate,
          [selectedPath, appDocDir.path],
        );
      }

      _updateProgress(l10n.backupRestoreProgressDb);

      // Close current DB, overwrite with backup, reopen
      final dbPath = await _db.getDatabaseFilePath();
      await _db.closeDatabase();

      if (isZip) {
        await File(dbPathToRead).copy(dbPath);
        await File(dbPathToRead).delete();
      } else {
        await File(selectedPath).copy(dbPath);
      }

      // Extract and restore preferences, fix image paths
      try {
        final restoredDb = await openDatabase(dbPath, singleInstance: false);
        final tables = await restoredDb.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='_backup_metadata'",
        );
        if (tables.isNotEmpty) {
          // Restore preferences
          final prefsRows = await restoredDb.query(
            '_backup_metadata',
            where: 'key = ?',
            whereArgs: ['preferences'],
          );
          if (prefsRows.isNotEmpty) {
            final prefsData =
                jsonDecode(prefsRows.first['value'] as String) as Map<String, dynamic>;
            final prefs = await SharedPreferences.getInstance();
            for (final entry in prefsData.entries) {
              final value = entry.value;
              if (value is String) {
                await prefs.setString(entry.key, value);
              } else if (value is int) {
                await prefs.setInt(entry.key, value);
              } else if (value is double) {
                await prefs.setDouble(entry.key, value);
              } else if (value is bool) {
                await prefs.setBool(entry.key, value);
              }
            }
          }

          // Fix image paths if app doc path changed
          if (isZip) {
            final pathRows = await restoredDb.query(
              '_backup_metadata',
              where: 'key = ?',
              whereArgs: ['app_doc_path'],
            );
            if (pathRows.isNotEmpty) {
              final oldDocPath = pathRows.first['value'] as String;
              final newDocPath = appDocDir.path;
              if (oldDocPath != newDocPath) {
                await restoredDb.rawUpdate(
                  "UPDATE cover_images SET path = REPLACE(path, ?, ?) WHERE path IS NOT NULL",
                  [oldDocPath, newDocPath],
                );
              }
            }
          }

          // Clean up metadata table
          await restoredDb.execute('DROP TABLE IF EXISTS _backup_metadata');
        }
        await restoredDb.close();
      } catch (_) {
        // Preferences/path restore failed, but DB restore succeeded
      }

      await _db.reopenDatabase();

      if (mounted) {
        await CommonDialog.showInfo(
          context: context,
          title: l10n.backupRestoreSuccessTitle,
          content: l10n.backupRestoreSuccessContent,
        );
      }
    } catch (e) {
      if (mounted) {
        CommonDialog.showSnackBar(
          context: context,
          message: l10n.backupRestoreFailed(e.toString()),
        );
      }
    } finally {
      if (mounted) setState(() { _isProcessing = false; _progressText = ''; });
    }
  }

  // ── Web backup (JSON dump → browser download) ─────────────────────────────

  Future<void> _createBackupWeb(AppLocalizations l10n) async {
    try {
      final bytes = await WebBackupService().exportToBytes();
      final now = DateTime.now();
      final timestamp =
          '${now.year}${_pad(now.month)}${_pad(now.day)}_${_pad(now.hour)}${_pad(now.minute)}${_pad(now.second)}';
      final fileName = 'flan_web_backup_$timestamp.json';
      await downloadBytesAsFile(bytes, fileName);

      if (mounted) {
        CommonDialog.showSnackBar(
          context: context,
          message: l10n.backupSuccessDownloads(fileName),
        );
      }
    } catch (e) {
      if (mounted) {
        CommonDialog.showSnackBar(
          context: context,
          message: l10n.backupFailed(e.toString()),
        );
      }
    }
  }

  Future<void> _restoreBackupWeb(AppLocalizations l10n) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );
      if (result == null || result.files.single.bytes == null) return;

      final bytes = result.files.single.bytes!;

      if (!mounted) return;
      final confirm = await CommonDialog.showConfirmation(
        context: context,
        title: l10n.backupRestoreConfirmTitle,
        content: l10n.backupRestoreConfirmContent(result.files.single.name),
        confirmText: l10n.backupRestoreConfirmButton,
        isDestructive: true,
      );
      if (confirm != true) return;

      setState(() => _isProcessing = true);
      final restored = await WebBackupService().restoreFromBytes(bytes);

      if (mounted) {
        await CommonDialog.showInfo(
          context: context,
          title: l10n.backupRestoreSuccessTitle,
          content: restored.hasSchemaMismatch
              ? '${l10n.backupRestoreSuccessContent}\n(schema v${restored.backupSchemaVersion} → v${restored.currentSchemaVersion})'
              : l10n.backupRestoreSuccessContent,
        );
      }
    } catch (e) {
      if (mounted) {
        CommonDialog.showSnackBar(
          context: context,
          message: l10n.backupRestoreFailed(e.toString()),
        );
      }
    } finally {
      if (mounted) setState(() { _isProcessing = false; _progressText = ''; });
    }
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CommonAppBar(title: AppLocalizations.of(context).backupTitle),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.backup, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            l10n.backupSectionTitle,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.backupSectionDesc,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _isProcessing ? null : _createBackup,
                          icon: const Icon(Icons.file_download),
                          label: Text(l10n.backupCreateButton),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.restore, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            l10n.backupRestoreTitle,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.backupRestoreDesc,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.backupRestoreWarning,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _isProcessing ? null : _restoreBackup,
                          icon: const Icon(Icons.file_upload),
                          label: Text(l10n.backupRestoreButton),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_isProcessing)
            Container(
              color: Colors.black26,
              child: Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(_progressText.isNotEmpty
                            ? _progressText
                            : l10n.backupProcessing),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
