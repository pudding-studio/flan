import '../models/chat/chat_room.dart';
import '../models/prompt/prompt_regex_rule.dart';
import 'metadata_parser.dart';
import 'regex_processor.dart';

/// Pure transformation helpers for chat message content rendering.
///
/// Used by both message bubbles (display rendering) and search/edit
/// controllers, so it lives outside any widget state.
class ChatContentFormatter {
  static final RegExp imageMarkdownPattern = RegExp(r'!\[[^\]]*\]\([^)]+\)');
  static final RegExp _imgTagPattern = RegExp(r'<img="([^"]+)">');
  static final RegExp _imageExtPattern =
      RegExp(r'\.(png|jpe?g|gif|webp|bmp|heic|avif)$', caseSensitive: false);

  static String _stripImageExt(String name) =>
      name.replaceFirst(_imageExtPattern, '');

  /// Convert a stored message body into the text the user actually sees.
  ///
  /// Strips metadata tags, applies display-time regex rules, and rewrites
  /// `<img="name">` placeholders to local-image markdown when the matching
  /// character image exists. When the chat room has images disabled, all
  /// image markdown is removed entirely.
  static String buildDisplayContent({
    required String content,
    required ChatRoom? chatRoom,
    required List<PromptRegexRule> regexRules,
    required Map<String, String> imagePathMap,
  }) {
    var text = MetadataParser.removeMetadataTags(content);
    text = RegexProcessor.apply(text, regexRules, RegexTarget.displayModify);
    text = text.replaceAllMapped(_imgTagPattern, (match) {
      if (chatRoom?.showImages == false) return '';
      final name = match.group(1)!;
      final path = imagePathMap[name] ?? imagePathMap[_stripImageExt(name)];
      if (path != null) {
        return '![$name]($path)';
      }
      return '';
    });
    if (chatRoom?.showImages == false) {
      text = text.replaceAll(imageMarkdownPattern, '');
    }
    return text;
  }
}
