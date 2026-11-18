// Failed AI requests are re-sent automatically, as many times as set for
// the model's provider.

import 'package:flan/l10n/app_localizations.dart';
import 'package:flan/models/chat/chat_model.dart';
import 'package:flan/models/chat/custom_model.dart';
import 'package:flan/models/chat/custom_provider.dart';
import 'package:flan/models/chat/unified_model.dart';
import 'package:flan/models/prompt/prompt_parameters.dart';
import 'package:flan/screens/settings/api_key_screen.dart';
import 'package:flan/services/ai_service.dart';
import 'package:flan/services/provider_retry_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Fails the first [failures] requests, then answers.
class _FlakyAi extends AiService {
  _FlakyAi(this.failures) : super(retryDelay: (_) => Duration.zero);

  final int failures;
  int requests = 0;

  @override
  Future<AiResponse> sendOnce({
    required String systemPrompt,
    required List<Map<String, dynamic>> contents,
    required UnifiedModel model,
    required String apiKey,
    PromptParameters? promptParameters,
    int? chatRoomId,
    int? characterId,
    required String logType,
  }) async {
    requests++;
    if (requests <= failures) throw Exception('HTTP 503');
    return AiResponse(text: 'ok after $requests');
  }
}

Future<AiResponse> _send(AiService ai, UnifiedModel model,
        {void Function(int)? onRetry}) =>
    ai.sendMessage(
      systemPrompt: '',
      contents: const [],
      model: model,
      onRetry: onRetry,
    );

void main() {
  final claude = UnifiedModel.fromChatModel(ChatModel.claudeOpus55);
  final gemini = UnifiedModel.fromChatModel(ChatModel.geminiArgon4);

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'api_key_anthropic': 'key',
      'api_key_google': 'key',
    });
  });

  test('re-sends a failed request up to the provider retry count', () async {
    await ProviderRetrySettings.write('anthropic', 2);
    final retries = <int>[];
    final ai = _FlakyAi(2);

    final response = await _send(ai, claude, onRetry: retries.add);

    expect(response.text, 'ok after 3');
    expect(retries, [1, 2]);
  });

  test('gives up with the last error once the retries run out', () async {
    await ProviderRetrySettings.write('anthropic', 1);
    final ai = _FlakyAi(5);

    await expectLater(_send(ai, claude), throwsA(isA<Exception>()));
    expect(ai.requests, 2);
  });

  test('each provider keeps its own count; the default is no retry',
      () async {
    await ProviderRetrySettings.write('anthropic', 3);
    final ai = _FlakyAi(1);

    await expectLater(_send(ai, gemini), throwsA(isA<Exception>()));
    expect(ai.requests, 1);
    expect(await ProviderRetrySettings.read('google'), 0);
    expect(await AiService.retryCountFor(claude), 3);
  });

  test('custom providers use their own retry count', () async {
    await ProviderRetrySettings.write('openai', 0);
    final custom = UnifiedModel.fromCustomModel(
      CustomModel(
        id: 'm',
        displayName: 'Custom',
        modelId: 'x',
        apiFormat: ApiFormat.openai,
        apiKey: 'key',
        providerId: 'p',
      ),
      provider: CustomProvider(
        id: 'p',
        name: 'P',
        baseUrl: 'https://example.invalid',
        apiFormat: ApiFormat.openai,
        apiKey: 'key',
        retryCount: 2,
      ),
    );
    final ai = _FlakyAi(2);

    expect((await _send(ai, custom)).text, 'ok after 3');
  });

  test('a missing API key fails at once without retrying', () async {
    SharedPreferences.setMockInitialValues({'retry_count_openai': 3});
    final ai = _FlakyAi(0);

    await expectLater(
      _send(ai, UnifiedModel.fromChatModel(ChatModel.gpt6Astra)),
      throwsA(isA<Exception>()),
    );
    expect(ai.requests, 0);
  });

  test('the count is clamped to the allowed range', () async {
    await ProviderRetrySettings.write('google', 99);
    expect(await ProviderRetrySettings.read('google'),
        ProviderRetrySettings.maxRetries);
    await ProviderRetrySettings.write('google', -1);
    expect(await ProviderRetrySettings.read('google'), 0);
  });

  testWidgets('API key screen sets the count per provider', (tester) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ko'),
      home: const ApiKeyScreen(),
    ));
    await tester.pumpAndSettle();

    String shownCount() => tester
        .widget<Text>(find.byKey(const ValueKey('retryCountValue')))
        .data!;

    expect(shownCount(), '0');
    final increase = find.byKey(const ValueKey('retryCountIncrease'));
    await tester.ensureVisible(increase);
    await tester.tap(increase);
    await tester.tap(increase);
    await tester.pumpAndSettle();
    expect(shownCount(), '2');
    expect(await ProviderRetrySettings.read('google'), 2);

    // Another provider tab shows its own count.
    await tester.ensureVisible(find.text('Anthropic'));
    await tester.tap(find.text('Anthropic'));
    await tester.pumpAndSettle();
    expect(shownCount(), '0');
    expect(await ProviderRetrySettings.read('google'), 2);
  });
}
