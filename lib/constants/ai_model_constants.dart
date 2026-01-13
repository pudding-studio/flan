class AIModelConstants {
  static const String all = 'ALL';
  static const String gpt4 = 'GPT-4';
  static const String gpt35 = 'GPT-3.5';
  static const String claude = 'Claude';
  static const String geminiPro = 'Gemini Pro';

  static const List<String> supportedModels = [
    all,
    gpt4,
    gpt35,
    claude,
    geminiPro,
  ];

  static String getDisplayName(String model) {
    return model;
  }

  AIModelConstants._();
}
