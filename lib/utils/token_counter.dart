import '../providers/tokenizer_provider.dart';

class TokenCounter {
  /// 토크나이저 타입에 따른 토큰 수 추정
  /// 각 토크나이저마다 다른 추정 방식 사용
  static int estimateTokenCount(String text, {TokenizerType? tokenizer}) {
    if (text.isEmpty) return 0;

    tokenizer ??= TokenizerType.o200kBase;

    switch (tokenizer) {
      case TokenizerType.o200kBase:
        return _estimateO200kBase(text);
      case TokenizerType.o100kBase:
        return _estimateO100kBase(text);
      case TokenizerType.cl100kBase:
        return _estimateCl100kBase(text);
      case TokenizerType.p50kBase:
        return _estimateP50kBase(text);
    }
  }

  /// o200k_base (GPT-4o) 토크나이저 추정
  /// 더 효율적인 토크나이저로 토큰 수가 적음
  static int _estimateO200kBase(String text) {
    int totalChars = text.length;
    int nonAsciiChars = text.replaceAll(RegExp(r'[\x00-\x7F]'), '').length;
    int asciiChars = totalChars - nonAsciiChars;

    // o200k_base는 더 효율적: 영문 ~4.5자/토큰, 한글 ~1.5자/토큰
    int asciiTokens = (asciiChars / 4.5).ceil();
    int nonAsciiTokens = (nonAsciiChars / 1.5).ceil();

    return asciiTokens + nonAsciiTokens;
  }

  /// o100k_base (GPT-4) 토크나이저 추정
  static int _estimateO100kBase(String text) {
    int totalChars = text.length;
    int nonAsciiChars = text.replaceAll(RegExp(r'[\x00-\x7F]'), '').length;
    int asciiChars = totalChars - nonAsciiChars;

    // o100k_base: 영문 ~4자/토큰, 한글 ~1.3자/토큰
    int asciiTokens = (asciiChars / 4).ceil();
    int nonAsciiTokens = (nonAsciiChars / 1.3).ceil();

    return asciiTokens + nonAsciiTokens;
  }

  /// cl100k_base (GPT-3.5-turbo) 토크나이저 추정
  static int _estimateCl100kBase(String text) {
    int totalChars = text.length;
    int nonAsciiChars = text.replaceAll(RegExp(r'[\x00-\x7F]'), '').length;
    int asciiChars = totalChars - nonAsciiChars;

    // cl100k_base: 영문 ~4자/토큰, 한글 ~1.2자/토큰
    int asciiTokens = (asciiChars / 4).ceil();
    int nonAsciiTokens = (nonAsciiChars / 1.2).ceil();

    return asciiTokens + nonAsciiTokens;
  }

  /// p50k_base (GPT-3) 토크나이저 추정
  static int _estimateP50kBase(String text) {
    int totalChars = text.length;
    int nonAsciiChars = text.replaceAll(RegExp(r'[\x00-\x7F]'), '').length;
    int asciiChars = totalChars - nonAsciiChars;

    // p50k_base: 영문 ~4자/토큰, 한글 ~1자/토큰 (가장 비효율적)
    int asciiTokens = (asciiChars / 4).ceil();
    int nonAsciiTokens = nonAsciiChars;

    return asciiTokens + nonAsciiTokens;
  }

  static String formatTokenCount(int count) {
    return count.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}
