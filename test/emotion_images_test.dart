// RisuAI-compatible emotion images: picking, display and card import/export.

import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flan/models/character/character.dart';
import 'package:flan/models/character/emotion_mode.dart';
import 'package:flan/models/chat/chat_room.dart';
import 'package:flan/utils/cbs/cbs_context.dart';
import 'package:flan/utils/character_card_parser.dart';
import 'package:flan/utils/chat_content_formatter.dart';
import 'package:flan/utils/emotion_picker.dart';
import 'package:flan/utils/prompt_builder.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

final Uint8List _png =
    Uint8List.fromList(img.encodePng(img.Image(width: 2, height: 2)));

/// A PNG with extra tEXt chunks, as RisuAI writes `chara-ext-asset_:<n>`.
Uint8List _pngWithTextChunks(Map<String, String> chunks) {
  final out = BytesBuilder()..add(_png.sublist(0, _png.length - 12));
  for (final entry in chunks.entries) {
    final data = [...latin1.encode(entry.key), 0, ...latin1.encode(entry.value)];
    out
      ..add((ByteData(4)..setUint32(0, data.length)).buffer.asUint8List())
      ..add(latin1.encode('tEXt'))
      ..add(data)
      ..add(Uint8List(4)); // CRC is not checked by the reader.
  }
  out.add(_png.sublist(_png.length - 12));
  return out.toBytes();
}

ChatRoom _room({bool showImages = true}) =>
    ChatRoom(characterId: 1, name: 'room', showImages: showImages);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory storage;
  setUpAll(() {
    storage = Directory.systemTemp.createTempSync('flan_emotion_test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => storage.path,
    );
  });
  tearDownAll(() => storage.deleteSync(recursive: true));

  group('classifier', () {
    const emotions = ['Happy', 'sad', 'neutral'];

    test('matches like RisuAI: exact, then contained, then neutral', () {
      expect(EmotionPicker.matchClassifierOutput(' happy\n', emotions), 'Happy');
      expect(EmotionPicker.matchClassifierOutput('verysad.', emotions), 'sad');
      expect(EmotionPicker.matchClassifierOutput('angry', emotions), 'neutral');
      expect(EmotionPicker.matchClassifierOutput('angry', ['sad']), isNull);
    });

    test('sends the RisuAI prompt with one example', () {
      final request = EmotionPicker.classifierRequest(
        instructions: EmotionMode.classifier.defaultInstructions,
        emotions: emotions,
        reply: 'I am so glad!',
        recent: ['sad', 'gone'],
        random: Random(1),
      );
      expect(request.systemPrompt,
          startsWith(EmotionMode.classifier.defaultInstructions));
      expect(request.systemPrompt, contains('output only one word.'));
      for (final emotion in emotions) {
        expect(request.systemPrompt, contains(emotion));
      }
      expect(request.systemPrompt, contains('Recently used: sad.'));
      expect(
        [for (final c in request.contents) (c['role'], c['parts'][0]['text'])],
        [
          ('user', EmotionPicker.exampleReply),
          ('model', 'happy'),
          ('user', 'I am so glad!'),
        ],
      );
    });

    test('inline instruction lists the emotions', () {
      expect(
        EmotionPicker.inlineInstruction(
            EmotionMode.inline.defaultInstructions, emotions),
        endsWith('List of commands: Happy, sad, neutral'),
      );
    });
  });

  group('display', () {
    String show(String content, {String? emotion, bool showImages = true}) =>
        ChatContentFormatter.buildDisplayContent(
          content: content,
          chatRoom: _room(showImages: showImages),
          regexRules: const [],
          imagePathMap: const {},
          emotionImageMap: const {'happy': '/img/happy.png'},
          emotion: emotion,
        );

    test('inline tags become the image where they stand', () {
      expect(show('Hi! <Emotion="Happy">'), 'Hi! ![Happy](/img/happy.png)');
      expect(show('{{emotion::happy}}'), '![happy](/img/happy.png)');
      expect(show('Hi <Emotion="unknown">'), 'Hi ');
    });

    test('the picked emotion goes above the reply', () {
      expect(show('Hi', emotion: 'happy'), '![happy](/img/happy.png)\n\nHi');
    });

    test('hidden images drop the tags too', () {
      expect(show('Hi <Emotion="happy">', emotion: 'happy', showImages: false),
          'Hi ');
    });

    test('{{emotionlist}} lists the emotion names', () {
      expect(
        PromptBuilder.replaceKeywords('{{emotionlist}}', const {},
            context: CbsContext(emotions: const ['happy', 'sad'])),
        '["happy","sad"]',
      );
    });
  });

  group('card import', () {
    test('V3 emotion assets become emotion images', () async {
      final images = await CharacterCardParser.parseAssets({
        'spec': 'chara_card_v3',
        'data': {
          'assets': [
            {'type': 'icon', 'name': 'main', 'uri': 'data:image/png;base64,${base64Encode(_png)}'},
            {'type': 'emotion', 'name': 'happy', 'uri': 'data:image/png;base64,${base64Encode(_png)}'},
            {'type': 'emotion', 'name': 'sad', 'uri': '__asset:3', 'ext': 'png'},
          ],
        },
      }, 0, 'Alice', pngAssets: {'3': _png});
      expect([for (final i in images) (i.imageType, i.name)], [
        ('cover', 'main'),
        ('emotion', 'happy'),
        ('emotion', 'sad'),
      ]);
      expect(images.every((i) => i.path != null), isTrue);
    });

    test('V2 RisuAI emotions read base64 and PNG chunk assets', () async {
      final png = _pngWithTextChunks({
        'chara-ext-asset_:0': base64Encode(_png),
      });
      final images = await CharacterCardParser.parseAssets({
        'spec': 'chara_card_v2',
        'data': {
          'extensions': {
            'risuai': {
              'emotions': [
                ['joy', base64Encode(_png)],
                ['anger', '__asset:0'],
              ],
            },
          },
        },
      }, 0, 'Bob', pngAssets: CharacterCardParser.extractPngAssetChunks(png));
      expect([for (final i in images) (i.imageType, i.name)],
          [('emotion', 'joy'), ('emotion', 'anger')]);
    });

    test('RisuAI view screen settings pick the mode', () {
      Character parse(Map<String, dynamic> risu) =>
          CharacterCardParser.parseCharacterCard({
            'spec': 'chara_card_v3',
            'data': {
              'name': 'C',
              'extensions': {'risuai': risu},
            },
          });
      expect(parse({'viewScreen': 'none'}).emotionMode, EmotionMode.none);
      expect(parse({'viewScreen': 'emotion'}).emotionMode,
          EmotionMode.classifier);
      final inline = parse({
        'viewScreen': 'emotion',
        'inlayViewScreen': true,
        'newGenData': {'emotionInstructions': 'Custom {{slot}}'},
      });
      expect(inline.emotionMode, EmotionMode.inline);
      expect(inline.emotionInstructions, 'Custom {{slot}}');
      expect(
        parse({
          'viewScreen': 'emotion',
          'inlayViewScreen': true,
          'newGenData': {
            'emotionInstructions': EmotionMode.inline.defaultInstructions,
          },
        }).emotionInstructions,
        isNull,
      );
    });
  });

  group('card export', () {
    test('emotion images and settings survive a RisuAI round trip', () async {
      final character = Character(
        name: 'Dana',
        emotionMode: EmotionMode.inline,
      );
      final card = CharacterCardParser.toCharacterCardV3WithDataAssets(
        character: character,
        imageAssets: [
          (name: 'happy', mimeType: 'image/png', bytes: _png, imageType: 'emotion'),
        ],
      );
      final data = card['data'] as Map<String, dynamic>;
      expect((data['assets'] as List).single['type'], 'emotion');
      final risu = (data['extensions'] as Map)['risuai'] as Map;
      expect(risu['viewScreen'], 'emotion');
      expect(risu['inlayViewScreen'], isTrue);

      final reimported = CharacterCardParser.parseCharacterCard(card);
      expect(reimported.emotionMode, EmotionMode.inline);
      final images = await CharacterCardParser.parseAssets(card, 0, 'Dana');
      expect([for (final i in images) (i.imageType, i.name)],
          [('emotion', 'happy')]);
    });

    test('charx keeps emotion names apart from other images', () {
      final bytes = CharacterCardParser.buildCharxBytes(
        character: Character(name: 'Eve'),
        assetFiles: [
          (filename: 'happy.png', mimeType: 'image/png', bytes: _png, imageType: 'additional'),
          (filename: 'emotion/happy.png', mimeType: 'image/png', bytes: _png, imageType: 'emotion'),
        ],
      );
      final archive = ZipDecoder().decodeBytes(bytes);
      expect(archive.findFile('assets/happy.png'), isNotNull);
      expect(archive.findFile('assets/emotion/happy.png'), isNotNull);
      final card = jsonDecode(
          utf8.decode(archive.findFile('card.json')!.content as List<int>));
      expect(
        [
          for (final a in card['data']['assets'] as List)
            (a['type'], a['name'], a['uri']),
        ],
        [
          ('background', 'happy', 'embeded://assets/happy.png'),
          ('emotion', 'happy', 'embeded://assets/emotion/happy.png'),
        ],
      );
    });
  });
}
