import 'package:flutter/material.dart';

class MarkdownText extends StatelessWidget {
  final String text;
  final TextStyle? baseStyle;
  final TextAlign textAlign;
  final double paragraphSpacing;

  const MarkdownText({
    super.key,
    required this.text,
    this.baseStyle,
    this.textAlign = TextAlign.left,
    this.paragraphSpacing = 0,
  });

  @override
  Widget build(BuildContext context) {
    final style = baseStyle ?? Theme.of(context).textTheme.bodyMedium ?? const TextStyle();
    final primaryColor = Theme.of(context).colorScheme.primary;
    final tertiaryColor = Theme.of(context).colorScheme.tertiary;

    if (paragraphSpacing <= 0) {
      final spans = _parse(text, style, primaryColor, tertiaryColor);
      return RichText(
        textAlign: textAlign,
        text: TextSpan(children: spans),
      );
    }

    final paragraphs = text.split('\n');
    return Column(
      crossAxisAlignment: textAlign == TextAlign.left
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < paragraphs.length; i++) ...[
          if (i > 0) SizedBox(height: paragraphSpacing),
          RichText(
            textAlign: textAlign,
            text: TextSpan(
              children: _parse(paragraphs[i], style, primaryColor, tertiaryColor),
            ),
          ),
        ],
      ],
    );
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
