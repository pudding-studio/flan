import 'dart:convert';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// One speaker turn of the conversation history packed into the PDF.
class ContextPdfEntry {
  final String speaker;
  final String text;

  const ContextPdfEntry(this.speaker, this.text);
}

/// Font bytes for the PDF. A glyph missing from every font is also missing
/// from the PDF text layer, which is what Gemini actually reads, so:
/// [base] covers Latin, Hangul, kana and common hanja; [kanji] adds the
/// Japanese kanji [base] lacks; [emoji] keeps symbols such as the 📍 metadata
/// markers.
class ContextPdfFonts {
  final ByteData base;
  final ByteData kanji;
  final ByteData emoji;

  const ContextPdfFonts({
    required this.base,
    required this.kanji,
    required this.emoji,
  });
}

/// Sends long Gemini context as a PDF. Gemini bills a PDF page at a fixed
/// image rate (280 tokens at MEDIA_RESOLUTION_LOW) and does not bill the
/// page's native text layer, so a densely packed page costs far less than
/// the same text sent as plain tokens.
class ContextPdf {
  static const int thresholdTokens = 30000;
  static const String mimeType = 'application/pdf';
  static const String placeholderKey = 'contextPdfPlaceholder';

  static const String summaryPointer =
      '[The summary of earlier events is in the attached PDF.]';
  static const String attachmentNote =
      '[The attached PDF holds the conversation so far: a summary of earlier '
      'events, then the chat log in order, oldest first. Treat it as the '
      'preceding turns and continue from its last entry.]';

  static const double _fontSize = 6.5;
  static const double _margin = 18;

  static Map<String, dynamic> placeholderPart() =>
      <String, dynamic>{placeholderKey: true};

  static bool isPlaceholder(Object? part) =>
      part is Map && part[placeholderKey] == true;

  static Future<Uint8List> render({
    required ContextPdfFonts fonts,
    required String summary,
    required List<ContextPdfEntry> entries,
  }) async {
    final theme = pw.ThemeData.withFont(
      base: _Utf16CmapFont(fonts.base),
      fontFallback: [_Utf16CmapFont(fonts.kanji), _Utf16CmapFont(fonts.emoji)],
    ).copyWith(
      defaultTextStyle: const pw.TextStyle(fontSize: _fontSize, lineSpacing: 1),
    );

    final body = <pw.Widget>[
      if (summary.trim().isNotEmpty) ...[
        _heading('Summary of earlier events'),
        ..._paragraphs(summary),
      ],
      if (entries.isNotEmpty) ...[
        _heading('Chat log (oldest first)'),
        for (final entry in entries)
          ..._paragraphs('${entry.speaker}: ${entry.text}'),
      ],
    ];

    final doc = pw.Document(compress: true);
    doc.addPage(pw.MultiPage(
      theme: theme,
      pageFormat: PdfPageFormat.a4.copyWith(
        marginLeft: _margin,
        marginRight: _margin,
        marginTop: _margin,
        marginBottom: _margin,
      ),
      maxPages: 10000,
      build: (_) => body,
    ));
    return doc.save();
  }

  /// Replaces the placeholder part with the PDF itself followed by the note
  /// telling the model what the attachment is.
  static List<Map<String, dynamic>> attach(
    List<Map<String, dynamic>> contents,
    Uint8List pdfBytes,
  ) {
    return contents.map((message) {
      final parts = message['parts'] as List<dynamic>;
      if (!parts.any(isPlaceholder)) return message;
      return {
        ...message,
        'parts': [
          for (final part in parts)
            if (isPlaceholder(part)) ...[
              {
                'inlineData': {
                  'mimeType': mimeType,
                  'data': base64Encode(pdfBytes),
                },
              },
              {'text': attachmentNote},
            ] else
              part,
        ],
      };
    }).toList();
  }

  static bool containsPdf(List<Map<String, dynamic>> contents) =>
      contents.any((message) => (message['parts'] as List<dynamic>? ?? [])
          .any((part) => part is Map && part['inlineData'] is Map));

  /// Request body copy for the chat log, with the base64 payload swapped for
  /// its size so a multi-page PDF does not bloat the log database.
  static Map<String, dynamic> redactForLog(Map<String, dynamic> requestBody) {
    final contents = requestBody['contents'];
    if (contents is! List) return requestBody;
    return {
      ...requestBody,
      'contents': [
        for (final message in contents)
          if (message is Map)
            {
              ...message,
              'parts': [
                for (final part in (message['parts'] as List? ?? []))
                  if (part is Map && part['inlineData'] is Map)
                    {
                      'inlineData': {
                        'mimeType': part['inlineData']['mimeType'],
                        'data': '<${(part['inlineData']['data'] as String).length} '
                            'base64 chars omitted>',
                      },
                    }
                  else
                    part,
              ],
            }
          else
            message,
      ],
    };
  }

  static pw.Widget _heading(String text) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 4, bottom: 2),
        child: pw.Text('## $text'),
      );

  // One widget per line lets MultiPage break between lines; span overflow
  // lets a single line longer than a page (a long monologue) continue onto
  // the next page instead of aborting the whole render.
  static List<pw.Widget> _paragraphs(String text) => [
        for (final line in text.split('\n'))
          pw.Text(
            line.isEmpty ? ' ' : line,
            softWrap: true,
            overflow: pw.TextOverflow.span,
          ),
      ];
}

/// Works around package:pdf (through 3.13.1) writing ToUnicode entries above
/// U+FFFF as bare code points (`<1F4CD>`) instead of UTF-16 (`<D83DDCCD>`).
/// Extractors, Gemini's included, drop such entries, so every emoji and the
/// 📍/📅/🕰 metadata markers would vanish from the text layer.
class _Utf16CmapFont extends pw.TtfFont {
  _Utf16CmapFont(super.data);

  @override
  PdfFont buildFont(PdfDocument pdfDocument) =>
      _Utf16CmapPdfFont(pdfDocument, data, protect: protect);
}

class _Utf16CmapPdfFont extends PdfTtfFont {
  _Utf16CmapPdfFont(super.pdfDocument, super.bytes, {super.protect});

  // The document prepares objects in creation order, so this font runs
  // before its CMap object. The font's own prepare() subsets glyphs and
  // measures widths with the real code points; only after that are the
  // shared entries packed as surrogate pairs (0xD83DDCCD prints as
  // "D83DDCCD"), which the CMap object then writes verbatim.
  @override
  void prepare() {
    super.prepare();
    final cmap = unicodeCMap.cmap;
    for (var i = 0; i < cmap.length; i++) {
      final codePoint = cmap[i];
      if (codePoint <= 0xFFFF) continue;
      final offset = codePoint - 0x10000;
      cmap[i] = ((0xD800 + (offset >> 10)) << 16) | (0xDC00 + (offset & 0x3FF));
    }
  }
}
