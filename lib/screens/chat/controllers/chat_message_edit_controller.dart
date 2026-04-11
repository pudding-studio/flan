import 'package:flutter/widgets.dart';
import '../../../models/chat/chat_message.dart';

/// Owns the bookkeeping for in-place message editing in the chat room.
///
/// Tracks which message is currently being edited, holds a
/// [TextEditingController] per message, and disposes them when the host
/// state is torn down. The actual save logic stays in the host because
/// it touches the database, the tokenizer, and the chat-data reload.
class ChatMessageEditController {
  final VoidCallback _onChanged;

  ChatMessageEditController({required VoidCallback onChanged})
      : _onChanged = onChanged;

  int? _editingMessageId;
  final Map<int, TextEditingController> _controllers = {};

  int? get editingMessageId => _editingMessageId;

  bool isEditing(ChatMessage message) =>
      message.id != null && _editingMessageId == message.id;

  TextEditingController? controllerFor(ChatMessage message) =>
      message.id == null ? null : _controllers[message.id];

  /// Begin editing [message]. Creates a fresh [TextEditingController]
  /// pre-filled with the current message body and notifies listeners
  /// so the host can rebuild.
  void start(ChatMessage message) {
    if (message.id == null) return;
    _editingMessageId = message.id;
    _controllers[message.id!] = TextEditingController(text: message.content);
    _onChanged();
  }

  /// Cancel the current edit, dispose its controller, and notify.
  /// Safe to call when nothing is being edited.
  void cancel() {
    if (_editingMessageId == null) return;
    _controllers[_editingMessageId]?.dispose();
    _controllers.remove(_editingMessageId);
    _editingMessageId = null;
    _onChanged();
  }

  /// Returns the trimmed text from the active edit controller for
  /// [message], or `null` if there is no active controller.
  String? trimmedTextFor(ChatMessage message) {
    final controller = _controllers[message.id];
    if (controller == null) return null;
    return controller.text.trim();
  }

  /// Dispose every outstanding edit controller. Call from the host's
  /// `dispose()`.
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _controllers.clear();
    _editingMessageId = null;
  }
}
