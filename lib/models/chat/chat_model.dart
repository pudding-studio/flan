enum ChatModelProvider {
  all('ALL'),
  googleAIStudio('Google AIstudio');

  final String displayName;
  const ChatModelProvider(this.displayName);
}

enum ChatModel {
  geminiPro3Preview(
    'Gemini 3 Pro Preview',
    ChatModelProvider.googleAIStudio,
    'gemini-3-pro-preview',
  ),
  geminiFlash3Preview(
    'Gemini 3 Flash Preview',
    ChatModelProvider.googleAIStudio,
    'gemini-3-flash-preview',
  ),
  geminiPro25(
    'Gemini 2.5 Pro',
    ChatModelProvider.googleAIStudio,
    'gemini-2.5-pro',
  ),
  geminiFlash25(
    'Gemini 2.5 Flash',
    ChatModelProvider.googleAIStudio,
    'gemini-2.5-flash',
  ),
  geminiFlashLite25(
    'Gemini 2.5 Flash Lite',
    ChatModelProvider.googleAIStudio,
    'gemini-2.5-flash-lite',
  );

  final String displayName;
  final ChatModelProvider provider;
  final String modelId;

  const ChatModel(this.displayName, this.provider, this.modelId);

  static List<ChatModel> getModelsByProvider(ChatModelProvider provider) {
    if (provider == ChatModelProvider.all) {
      return ChatModel.values;
    }
    return ChatModel.values
        .where((model) => model.provider == provider)
        .toList();
  }
}
