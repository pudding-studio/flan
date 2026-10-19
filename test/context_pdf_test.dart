import 'dart:convert';
import 'dart:typed_data';

import 'package:flan/models/character/character.dart';
import 'package:flan/models/character/persona.dart';
import 'package:flan/models/chat/chat_message.dart';
import 'package:flan/models/prompt/chat_prompt.dart';
import 'package:flan/models/prompt/prompt_item.dart';
import 'package:flan/services/context_pdf_service.dart';
import 'package:flan/utils/context_pdf.dart';
import 'package:flan/utils/prompt_builder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final character = Character(name: '루나');
  final persona = Persona(characterId: 1, name: '지민', order: 0);
  final chatItem = PromptItem(role: PromptRole.chat, content: '', order: 1);
  final prompt = ChatPrompt(name: 'test', items: [
    PromptItem(role: PromptRole.system, content: 'You are {{char}}.'),
    chatItem,
    PromptItem(
      role: PromptRole.user,
      content: 'Summary: {{chat_historys}}',
      order: 2,
    ),
  ]);
  final history = [
    ChatMessage(chatRoomId: 1, role: MessageRole.user, content: '안녕 📍'),
    ChatMessage(chatRoomId: 1, role: MessageRole.assistant, content: '반가워'),
  ];

  List<Map<String, dynamic>> build({
    List<ContextPdfEntry>? sink,
    Map<String, String>? extraKeywords,
  }) {
    return PromptBuilder.buildContents(
      chatPrompt: prompt,
      character: character,
      persona: persona,
      userMessage: '지금 메시지',
      chatHistoryMap: {chatItem: history},
      systemPrompt: '',
      pdfHistorySink: sink,
      extraKeywords: extraKeywords,
    );
  }

  test('text mode keeps history as alternating turns', () {
    final contents = build();

    expect(contents.map((c) => c['role']), ['user', 'model', 'user']);
    expect(ContextPdf.containsPdf(contents), isFalse);
  });

  test('pdf mode collects history and leaves one placeholder in its slot', () {
    final sink = <ContextPdfEntry>[];
    final contents = build(
      sink: sink,
      extraKeywords: {'chat_historys': ContextPdf.summaryPointer},
    );

    expect(
      sink.map((e) => '${e.speaker}: ${e.text}'),
      ['지민: 안녕 📍', '루나: 반가워'],
    );
    expect(contents, hasLength(1));
    final parts = contents.single['parts'] as List;
    expect(ContextPdf.isPlaceholder(parts.first), isTrue);
    expect(
      parts.skip(1).map((p) => p['text']),
      ['Summary: ${ContextPdf.summaryPointer}\n지금 메시지'],
    );
  });

  test('attach swaps the placeholder for the PDF; the log copy drops it', () {
    final pdf = Uint8List.fromList(utf8.encode('%PDF-test'));
    final attached = ContextPdf.attach(build(sink: <ContextPdfEntry>[]), pdf);

    final parts = attached.single['parts'] as List;
    expect(parts[0]['inlineData']['mimeType'], ContextPdf.mimeType);
    expect(parts[0]['inlineData']['data'], base64Encode(pdf));
    expect(parts[1]['text'], ContextPdf.attachmentNote);
    expect(parts.any(ContextPdf.isPlaceholder), isFalse);
    expect(ContextPdf.containsPdf(attached), isTrue);

    final logged = jsonEncode(ContextPdf.redactForLog({'contents': attached}));
    expect(logged, isNot(contains(base64Encode(pdf))));
    expect(logged, contains('base64 chars omitted'));
  });

  test('renders a PDF from the bundled fonts off the UI isolate', () async {
    final bytes = await ContextPdfService.render(
      summary: '요약 📅',
      entries: const [ContextPdfEntry('루나', '飲み物を温めた 🕰')],
    );

    expect(latin1.decode(bytes.sublist(0, 5)), '%PDF-');
  });
}
