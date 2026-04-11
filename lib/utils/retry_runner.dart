import 'package:flutter/foundation.dart';

/// Tiny helper that runs an async [attempt] up to `maxRetries + 1` times,
/// stopping on the first success and rethrowing the last error otherwise.
///
/// Used by chat send paths so each retry loop reads as a single
/// `RetryRunner.run(...)` call instead of repeating the same try/catch
/// boilerplate. The [onRetry] callback (if any) is invoked at the start
/// of every attempt **after** the first, so the host can update phase
/// state ("retry 1/3") before the request goes out.
class RetryRunner {
  static Future<T> run<T>({
    required int maxRetries,
    required String tag,
    required Future<T> Function(int attempt) attempt,
    void Function(int attempt)? onRetry,
  }) async {
    Object? lastError;
    for (int i = 0; i <= maxRetries; i++) {
      try {
        if (i > 0) {
          debugPrint('Retrying $tag (attempt ${i + 1}/${maxRetries + 1})');
          onRetry?.call(i);
        }
        return await attempt(i);
      } catch (e) {
        lastError = e;
        debugPrint('$tag attempt ${i + 1} failed: $e');
        if (i >= maxRetries) break;
      }
    }
    throw lastError!;
  }
}
