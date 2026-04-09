import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'fullscreen_image_viewer.dart';

// Regex to match markdown image syntax: ![alt](url)
final _imagePattern = RegExp(r'!\[([^\]]*)\]\(([^)]+)\)');

class MarkdownText extends StatelessWidget {
  final String text;
  final TextStyle? baseStyle;
  final TextAlign textAlign;
  final double paragraphSpacing;
  final String? highlightQuery;
  final Color? highlightColor;
  final Color? currentHighlightColor;
  final int currentOccurrence;
  final GlobalKey? highlightKey;

  const MarkdownText({
    super.key,
    required this.text,
    this.baseStyle,
    this.textAlign = TextAlign.left,
    this.paragraphSpacing = 0,
    this.highlightQuery,
    this.highlightColor,
    this.currentHighlightColor,
    this.currentOccurrence = -1,
    this.highlightKey,
  });

  @override
  Widget build(BuildContext context) {
    final style = baseStyle ?? Theme.of(context).textTheme.bodyMedium ?? const TextStyle();
    final primaryColor = Theme.of(context).colorScheme.primary;
    final tertiaryColor = Theme.of(context).colorScheme.tertiary;

    // Split text into segments: plain text and image references
    final segments = _splitByImages(text);

    if (segments.length == 1 && segments.first.type == _SegmentType.text) {
      // No images — use original rendering path
      return _buildTextContent(segments.first.value, style, primaryColor, tertiaryColor);
    }

    // Mixed content: text and images
    return Column(
      crossAxisAlignment: textAlign == TextAlign.left
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < segments.length; i++) ...[
          if (segments[i].type == _SegmentType.text)
            _buildTextContent(segments[i].value, style, primaryColor, tertiaryColor)
          else
            _ImageBlock(
              url: segments[i].value,
              alt: segments[i].alt,
            ),
          if (i < segments.length - 1 && paragraphSpacing > 0)
            SizedBox(height: paragraphSpacing),
        ],
      ],
    );
  }

  /// Returns (highlighted spans, number of occurrences consumed).
  /// [occOffset] is the occurrence index of the first match in this batch.
  (List<InlineSpan>, int) _withHighlight(List<InlineSpan> spans, int occOffset) {
    final query = highlightQuery;
    final color = highlightColor;
    if (query == null || query.isEmpty || color == null) return (spans, 0);

    final lowerQuery = query.toLowerCase();
    final result = <InlineSpan>[];
    int occCount = 0;

    for (final span in spans) {
      if (span is TextSpan && span.text != null && span.children == null) {
        final text = span.text!;
        final lowerText = text.toLowerCase();
        int start = 0;

        while (true) {
          final matchIndex = lowerText.indexOf(lowerQuery, start);
          if (matchIndex == -1) {
            if (start < text.length) {
              result.add(TextSpan(text: text.substring(start), style: span.style));
            }
            break;
          }
          if (matchIndex > start) {
            result.add(TextSpan(text: text.substring(start, matchIndex), style: span.style));
          }
          final isCurrent = (occOffset + occCount) == currentOccurrence;
          final bgColor = isCurrent ? (currentHighlightColor ?? color) : color;
          result.add(TextSpan(
            text: text.substring(matchIndex, matchIndex + query.length),
            style: (span.style ?? const TextStyle()).copyWith(
              backgroundColor: bgColor,
              decoration: isCurrent ? TextDecoration.underline : null,
              decorationColor: isCurrent ? bgColor : null,
              decorationThickness: isCurrent ? 2.5 : null,
            ),
          ));
          occCount++;
          start = matchIndex + query.length;
        }
      } else {
        result.add(span);
      }
    }

    return (result, occCount);
  }

  Widget _buildTextContent(
    String content,
    TextStyle style,
    Color primaryColor,
    Color tertiaryColor,
  ) {
    // Always split by newlines when search key is active,
    // so the key lands on the exact matching line.
    final paragraphs = content.split('\n');
    if (paragraphs.length <= 1 && highlightKey == null) {
      final (spans, _) = _withHighlight(_parse(content, style, primaryColor, tertiaryColor), 0);
      return RichText(
        textAlign: textAlign,
        text: TextSpan(children: spans),
      );
    }

    bool keyAssigned = false;
    int occOffset = 0;
    final widgets = <Widget>[];
    for (int i = 0; i < paragraphs.length; i++) {
      if (i > 0 && paragraphSpacing > 0) widgets.add(SizedBox(height: paragraphSpacing));
      final (spans, count) = _withHighlight(
        _parse(paragraphs[i], style, primaryColor, tertiaryColor), occOffset,
      );
      // Attach key to the paragraph containing the current occurrence
      final hasCurrentOcc = highlightKey != null &&
          !keyAssigned &&
          currentOccurrence >= 0 &&
          currentOccurrence >= occOffset &&
          currentOccurrence < occOffset + count;
      if (hasCurrentOcc) keyAssigned = true;
      widgets.add(RichText(
        key: hasCurrentOcc ? highlightKey : null,
        textAlign: textAlign,
        text: TextSpan(children: spans),
      ));
      occOffset += count;
    }
    return Column(
      crossAxisAlignment: textAlign == TextAlign.left
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.stretch,
      children: widgets,
    );
  }

  static List<_Segment> _splitByImages(String text) {
    final segments = <_Segment>[];
    int lastEnd = 0;

    for (final match in _imagePattern.allMatches(text)) {
      if (match.start > lastEnd) {
        final before = text.substring(lastEnd, match.start).trim();
        if (before.isNotEmpty) {
          segments.add(_Segment(_SegmentType.text, before));
        }
      }
      segments.add(_Segment(
        _SegmentType.image,
        match.group(2)!, // url
        alt: match.group(1), // alt text
      ));
      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      final remaining = text.substring(lastEnd).trim();
      if (remaining.isNotEmpty) {
        segments.add(_Segment(_SegmentType.text, remaining));
      }
    }

    if (segments.isEmpty) {
      segments.add(_Segment(_SegmentType.text, text));
    }

    return segments;
  }

  static List<InlineSpan> _parse(
    String text,
    TextStyle base,
    Color primaryColor,
    Color tertiaryColor,
  ) {
    final spans = <InlineSpan>[];
    final buffer = StringBuffer();
    int i = 0;

    void flushBuffer() {
      if (buffer.isNotEmpty) {
        spans.add(TextSpan(text: buffer.toString(), style: base));
        buffer.clear();
      }
    }

    while (i < text.length) {
      // 1. "text" → primary + bold (최우선, 내부 ' ** * 중첩 지원)
      if (text[i] == '"') {
        final end = text.indexOf('"', i + 1);
        if (end != -1) {
          flushBuffer();
          final quoteStyle = base.copyWith(color: primaryColor, fontWeight: FontWeight.bold);
          spans.add(TextSpan(text: '"', style: quoteStyle));
          final inner = text.substring(i + 1, end);
          spans.addAll(_parseInner(inner, quoteStyle, tertiaryColor));
          spans.add(TextSpan(text: '"', style: quoteStyle));
          i = end + 1;
          continue;
        }
      }

      // 2. 'text' → tertiary + bold (내부 ** * 중첩 지원)
      if (text[i] == "'") {
        final end = text.indexOf("'", i + 1);
        if (end != -1) {
          flushBuffer();
          final quoteStyle = base.copyWith(color: tertiaryColor, fontWeight: FontWeight.bold);
          spans.add(TextSpan(text: "'", style: quoteStyle));
          final inner = text.substring(i + 1, end);
          spans.addAll(_parseInner(inner, quoteStyle, tertiaryColor));
          spans.add(TextSpan(text: "'", style: quoteStyle));
          i = end + 1;
          continue;
        }
      }

      // 3. **text** → 기본 색상 + bold
      if (i + 1 < text.length && text[i] == '*' && text[i + 1] == '*') {
        final end = text.indexOf('**', i + 2);
        if (end != -1) {
          flushBuffer();
          final inner = text.substring(i + 2, end);
          spans.add(TextSpan(
            text: inner,
            style: base.copyWith(fontWeight: FontWeight.bold),
          ));
          i = end + 2;
          continue;
        }
      }

      // 4. *text* → tertiary + bold
      if (text[i] == '*' && !(i + 1 < text.length && text[i + 1] == '*')) {
        final end = _findSingleStar(text, i + 1);
        if (end != -1) {
          flushBuffer();
          final inner = text.substring(i + 1, end);
          spans.add(TextSpan(
            text: inner,
            style: base.copyWith(color: tertiaryColor, fontWeight: FontWeight.bold),
          ));
          i = end + 1;
          continue;
        }
      }

      buffer.write(text[i]);
      i++;
    }

    flushBuffer();
    return spans;
  }

  static List<InlineSpan> _parseInner(
    String text,
    TextStyle parentStyle,
    Color tertiaryColor,
  ) {
    final spans = <InlineSpan>[];
    final buffer = StringBuffer();
    int i = 0;

    void flushBuffer() {
      if (buffer.isNotEmpty) {
        spans.add(TextSpan(text: buffer.toString(), style: parentStyle));
        buffer.clear();
      }
    }

    while (i < text.length) {
      // 'text' → tertiary + bold
      if (text[i] == "'") {
        final end = text.indexOf("'", i + 1);
        if (end != -1) {
          flushBuffer();
          final quoteStyle = parentStyle.copyWith(color: tertiaryColor, fontWeight: FontWeight.bold);
          spans.add(TextSpan(text: "'", style: quoteStyle));
          final inner = text.substring(i + 1, end);
          spans.add(TextSpan(text: inner, style: quoteStyle));
          spans.add(TextSpan(text: "'", style: quoteStyle));
          i = end + 1;
          continue;
        }
      }

      // **text** → 기본 색상 + bold
      if (i + 1 < text.length && text[i] == '*' && text[i + 1] == '*') {
        final end = text.indexOf('**', i + 2);
        if (end != -1) {
          flushBuffer();
          final inner = text.substring(i + 2, end);
          spans.add(TextSpan(
            text: inner,
            style: parentStyle.copyWith(fontWeight: FontWeight.bold),
          ));
          i = end + 2;
          continue;
        }
      }

      // *text* → tertiary + bold
      if (text[i] == '*' && !(i + 1 < text.length && text[i + 1] == '*')) {
        final end = _findSingleStar(text, i + 1);
        if (end != -1) {
          flushBuffer();
          final inner = text.substring(i + 1, end);
          spans.add(TextSpan(
            text: inner,
            style: parentStyle.copyWith(color: tertiaryColor, fontWeight: FontWeight.bold),
          ));
          i = end + 1;
          continue;
        }
      }

      buffer.write(text[i]);
      i++;
    }

    flushBuffer();
    return spans;
  }

  static int _findSingleStar(String text, int start) {
    for (int i = start; i < text.length; i++) {
      if (text[i] == '*' && i + 1 < text.length && text[i + 1] == '*') {
        return -1;
      }
      if (text[i] == '*') {
        return i;
      }
    }
    return -1;
  }
}

enum _SegmentType { text, image }

class _Segment {
  final _SegmentType type;
  final String value;
  final String? alt;

  _Segment(this.type, this.value, {this.alt});
}

class _ImageBlock extends StatelessWidget {
  final String url;
  final String? alt;

  const _ImageBlock({required this.url, this.alt});

  bool get _isLocalFile =>
      url.startsWith('/') || url.startsWith('file://');

  String get _filePath =>
      url.startsWith('file://') ? url.substring(7) : url;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: SizedBox(
          width: screenWidth * 0.7,
          child: GestureDetector(
            onTap: () => FullscreenImageViewer.show(context, url),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: _isLocalFile
                    ? Image.file(
                        File(_filePath),
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => _errorWidget(context),
                      )
                    : CachedNetworkImage(
                        imageUrl: url,
                        fit: BoxFit.contain,
                        placeholder: (context, url) => Container(
                          height: 150,
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        ),
                        errorWidget: (context, url, error) => _errorWidget(context),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _errorWidget(BuildContext context) {
    return Container(
      height: 80,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.broken_image,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
            if (alt != null && alt!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  alt!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
