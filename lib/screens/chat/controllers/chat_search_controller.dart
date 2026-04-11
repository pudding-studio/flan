import 'package:flutter/widgets.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../../../models/chat/chat_message.dart';
import '../../../utils/chat_content_formatter.dart';

/// Owns the in-conversation message search state for the chat room.
///
/// Holds the search input controller, focus node, the list of `(message
/// index, occurrence index)` matches, the active match cursor, and the
/// glyph-key used to drive scroll-into-view animations.
///
/// The host injects two callbacks at construction time so the controller
/// stays decoupled from any specific State:
///   - [messagesProvider]: returns the current message list each time a
///     search runs.
///   - [displayContentBuilder]: turns a stored message body into the same
///     visible text [MarkdownText] would render, so search hits line up
///     exactly with what the user sees.
///
/// Listeners are notified on toggle, query change, navigation, and on the
/// short-lived `highlightKeyActive` toggling that drives one
/// `Scrollable.ensureVisible` pass.
class ChatSearchController extends ChangeNotifier {
  final List<ChatMessage> Function() messagesProvider;
  final String Function(String content) displayContentBuilder;
  final ItemScrollController itemScrollController;
  final ItemPositionsListener itemPositionsListener;

  ChatSearchController({
    required this.messagesProvider,
    required this.displayContentBuilder,
    required this.itemScrollController,
    required this.itemPositionsListener,
  });

  final TextEditingController inputController = TextEditingController();
  final FocusNode focusNode = FocusNode();

  bool _isSearching = false;
  // Each entry: (messageIndex, occurrenceIndex within that message)
  List<(int msgIdx, int occIdx)> _matches = [];
  int _currentIndex = -1;
  GlobalKey _highlightKey = GlobalKey();
  bool _highlightKeyActive = false;

  bool get isSearching => _isSearching;
  List<(int msgIdx, int occIdx)> get matches => _matches;
  int get currentIndex => _currentIndex;
  GlobalKey? get highlightKey => _highlightKeyActive ? _highlightKey : null;

  bool isMatchedMessage(int messageIndex) =>
      _matches.any((m) => m.$1 == messageIndex);

  /// Returns the active occurrence within the given message, or `-1` if
  /// the active match is not in this message.
  int currentOccurrenceIn(int messageIndex) {
    if (_currentIndex < 0) return -1;
    final current = _matches[_currentIndex];
    return current.$1 == messageIndex ? current.$2 : -1;
  }

  bool isCurrentMessage(int messageIndex) {
    if (_currentIndex < 0) return false;
    return _matches[_currentIndex].$1 == messageIndex;
  }

  void toggle() {
    _isSearching = !_isSearching;
    if (!_isSearching) {
      inputController.clear();
      _matches = [];
      _currentIndex = -1;
    } else {
      focusNode.requestFocus();
    }
    notifyListeners();
  }

  void search(String query) {
    if (query.isEmpty) {
      _matches = [];
      _currentIndex = -1;
      notifyListeners();
      return;
    }

    final lowerQuery = query.toLowerCase();
    final messages = messagesProvider();
    final matches = <(int, int)>[];
    for (int i = 0; i < messages.length; i++) {
      // Strip image markdown so search results align with rendered text.
      var displayText = displayContentBuilder(messages[i].content);
      displayText =
          displayText.replaceAll(ChatContentFormatter.imageMarkdownPattern, '');
      final lowerContent = displayText.toLowerCase();
      int start = 0;
      int occIdx = 0;
      while (true) {
        final pos = lowerContent.indexOf(lowerQuery, start);
        if (pos == -1) break;
        matches.add((i, occIdx));
        occIdx++;
        start = pos + lowerQuery.length;
      }
    }

    _matches = matches;
    _currentIndex = matches.isNotEmpty ? 0 : -1;
    notifyListeners();

    if (matches.isNotEmpty) {
      _scrollToResult(0);
    }
  }

  void navigate(int direction) {
    if (_matches.isEmpty) return;
    var next = (_currentIndex + direction) % _matches.length;
    if (next < 0) next = _matches.length - 1;
    _currentIndex = next;
    notifyListeners();
    _scrollToResult(_currentIndex);
  }

  void _scrollToResult(int searchIndex) {
    final (messageIndex, _) = _matches[searchIndex];
    final messages = messagesProvider();
    final listIndex = messages.length - 1 - messageIndex;

    void ensureVisible() {
      _highlightKey = GlobalKey();
      _highlightKeyActive = true;
      notifyListeners();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _highlightKey.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            alignment: 0.0,
          ).then((_) {
            _highlightKeyActive = false;
            notifyListeners();
          });
        } else {
          _highlightKeyActive = false;
          notifyListeners();
        }
      });
    }

    final positions = itemPositionsListener.itemPositions.value;
    final isOnScreen = positions.any((p) => p.index == listIndex);

    if (isOnScreen) {
      ensureVisible();
    } else {
      itemScrollController.jumpTo(index: listIndex, alignment: 0.5);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ensureVisible();
      });
    }
  }

  @override
  void dispose() {
    inputController.dispose();
    focusNode.dispose();
    super.dispose();
  }
}
