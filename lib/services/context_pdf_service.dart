import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../utils/context_pdf.dart';

/// Loads the bundled PDF fonts once and renders context PDFs off the UI
/// isolate: laying out dozens of dense pages would otherwise drop frames
/// while the message is sending.
class ContextPdfService {
  static const String _fontDir = 'assets/fonts/context_pdf';
  static Future<ContextPdfFonts>? _fonts;

  static Future<Uint8List> render({
    required String summary,
    required List<ContextPdfEntry> entries,
  }) async {
    final fonts = await (_fonts ??= _loadFonts());
    return compute(_renderJob, _ContextPdfJob(fonts, summary, entries));
  }

  static Future<ContextPdfFonts> _loadFonts() async {
    try {
      return ContextPdfFonts(
        base: await rootBundle.load('$_fontDir/NotoSansKR-Regular.ttf'),
        kanji: await rootBundle.load('$_fontDir/NotoSansJP-Kanji-Regular.ttf'),
        emoji: await rootBundle.load('$_fontDir/NotoEmoji-Regular.ttf'),
      );
    } catch (_) {
      _fonts = null;
      rethrow;
    }
  }
}

class _ContextPdfJob {
  final ContextPdfFonts fonts;
  final String summary;
  final List<ContextPdfEntry> entries;

  const _ContextPdfJob(this.fonts, this.summary, this.entries);
}

Future<Uint8List> _renderJob(_ContextPdfJob job) => ContextPdf.render(
      fonts: job.fonts,
      summary: job.summary,
      entries: job.entries,
    );
