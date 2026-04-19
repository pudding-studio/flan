import 'dart:convert';
import 'package:universal_io/io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../l10n/app_localizations.dart';
import '../database/database_helper.dart';
import '../models/character/character.dart';
import '../models/character/persona.dart';
import '../models/character/start_scenario.dart';
import '../models/character/character_book_folder.dart';
import '../models/character/cover_image.dart';
import '../utils/common_dialog.dart';
import '../utils/character_card_parser.dart';
import '../utils/streaming_zip_writer.dart';

/// Data transfer object holding all character-related data needed for export.
class CharacterExportData {
  final Character character;
  final List<Persona> personas;
  final List<StartScenario> startScenarios;
  final List<CharacterBookFolder> characterBookFolders;
  final List<CharacterBook> standaloneCharacterBooks;
  final List<CharacterBook> allCharacterBooks;
  final List<CoverImage> coverImages;

  CharacterExportData({
    required this.character,
    required this.personas,
    required this.startScenarios,
    required this.characterBookFolders,
    required this.standaloneCharacterBooks,
    required this.allCharacterBooks,
    required this.coverImages,
  });
}

/// Handles character export in multiple formats (Flan, V2 PNG, V3 JSON/PNG/charx).
class CharacterExporter {
  CharacterExporter._();

  // ─── Public API ─────────────────────────────────────────────────────────────

  /// Full export flow: shows format dialog, loads data, exports to file.
  static Future<void> export(
    BuildContext context,
    int characterId,
    DatabaseHelper db,
  ) async {
    final format = await showFormatDialog(context);
    if (format == null || !context.mounted) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: Center(child: CircularProgressIndicator()),
      ),
    );

    try {
      final data = await loadExportData(characterId, db);
      await _runExport(data, context, format);
    } catch (e) {
      if (context.mounted) {
        CommonDialog.showSnackBar(context: context, message: 'Export failed: $e');
      }
    } finally {
      if (context.mounted) Navigator.pop(context);
    }
  }

  /// Returns a format string or null if cancelled.
  /// Formats: 'flan' | 'v2_png' | 'v3_charx' | 'v3_charx_jpeg' | 'v3_png' | 'v3_json'
  static Future<String?> showFormatDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.characterExportFormatTitle),
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(l10n.characterExportFlanFormat),
              subtitle: Text(l10n.characterExportFlanSubtitle),
              onTap: () => Navigator.pop(ctx, 'flan'),
            ),
            ListTile(
              title: Text(l10n.characterExportV2Card),
              subtitle: Text(l10n.characterExportV2Subtitle),
              onTap: () => Navigator.pop(ctx, 'v2_png'),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(l10n.characterExportV3Card, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            ListTile(
              leading: const SizedBox(width: 16),
              title: const Text('charx'),
              onTap: () => Navigator.pop(ctx, 'v3_charx'),
            ),
            ListTile(
              leading: const SizedBox(width: 16),
              title: const Text('charx-JPEG'),
              onTap: () => Navigator.pop(ctx, 'v3_charx_jpeg'),
            ),
            ListTile(
              leading: const SizedBox(width: 16),
              title: const Text('PNG'),
              onTap: () => Navigator.pop(ctx, 'v3_png'),
            ),
            ListTile(
              leading: const SizedBox(width: 16),
              title: const Text('JSON'),
              onTap: () => Navigator.pop(ctx, 'v3_json'),
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

  /// Loads character + all related data from DB.
  static Future<CharacterExportData> loadExportData(
    int characterId,
    DatabaseHelper db,
  ) async {
    final character = await db.readCharacter(characterId);
    if (character == null) throw Exception('Character not found');

    final personas = await db.readPersonas(characterId);
    final startScenarios = await db.readStartScenarios(characterId);
    final characterBookFolders = await db.readCharacterBookFolders(characterId);
    final standaloneCharacterBooks = await db.readCharacterBooks(characterId);
    final coverImages = await db.readCoverImages(characterId);
    final additionalImages = await db.readAdditionalImages(characterId);

    for (final folder in characterBookFolders) {
      folder.characterBooks.addAll(await db.readCharacterBooksByFolder(folder.id!));
    }

    // Flatten all character books for CharacterCard formats
    final allCharacterBooks = [
      ...characterBookFolders.expand((f) => f.characterBooks),
      ...standaloneCharacterBooks,
    ];

    // Merge cover + additional images for export
    final allImages = [...coverImages, ...additionalImages];

    return CharacterExportData(
      character: character,
      personas: personas,
      startScenarios: startScenarios,
      characterBookFolders: characterBookFolders,
      standaloneCharacterBooks: standaloneCharacterBooks,
      allCharacterBooks: allCharacterBooks,
      coverImages: allImages,
    );
  }

  // ─── File save helpers ────────────────────────────────────────────────────

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
              ? l10n.characterExportSuccessAndroid(fileName)
              : l10n.characterExportSaveFailed,
        );
      }
    } else if (Platform.isIOS) {
      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/$fileName';
      await File(path).writeAsString(content);
      if (context.mounted) {
        CommonDialog.showSnackBar(
          context: context,
          message: AppLocalizations.of(context).characterExportSuccessIos(path),
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
          message: AppLocalizations.of(context).characterExportSuccessIos(savePath),
        );
      }
    }
  }

  static Future<void> _saveBinaryFile(
    BuildContext context,
    String fileName,
    List<int> bytes,
  ) async {
    final tempDir = await getTemporaryDirectory();
    final sourceFile = File('${tempDir.path}/$fileName');
    await sourceFile.writeAsBytes(bytes);
    await _saveExistingFile(context, fileName, sourceFile);
  }

  /// Save a file that already exists on disk (avoids re-buffering bytes in memory).
  /// The [sourceFile] is consumed (deleted) after save.
  static Future<void> _saveExistingFile(
    BuildContext context,
    String fileName,
    File sourceFile,
  ) async {
    try {
      if (Platform.isAndroid) {
        const platform = MethodChannel('com.flanapp.flan/file_saver');
        final ok = await platform.invokeMethod<bool>('copyFileToDownloads', {
          'sourcePath': sourceFile.path,
          'fileName': fileName,
        });
        if (context.mounted) {
          final l10n = AppLocalizations.of(context);
          CommonDialog.showSnackBar(
            context: context,
            message: ok == true
                ? l10n.characterExportSuccessAndroid(fileName)
                : l10n.characterExportSaveFailed,
          );
        }
      } else if (Platform.isIOS) {
        final dir = await getApplicationDocumentsDirectory();
        final path = '${dir.path}/$fileName';
        await sourceFile.copy(path);
        if (context.mounted) {
          CommonDialog.showSnackBar(
            context: context,
            message: AppLocalizations.of(context).characterExportSuccessIos(path),
          );
        }
      } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        final savePath = await FilePicker.platform.saveFile(
          dialogTitle: fileName,
          fileName: fileName,
          lockParentWindow: true,
        );
        if (savePath == null) return;
        await sourceFile.copy(savePath);
        if (context.mounted) {
          CommonDialog.showSnackBar(
            context: context,
            message: AppLocalizations.of(context).characterExportSuccessIos(savePath),
          );
        }
      }
    } finally {
      if (await sourceFile.exists()) await sourceFile.delete();
    }
  }

  // ─── Format dispatch ────────────────────────────────────────────────────────

  static Future<void> _runExport(
    CharacterExportData data,
    BuildContext context,
    String format,
  ) async {
    switch (format) {
      case 'flan':
        await _exportFlan(data, context);
      case 'v2_png':
        await _exportV2Png(data, context);
      case 'v3_json':
        await _exportV3Json(data, context);
      case 'v3_png':
        await _exportV3Png(data, context);
      case 'v3_charx':
        await _exportV3Charx(data, context);
      case 'v3_charx_jpeg':
        await _exportV3CharxJpeg(data, context);
    }
  }

  // ─── Flan format (PNG + ZIP polyglot: cover PNG followed by ZIP with character.json + images/) ─

  static Future<void> _exportFlan(CharacterExportData data, BuildContext context) async {
    // Build cover image entries WITHOUT imageData (references only)
    final imageEntries = <CoverImage>[];
    final imageFiles = <({String zipPath, CoverImage image})>[];

    for (final image in data.coverImages) {
      final ext = image.path != null
          ? p.extension(image.path!).replaceFirst('.', '').toLowerCase()
          : 'png';
      final zipPath = 'images/${image.name}.${ext.isNotEmpty ? ext : 'png'}';

      imageEntries.add(CoverImage(
        characterId: image.characterId,
        name: image.name,
        order: image.order,
        isExpanded: image.isExpanded,
        imageType: image.imageType,
      ));
      imageFiles.add((zipPath: zipPath, image: image));
    }

    final jsonData = data.character.toJson(
      personas: data.personas,
      startScenarios: data.startScenarios,
      characterBookFolders: data.characterBookFolders,
      standaloneCharacterBooks: data.standaloneCharacterBooks,
      coverImages: imageEntries,
    );

    // Build polyglot (PNG prefix + ZIP body) directly on disk to avoid OOM.
    // Image viewers render the PNG prefix; ZIP tools (and our importer) locate
    // the archive via the PK\x03\x04 signature.
    final tempDir = await getTemporaryDirectory();
    final fileName = '${data.character.name}.flan';
    final tempZipPath = '${tempDir.path}/${data.character.name}.flan.zip';
    final polyglotPath = '${tempDir.path}/$fileName';

    final zipWriter = await StreamingZipWriter.open(tempZipPath);
    final jsonBytes = utf8.encode(const JsonEncoder.withIndent('  ').convert(jsonData));
    await zipWriter.addFile('character.json', jsonBytes);

    for (final entry in imageFiles) {
      final bytes = await entry.image.resolveImageData();
      if (bytes == null) continue;
      await zipWriter.addFile(entry.zipPath, bytes);
    }
    await zipWriter.close();

    final coverPng = await _resolveCoverPng(data);
    final polyglotFile = File(polyglotPath);
    final out = polyglotFile.openWrite();
    out.add(coverPng);
    await out.addStream(File(tempZipPath).openRead());
    await out.flush();
    await out.close();
    await File(tempZipPath).delete();

    await _saveExistingFile(context, fileName, polyglotFile);
  }

  // ─── Character Card V2 PNG ─────────────────────────────────────────────────

  static Future<void> _exportV2Png(CharacterExportData data, BuildContext context) async {
    final cardJson = CharacterCardParser.toCharacterCardV2(
      character: data.character,
      personas: data.personas,
      startScenarios: data.startScenarios,
      characterBooks: data.allCharacterBooks,
    );

    final coverBytes = await _resolveCoverPng(data);
    final pngBytes = CharacterCardParser.embedMetadataInPng(coverBytes, cardJson);
    if (pngBytes == null) throw Exception('PNG metadata embedding failed');

    await _saveBinaryFile(context, '${data.character.name}.png', pngBytes);
  }

  // ─── Character Card V3 JSON ────────────────────────────────────────────────

  static Future<void> _exportV3Json(CharacterExportData data, BuildContext context) async {
    final imageAssets = await _buildDataUriAssets(data);

    final cardJson = CharacterCardParser.toCharacterCardV3WithDataAssets(
      character: data.character,
      personas: data.personas,
      startScenarios: data.startScenarios,
      characterBooks: data.allCharacterBooks,
      imageAssets: imageAssets,
    );

    await _saveTextFile(
      context,
      '${data.character.name}.json',
      const JsonEncoder.withIndent('  ').convert(cardJson),
    );
  }

  // ─── Character Card V3 PNG ─────────────────────────────────────────────────

  static Future<void> _exportV3Png(CharacterExportData data, BuildContext context) async {
    final imageAssets = await _buildDataUriAssets(data);

    final cardJson = CharacterCardParser.toCharacterCardV3WithDataAssets(
      character: data.character,
      personas: data.personas,
      startScenarios: data.startScenarios,
      characterBooks: data.allCharacterBooks,
      imageAssets: imageAssets,
    );

    final coverBytes = await _resolveCoverPng(data);
    final pngBytes = CharacterCardParser.embedMetadataInPng(coverBytes, cardJson);
    if (pngBytes == null) throw Exception('PNG metadata embedding failed');

    await _saveBinaryFile(context, '${data.character.name}.png', pngBytes);
  }

  // ─── Character Card V3 charx ───────────────────────────────────────────────

  static Future<void> _exportV3Charx(CharacterExportData data, BuildContext context) async {
    final assetFiles = await _buildCharxAssets(data, asJpeg: false);

    final charxBytes = CharacterCardParser.buildCharxBytes(
      character: data.character,
      personas: data.personas,
      startScenarios: data.startScenarios,
      characterBooks: data.allCharacterBooks,
      assetFiles: assetFiles,
    );

    await _saveBinaryFile(context, '${data.character.name}.charx', charxBytes);
  }

  // ─── Character Card V3 charx-JPEG ──────────────────────────────────────────

  static Future<void> _exportV3CharxJpeg(CharacterExportData data, BuildContext context) async {
    final assetFiles = await _buildCharxAssets(data, asJpeg: true);

    final charxBytes = CharacterCardParser.buildCharxBytes(
      character: data.character,
      personas: data.personas,
      startScenarios: data.startScenarios,
      characterBooks: data.allCharacterBooks,
      assetFiles: assetFiles,
    );

    // Polyglot: JPEG cover + ZIP concatenated. Use BytesBuilder to avoid the
    // List<int> boxing blow-up that [...a, ...b] would cause with large buffers.
    final Uint8List polyglot;
    if (assetFiles.isNotEmpty) {
      final bb = BytesBuilder(copy: false);
      bb.add(assetFiles.first.bytes);
      bb.add(charxBytes);
      polyglot = bb.takeBytes();
    } else {
      polyglot = charxBytes;
    }

    await _saveBinaryFile(context, '${data.character.name}.charx', polyglot);
  }

  // ─── Image helpers ──────────────────────────────────────────────────────────

  /// Returns PNG bytes for the cover image (or a 1x1 white placeholder).
  static Future<Uint8List> _resolveCoverPng(CharacterExportData data) async {
    final covers = data.coverImages.where((i) => i.imageType == 'cover').toList()
      ..sort((CoverImage a, CoverImage b) => a.order.compareTo(b.order));

    final selected = covers.isEmpty ? null : (data.character.selectedCoverImageId != null
        ? covers.firstWhere(
            (i) => i.id == data.character.selectedCoverImageId,
            orElse: () => covers.first,
          )
        : covers.first);

    if (selected != null) {
      final bytes = await selected.resolveImageData();
      if (bytes != null) {
        final png = CharacterCardParser.convertToPng(bytes);
        if (png != null) return png;
      }
    }

    // 1x1 white PNG placeholder
    return _minimalPng();
  }

  /// Builds assets list with data: URIs (for JSON/PNG exports).
  /// Uses raw bytes without re-encoding to avoid OOM.
  static Future<List<({String name, String mimeType, Uint8List bytes, String imageType})>> _buildDataUriAssets(
      CharacterExportData data) async {
    final result = <({String name, String mimeType, Uint8List bytes, String imageType})>[];
    final sorted = [...data.coverImages]
      ..sort((CoverImage a, CoverImage b) => a.order.compareTo(b.order));

    for (final image in sorted) {
      final bytes = await image.resolveImageData();
      if (bytes == null) continue;
      final mime = CharacterCardParser.detectMimeType(bytes);
      result.add((name: image.name, mimeType: mime, bytes: bytes, imageType: image.imageType));
    }

    return result;
  }

  /// Builds asset file list for CHARX archive.
  /// Only converts the first cover image to JPEG when [asJpeg] is true; others pass through.
  static Future<List<({String filename, String mimeType, Uint8List bytes, String imageType})>> _buildCharxAssets(
      CharacterExportData data, {required bool asJpeg}) async {
    final result = <({String filename, String mimeType, Uint8List bytes, String imageType})>[];
    final sorted = [...data.coverImages]
      ..sort((CoverImage a, CoverImage b) => a.order.compareTo(b.order));

    bool firstCoverDone = false;
    for (final image in sorted) {
      final raw = await image.resolveImageData();
      if (raw == null) continue;

      final Uint8List bytes;
      final String ext;
      final String mime;
      final bool isCover = image.imageType == 'cover';

      if (asJpeg && isCover && !firstCoverDone) {
        final jpeg = CharacterCardParser.convertToJpeg(raw);
        if (jpeg == null) continue;
        bytes = jpeg;
        ext = 'jpg';
        mime = 'image/jpeg';
      } else {
        bytes = raw;
        final detected = CharacterCardParser.detectMimeType(raw);
        ext = CharacterCardParser.mimeToExt(detected);
        mime = detected;
      }

      final filename = isCover ? '${image.name}.$ext' : '${image.name}.$ext';
      result.add((filename: filename, mimeType: mime, bytes: bytes, imageType: image.imageType));
      if (isCover) firstCoverDone = true;
    }

    return result;
  }

  /// Returns a minimal 1x1 white PNG as a fallback cover.
  static Uint8List _minimalPng() {
    // Pre-built 1x1 white PNG bytes
    return Uint8List.fromList([
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG signature
      0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, // IHDR length + type
      0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, // width=1, height=1
      0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53, // bit depth, color type, crc
      0xDE, 0x00, 0x00, 0x00, 0x0C, 0x49, 0x44, 0x41, // IDAT length + type
      0x54, 0x08, 0xD7, 0x63, 0xF8, 0xFF, 0xFF, 0x3F, // deflate stream
      0x00, 0x05, 0xFE, 0x02, 0xFE, 0xDC, 0xCC, 0x59, // data + crc
      0xE7, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, // IEND length + type
      0x44, 0xAE, 0x42, 0x60, 0x82,                   // IEND crc
    ]);
  }
}
