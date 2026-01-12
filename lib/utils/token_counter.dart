class TokenCounter {
  static int estimateTokenCount(String text) {
    if (text.isEmpty) return 0;

    int totalChars = text.length;
    int englishChars = text.replaceAll(RegExp(r'[a-zA-Z0-9\s]'), '').length;
    int koreanChars = totalChars - englishChars;

    int englishTokens = (englishChars / 4).ceil();
    int koreanTokens = (koreanChars / 2).ceil();

    return englishTokens + koreanTokens;
  }

  static String formatTokenCount(int count) {
    return count.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}
