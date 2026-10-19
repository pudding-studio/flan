// How the CBS engine behaves inside the app's prompt pipeline.

import 'dart:convert';
import 'dart:io';

import 'package:flan/models/prompt/prompt_condition.dart';
import 'package:flan/models/prompt/prompt_condition_option.dart';
import 'package:flan/utils/cbs/cbs_app_bridge.dart';
import 'package:flan/utils/cbs/cbs_context.dart';
import 'package:flan/utils/prompt_builder.dart';
import 'package:flutter_test/flutter_test.dart';

/// The replacement the app used before CBS.
String _flatReplace(String text, Map<String, String> keywords) {
  var result = text;
  for (final entry in keywords.entries) {
    result = result.replaceAll('{{${entry.key}}}', entry.value);
  }
  return PromptBuilder.stripComments(result);
}

const _appKeywords = {
  'char': 'Alice',
  'user': 'Bob',
  'output_language': 'Korean',
  '시점자': 'Bob',
  '視点者': 'Bob',
  'char_description': 'A curious girl.',
  'user_description': 'A quiet boy.',
  'character_book': 'Lore entry',
  'start_setting': 'Start Date : 2024.01.01',
  'chat_memo': 'memo',
  'chat_historys': '<1>\nsummary\n</1>',
  'agent_context': 'agent notes',
  'world_date': '2024.01.02',
  'tools': 'tool list',
};

Iterable<String> _stringsIn(Object? json) sync* {
  if (json is String) {
    yield json;
  } else if (json is Map) {
    for (final value in json.values) {
      yield* _stringsIn(value);
    }
  } else if (json is List) {
    for (final value in json) {
      yield* _stringsIn(value);
    }
  }
}

void main() {
  group('default prompts', () {
    final files = Directory('assets/defaults')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.json') || f.path.endsWith('.txt'));

    for (final file in files) {
      test('${file.path} renders as before', () {
        final raw = file.readAsStringSync();
        final texts =
            file.path.endsWith('.json') ? _stringsIn(jsonDecode(raw)) : [raw];
        for (final text in texts) {
          expect(
            PromptBuilder.replaceKeywords(text, _appKeywords),
            _flatReplace(text, _appKeywords),
          );
        }
      });
    }
  });

  group('app keywords', () {
    test('win over CBS functions of the same name', () {
      expect(
        PromptBuilder.replaceKeywords('{{user}}/{{char}}', {
          'user': 'Persona',
          'char': 'Card',
        }, context: CbsContext(userName: 'Other', charName: 'Other')),
        'Persona/Card',
      );
    });

    test('parsed keyword values are rendered', () {
      final context = CbsContext(
        charName: 'Alice',
        parsedKeywords: cbsParsedAppKeywords,
      );
      expect(
        PromptBuilder.replaceKeywords(
          '{{char_description}}',
          {'char_description': '{{#if 1}}{{char}} is here{{/if}}'},
          context: context,
        ),
        'Alice is here',
      );
    });

    test('unparsed keyword values stay literal', () {
      expect(
        PromptBuilder.replaceKeywords(
          '{{chat_historys}}',
          {'chat_historys': '{{random::a::b}}'},
          context: CbsContext(parsedKeywords: cbsParsedAppKeywords),
        ),
        '{{random::a::b}}',
      );
    });

    test('unknown names are left untouched', () {
      expect(
        PromptBuilder.replaceKeywords('{{no_such_thing}}', const {}),
        '{{no_such_thing}}',
      );
    });
  });

  group('prompt rendering', () {
    test('variable writes are stripped, not executed', () {
      final context = CbsContext();
      expect(
        PromptBuilder.replaceKeywords(
          'a{{setvar::mood::happy}}b{{getvar::mood}}',
          const {},
          context: context,
        ),
        'abnull',
      );
      expect(context.chatVars, isEmpty);
    });

    test('comments are stripped', () {
      expect(
        PromptBuilder.replaceKeywords('a{{// note}}b/* note */c', const {}),
        'abc',
      );
    });

    test('escaped braces come out as plain text', () {
      expect(
        PromptBuilder.replaceKeywords('{{bo}}x{{bc}}', const {}),
        '{{x}}',
      );
    });

    test('role follows the item being rendered', () {
      expect(
        PromptBuilder.replaceKeywords('{{role}}', const {}, role: 'user'),
        'user',
      );
    });
  });

  group('prompt conditions as toggles', () {
    final conditions = [
      PromptCondition(id: 1, name: 'NSFW', variableName: 'nsfw'),
      PromptCondition(
        id: 2,
        name: 'Length',
        type: ConditionType.singleSelect,
        options: [
          PromptConditionOption(name: 'short'),
          PromptConditionOption(name: 'long'),
        ],
      ),
      PromptCondition(
        id: 3,
        name: 'Style',
        type: ConditionType.variable,
        variableName: 'style',
      ),
    ];

    test('map to RisuAI toggle globals', () {
      expect(
        cbsToggleVars(conditions, {1: 'true', 2: 'long', 3: 'noir'}),
        {
          'toggle_nsfw': '1',
          'toggle_NSFW': '1',
          'toggle_Length': '1',
          'toggle_style': 'noir',
          'toggle_Style': 'noir',
        },
      );
    });

    test('drive #when::toggle blocks', () {
      String render(Map<int, String> states) => PromptBuilder.replaceKeywords(
            '{{#when::toggle::nsfw}}on{{:else}}off{{/when}}'
            '|{{#when::Length::tis::1}}long{{/when}}',
            const {},
            context: CbsContext(globalVars: cbsToggleVars(conditions, states)),
          );

      expect(render({1: 'true', 2: 'long'}), 'on|long');
      expect(render({1: 'false', 2: 'short'}), 'off|');
    });
  });
}
