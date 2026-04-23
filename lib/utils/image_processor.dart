import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as img;
import 'package:universal_io/io.dart';

class ProcessedImage {
  final Uint8List bytes;
  final String ext;
  const ProcessedImage(this.bytes, this.ext);
}

class ImageProcessor {
  static const int maxDimension = 1024;
  static const int webpQuality = 85;
  static const int jpegQuality = 85;

  /// Processes an image for storage: caps the longer side at [maxDimension]
  /// and, on Android/iOS, re-encodes as WebP. On other platforms (desktop/web)
  /// the image is only resized — the original format is preserved.
  /// On any failure, returns the original bytes with the original extension.
  static Future<ProcessedImage> processForStorage(
    Uint8List bytes, {
    String originalExt = '',
  }) async {
    final normalizedExt = _normalizeExt(originalExt);
    final isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);

    img.Image? decoded;
    try {
      decoded = img.decodeImage(bytes);
    } catch (_) {
      decoded = null;
    }

    // Undecodable by the `image` package (e.g. HEIC). On mobile, still try
    // the native encoder — it may understand the format. Otherwise leave
    // the bytes untouched.
    if (decoded == null) {
      if (isMobile) {
        final compressed = await _compressToWebp(
          bytes,
          minWidth: maxDimension,
          minHeight: maxDimension,
        );
        if (compressed != null) return ProcessedImage(compressed, 'webp');
      }
      return ProcessedImage(bytes, normalizedExt);
    }

    final longer = decoded.width >= decoded.height ? decoded.width : decoded.height;
    int targetW = decoded.width;
    int targetH = decoded.height;
    if (longer > maxDimension) {
      final scale = maxDimension / longer;
      targetW = (decoded.width * scale).round().clamp(1, maxDimension);
      targetH = (decoded.height * scale).round().clamp(1, maxDimension);
    }
    final needsResize = targetW != decoded.width || targetH != decoded.height;

    if (isMobile) {
      final compressed = await _compressToWebp(
        bytes,
        minWidth: targetW,
        minHeight: targetH,
      );
      if (compressed != null) return ProcessedImage(compressed, 'webp');
      // Fall through to pure-Dart path if native compressor failed
    }

    // Desktop / web / fallback: resize only, preserve format.
    if (!needsResize) {
      return ProcessedImage(bytes, normalizedExt);
    }

    final resized = img.copyResize(
      decoded,
      width: targetW,
      height: targetH,
      interpolation: img.Interpolation.cubic,
    );

    switch (normalizedExt) {
      case 'jpg':
      case 'jpeg':
        return ProcessedImage(
          Uint8List.fromList(img.encodeJpg(resized, quality: jpegQuality)),
          'jpg',
        );
      case 'webp':
        // No WebP encoder available in pure Dart — fall back to PNG.
        return ProcessedImage(
          Uint8List.fromList(img.encodePng(resized)),
          'png',
        );
      case 'png':
      default:
        return ProcessedImage(
          Uint8List.fromList(img.encodePng(resized)),
          'png',
        );
    }
  }

  static Future<Uint8List?> _compressToWebp(
    Uint8List bytes, {
    required int minWidth,
    required int minHeight,
  }) async {
    try {
      final result = await FlutterImageCompress.compressWithList(
        bytes,
        format: CompressFormat.webp,
        minWidth: minWidth,
        minHeight: minHeight,
        quality: webpQuality,
      );
      if (result.isEmpty) return null;
      return result;
    } catch (_) {
      return null;
    }
  }

  static String _normalizeExt(String ext) {
    final lower = ext.toLowerCase().replaceFirst('.', '').trim();
    if (lower.isEmpty) return 'bin';
    if (lower == 'jpeg') return 'jpg';
    return lower;
  }
}
