import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../../database/database_helper.dart';
import '../../utils/common_dialog.dart';
import '../../widgets/common/common_appbar.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  bool _isProcessing = false;

  static const _prefsKeys = [
    'api_key_google',
    'api_key_openai',
    'api_key_anthropic',
    'api_key',
    'theme_mode',
    'theme_color',
    'chat_model_provider',
    'chat_model',
    'character_is_grid_view',
    'character_sort_method',
  ];

  Future<void> _createBackup() async {
    setState(() => _isProcessing = true);

    try {
      final dbPath = await _db.getDatabaseFilePath();
      final now = DateTime.now();
      final timestamp =
          '${now.year}${_pad(now.month)}${_pad(now.day)}_${_pad(now.hour)}${_pad(now.minute)}${_pad(now.second)}';
      final fileName = 'flan_backup_$timestamp.db';

      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/$fileName';

      // Copy DB file to temp
      await File(dbPath).copy(tempPath);

      // Open the copy and embed preferences into it
      final backupDb = await openDatabase(tempPath, singleInstance: false);
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
      await backupDb.close();

      if (Platform.isAndroid) {
        const platform = MethodChannel('com.flanapp.flan/file_saver');
        final result = await platform.invokeMethod('copyFileToDownloads', {
          'sourcePath': tempPath,
          'fileName': fileName,
        });

        await File(tempPath).delete();

        if (result == true && mounted) {
          CommonDialog.showSnackBar(
            context: context,
            message: '백업 완료: Downloads/$fileName',
          );
        } else if (mounted) {
          CommonDialog.showSnackBar(
            context: context,
            message: '파일 저장에 실패했습니다',
          );
        }
      } else if (Platform.isIOS) {
        final docsDir = await getApplicationDocumentsDirectory();
        await File(tempPath).copy('${docsDir.path}/$fileName');
        await File(tempPath).delete();

        if (mounted) {
          CommonDialog.showSnackBar(
            context: context,
            message: '백업 완료: $fileName',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        CommonDialog.showSnackBar(
          context: context,
          message: '백업 실패: $e',
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _restoreBackup() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );

      if (result == null || result.files.single.path == null) return;

      final file = result.files.single;
      final selectedPath = file.path!;
      final originalName = file.name;
      if (!originalName.endsWith('.db')) {
        if (mounted) {
          CommonDialog.showSnackBar(
            context: context,
            message: '.db 백업 파일을 선택해주세요',
          );
        }
        return;
      }

      // Read backup metadata to show info
      String createdAt = '알 수 없음';
      try {
        final backupDb = await openDatabase(selectedPath, readOnly: true, singleInstance: false);
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
        title: '백업 복구',
        content: '백업 일시: $createdAt\n\n기존 데이터가 모두 삭제되고 백업 데이터로 대체됩니다.\n계속하시겠습니까?',
        confirmText: '복구',
        isDestructive: true,
      );

      if (confirm != true) return;

      setState(() => _isProcessing = true);

      // Close current DB, overwrite with backup, reopen
      final dbPath = await _db.getDatabaseFilePath();
      await _db.closeDatabase();

      await File(selectedPath).copy(dbPath);

      // Extract and restore preferences before reopening main DB
      try {
        final restoredDb = await openDatabase(dbPath, singleInstance: false);
        final tables = await restoredDb.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='_backup_metadata'",
        );
        if (tables.isNotEmpty) {
          final rows = await restoredDb.query(
            '_backup_metadata',
            where: 'key = ?',
            whereArgs: ['preferences'],
          );
          if (rows.isNotEmpty) {
            final prefsData =
                jsonDecode(rows.first['value'] as String) as Map<String, dynamic>;
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
          // Clean up metadata table from restored DB
          await restoredDb.execute('DROP TABLE IF EXISTS _backup_metadata');
        }
        await restoredDb.close();
      } catch (_) {
        // Preferences restore failed, but DB restore succeeded
      }

      await _db.reopenDatabase();

      if (mounted) {
        await CommonDialog.showInfo(
          context: context,
          title: '복구 완료',
          content: '백업 데이터가 복구되었습니다.\n변경사항을 완전히 적용하려면 앱을 재시작해주세요.',
        );
      }
    } catch (e) {
      if (mounted) {
        CommonDialog.showSnackBar(
          context: context,
          message: '복구 실패: $e',
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const CommonAppBar(title: '백업 및 복구'),
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
                            '백업 생성',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '캐릭터, 채팅 기록, 프롬프트, 설정 등 모든 데이터를 하나의 백업 파일로 내보냅니다.',
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
                          label: const Text('백업 파일 생성'),
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
                            '백업 복구',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '백업 .db 파일을 선택하여 데이터를 복원합니다.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '주의: 기존 데이터가 모두 삭제됩니다. 복구 후 앱 재시작이 필요합니다.',
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
                          label: const Text('백업 파일 선택'),
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
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('처리 중...'),
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
