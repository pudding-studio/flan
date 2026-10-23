/// How a character's emotion image is picked for each AI reply
/// (RisuAI `viewScreen: 'emotion'` with or without `inlayViewScreen`).
enum EmotionMode {
  /// No emotion images.
  none,

  /// After each reply a separate model call picks one emotion name.
  classifier,

  /// The reply itself carries `<Emotion="name">`, shown where it appears.
  inline;

  static EmotionMode fromName(String? value) => EmotionMode.values.firstWhere(
        (mode) => mode.name == value,
        orElse: () => EmotionMode.none,
      );

  /// RisuAI's default instruction for each mode; `{{slot}}` is the
  /// comma-separated emotion list.
  String get defaultInstructions => switch (this) {
        EmotionMode.inline =>
          'You must always output the character\'s emotional image as a command at the end of a conversation. The command must be selected from a given list, and it\'s better to have variety than to repeat images used in previous chats. Use one image, depending on the character\'s emotion. See the list below. Form: <Emotion="<image command>"> Example: <Emotion="Agree"> List of commands: {{slot}}',
        _ =>
          'From the list below, choose a word that best represents a character\'s outfit description, action, or emotion in their dialogue. Prioritize selecting words related to outfit first, then action, and lastly emotion. Print out the chosen word.',
      };
}
