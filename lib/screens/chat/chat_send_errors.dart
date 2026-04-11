/// Thrown when a model required for sending could not be resolved from
/// its saved identifier — e.g. the user's saved primary/sub model was
/// deleted, or the chat room's per-room custom model id no longer maps
/// to an available model.
///
/// Caught by the send paths to show a clear, localized error instead of
/// silently falling back to a default model.
class ChatModelLoadException implements Exception {
  final String localizedMessage;
  ChatModelLoadException(this.localizedMessage);
  @override
  String toString() => localizedMessage;
}

/// Thrown when [ChatRoom.selectedChatPromptId] points to a chat prompt
/// row that no longer exists. Distinct from the user explicitly choosing
/// "없음" (which is represented as `selectedChatPromptId == null`).
class ChatPromptLoadException implements Exception {
  final String localizedMessage;
  ChatPromptLoadException(this.localizedMessage);
  @override
  String toString() => localizedMessage;
}
