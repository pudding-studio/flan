import 'package:universal_io/io.dart';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Result of [CharacterImageStorage.saveImageBytes].
/// Native: [path] is set, [bytes] is null.
/// Web: [bytes] is set, [path] is null (no filesystem available).
class StoredImage {
  final String? path;
  final Uint8List? bytes;
  const StoredImage({this.path, this.bytes});
}

class CharacterImageStorage {
  /// Saves image bytes to {appDocDir}/characters/{characterName}/{imageName}.{ext}
  /// Returns the absolute path of the saved file.
  static Future<String> saveImage(
    String characterName,
    String imageName,
    String ext,
    Uint8List bytes,
  ) async {
    final dir = await _characterDir(characterName);
    final filePath = await _resolvePath(dir, imageName, ext);
    final file = File(filePath);
    await file.writeAsBytes(bytes);
    return filePath;
  }

  /// Platform-aware variant: writes to disk on native, keeps bytes in-memory on web.
  /// Callers store the result on [CoverImage] via either `path` or `imageData`,
  /// and rendering picks whichever is available via `resolveImageData()`.
  static Future<StoredImage> saveImageBytes(
    String characterName,
    String imageName,
    String ext,
    Uint8List bytes,
  ) async {
    if (kIsWeb) {
      return StoredImage(bytes: bytes);
    }
    final path = await saveImage(characterName, imageName, ext, bytes);
    return StoredImage(path: path);
  }

  /// Loads image bytes from the given absolute path. Returns null if not found.
  static Future<Uint8List?> loadImage(String path) async {
    final file = File(path);
    if (!await file.exists()) return null;
    return await file.readAsBytes();
  }

  /// Deletes the image file at the given path. Silently ignores missing files.
  static Future<void> deleteImage(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Returns the character-specific directory, creating it if necessary.
  static Future<String> _characterDir(String characterName) async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final safeCharName = _sanitizeFileName(characterName);
    final dir = Directory(p.join(appDocDir.path, 'characters', safeCharName));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir.path;
  }

  /// Resolves a unique file path, appending _1, _2, ... suffix on collision.
  static Future<String> _resolvePath(String dir, String baseName, String ext) async {
    final safeName = _sanitizeFileName(baseName);
    final normalizedExt = ext.isNotEmpty ? ext.toLowerCase() : 'bin';
    var candidate = p.join(dir, '$safeName.$normalizedExt');
    var counter = 1;
    while (await File(candidate).exists()) {
      candidate = p.join(dir, '${safeName}_$counter.$normalizedExt');
      counter++;
    }
    return candidate;
  }

  /// Removes characters that are illegal in file/directory names.
  static String _sanitizeFileName(String name) {
    return name
        .replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '_')
        .trim()
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^[._]+|[._]+$'), '');
  }
}
