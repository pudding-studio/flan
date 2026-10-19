// RisuAI preset import: toggles, per-item options and prompt settings,
// checked through what the converted prompt actually sends.

import 'package:flan/models/character/character.dart';
import 'package:flan/models/character/persona.dart';
import 'package:flan/models/chat/chat_message.dart';
import 'package:flan/models/prompt/chat_prompt.dart';
import 'package:flan/models/prompt/prompt_condition.dart';
import 'package:flan/models/prompt/prompt_item.dart';
import 'package:flan/models/prompt/prompt_parameters.dart';
import 'package:flan/utils/cbs/cbs_app_bridge.dart';
import 'package:flan/utils/cbs/cbs_context.dart';
import 'package:flan/utils/prompt_builder.dart';
import 'package:flan/utils/risu_preset_converter.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _convert(Map<String, dynamic> preset) =>
    RisuPresetConverter.convertToNativeFormat(
      {'mainPrompt': '', 'globalNote': '', ...preset},
      fileName: 'preset',
    );

List<Map<String, dynamic>> _items(Map<String, dynamic> preset) =>
    (_convert(preset)['standaloneItems'] as List).cast<Map<String, dynamic>>();

String _render(String content, Map<String, String> keywords,
        [Map<String, String> globals = const {}]) =>
    PromptBuilder.replaceKeywords(content, keywords,
        context: CbsContext(
          parsedKeywords: cbsParsedAppKeywords,
          globalVars: globals,
        ));

void main() {
  group('preset toggles', () {
    final converted = _convert({
      'promptTemplate': [
        {'type': 'plain', 'role': 'system', 'type2': 'main', 'text': 'x'},
      ],
      'customPromptTemplateToggle': [
        'nsfw=NSFW',
        'len=Length=select=Short,Long',
        'style=Style=text',
        '=Options=group',
        'mood=Mood',
        '==groupEnd',
        '=Note=caption',
        '==divider',
        'broken',
      ].join('\n'),
    });
    final conditions = (converted['conditions'] as List)
        .map((c) => PromptCondition.fromJson(c as Map<String, dynamic>))
        .toList();

    test('become conditions keyed like RisuAI toggles', () {
      expect(
        [for (final c in conditions) (c.variableName, c.name, c.type)],
        [
          ('nsfw', 'NSFW', ConditionType.toggle),
          ('len', 'Length', ConditionType.singleSelect),
          ('style', 'Style', ConditionType.variable),
          ('mood', 'Options / Mood', ConditionType.toggle),
        ],
      );
      expect(conditions[1].options.map((o) => o.name), ['Short', 'Long']);
    });

    test('start as an untouched RisuAI install', () {
      final preset = (converted['conditionPresets'] as List).single as Map;
      expect(preset['isDefault'], isTrue);
      expect(preset['values'], [
        {'conditionId': 1, 'value': 'false'},
        {'conditionId': 4, 'value': 'false'},
      ]);
    });

    test('feed toggle_<key> as RisuAI stores them', () {
      final states = {for (final c in conditions) c.id!: ''}
        ..[1] = 'true'
        ..[2] = 'Long'
        ..[3] = 'noir';
      final vars = cbsToggleVars(conditions, states);
      expect(vars['toggle_nsfw'], '1');
      expect(vars['toggle_len'], '1');
      expect(vars['toggle_style'], 'noir');
    });
  });

  group('jailbreak and chain of thought', () {
    test('items follow their switches', () {
      final converted = _convert({
        'promptTemplate': [
          {'type': 'jailbreak', 'role': 'system', 'text': 'jb text'},
          {'type': 'cot', 'role': 'system', 'text': 'think'},
        ],
      });
      final items = converted['standaloneItems'] as List;
      final conditions = converted['conditions'] as List;
      expect(conditions.map((c) => c['variableName']),
          [cbsJailbreakToggleKey, cbsChainOfThoughtToggleKey]);
      expect(items[0]['enableMode'], 'conditional');
      expect(items[0]['conditionId'], 1);
      expect(items[1]['conditionId'], 2);
      expect(items[0]['conditionValue'], 'true');
    });

    test('{{jbtoggled}} adds the switch and reads it', () {
      final converted = _convert({
        'promptTemplate': [
          {'type': 'plain', 'role': 'system', 'text': '{{#if {{jbtoggled}}}}on{{/if}}'},
        ],
      });
      expect((converted['conditions'] as List).single['variableName'],
          cbsJailbreakToggleKey);
      final content = (converted['standaloneItems'] as List).single['content'];
      expect(_render(content, const {}, {'toggle_$cbsJailbreakToggleKey': '1'}),
          'on');
      expect(_render(content, const {}, {'toggle_$cbsJailbreakToggleKey': '0'}),
          '');
    });

    test('{{jb}} and friends inline the preset texts', () {
      final items = _items({
        'jailbreak': 'JB',
        'mainPrompt': 'MAIN',
        'promptTemplate': [
          {'type': 'plain', 'role': 'system', 'text': '{{main_prompt}}/{{jb}}{{position::pt}}'},
        ],
      });
      expect(items.first['content'], 'MAIN/JB');
    });
  });

  group('per-item options', () {
    test('innerFormat wraps the slot and vanishes when it is empty', () {
      final content = _items({
        'promptTemplate': [
          {'type': 'description', 'innerFormat': '<desc>{{slot}}</desc>'},
        ],
      }).first['content'] as String;
      expect(_render(content, {'char_description': 'Kind {{char}}', 'char': 'Al'}),
          '<desc>Kind Al</desc>');
      expect(_render(content, {'char_description': ''}), '');
    });

    test('author note falls back to its default text', () {
      final content = _items({
        'promptTemplate': [
          {
            'type': 'authornote',
            'innerFormat': '[{{slot}}]',
            'defaultText': 'default',
          },
        ],
      }).first['content'] as String;
      expect(_render(content, {'chat_memo': 'memo'}), '[memo]');
      expect(_render(content, {'chat_memo': ''}), '[default]');
    });

    test('roles map and system blocks after the chat start become user turns', () {
      final items = _items({
        'promptTemplate': [
          {'type': 'plain', 'role': 'system', 'text': 'main'},
          {'type': 'persona', 'role2': 'user'},
          {'type': 'chat', 'rangeStart': 0, 'rangeEnd': 'end'},
          {'type': 'plain', 'role': 'system', 'type2': 'globalNote', 'text': 'note'},
          {'type': 'plain', 'role': 'bot', 'text': 'prefill'},
        ],
        'promptSettings': {'trimStartNewChat': true},
      });
      expect(
        [for (final i in items) (i['role'], i['content'])],
        [
          ('system', 'main'),
          ('user', items[1]['content']),
          ('chat', ''),
          ('user', 'system: note'),
          ('assistant', 'prefill'),
        ],
      );
    });

    test('chat ranges map to native windows', () {
      final items = _items({
        'promptTemplate': [
          {'type': 'chat', 'rangeStart': -1000, 'rangeEnd': 'end'},
          {'type': 'chat', 'rangeStart': -6, 'rangeEnd': 'end'},
          {'type': 'chat', 'rangeStart': 0, 'rangeEnd': -4},
          {'type': 'chat', 'rangeStart': -10, 'rangeEnd': -4},
        ],
        'promptSettings': {'trimStartNewChat': true},
      });
      expect(items[0]['chatSettingMode'], 'basic');
      expect([items[1]['chatRangeType'], items[1]['recentChatCount']],
          ['recent', 3]);
      expect([items[2]['chatRangeType'], items[2]['chatStartPosition']],
          ['old', 2]);
      expect(
        [items[3]['chatRangeType'], items[3]['chatStartPosition'], items[3]['chatEndPosition']],
        ['middle', 3, 5],
      );
    });

    test('ChatML splits into role blocks', () {
      final items = _items({
        'promptTemplate': [
          {
            'type': 'chatML',
            'text': '<|im_start|>system\nrules<|im_end|>\n'
                '<|im_start|>user\nhi<|im_end|>\n'
                '<|im_start|>assistant\nhello<|im_end|>',
          },
        ],
      });
      expect([for (final i in items) (i['role'], i['content'])], [
        ('system', 'rules'),
        ('user', 'hi'),
        ('assistant', 'hello'),
      ]);
    });
  });

  group('prompt settings', () {
    test('[Start a new chat] precedes the history unless trimmed', () {
      final template = [
        {'type': 'plain', 'role': 'system', 'text': 'main'},
        {'type': 'chat', 'rangeStart': 0, 'rangeEnd': 'end'},
      ];
      expect(_items({'promptTemplate': template}).map((i) => i['content']),
          ['main', '[Start a new chat]', '']);
      expect(
        _items({
          'promptTemplate': template,
          'promptSettings': {'trimStartNewChat': true},
        }).map((i) => i['content']),
        ['main', ''],
      );
    });

    test('postEndInnerFormat goes last even without a post-everything slot', () {
      final items = _items({
        'promptTemplate': [
          {'type': 'chat', 'rangeStart': 0, 'rangeEnd': 'end'},
        ],
        'promptSettings': {'trimStartNewChat': true, 'postEndInnerFormat': 'END'},
      });
      expect([items.last['role'], items.last['content']], ['user', 'system: END']);
    });

    test('behavior settings become prompt parameters', () {
      final parameters = PromptParameters.fromJson(_convert({
        'promptTemplate': [
          {'type': 'chat', 'rangeStart': 0, 'rangeEnd': 'end'},
        ],
        'promptSettings': {'sendName': true, 'sendChatAsSystem': true},
        'templateDefaultVariables': 'hp=10\nmp=5',
      })['parameters'] as Map<String, dynamic>);
      expect(parameters.userMessageInChatHistory, isTrue);
      expect(parameters.sendName, isTrue);
      expect(parameters.sendChatAsSystem, isTrue);
      expect(cbsParseKeyValue(parameters.defaultVariables), {'hp': '10', 'mp': '5'});
    });

    test('default variables back unset chat variables', () {
      final context = CbsContext(defaultChatVars: cbsParseKeyValue('hp=10'));
      expect(
        PromptBuilder.replaceKeywords('{{getvar::hp}}/{{getvar::mp}}', const {},
            context: context),
        '10/null',
      );
    });
  });

  test('converted JSON loads through the native import models', () {
    final json = _convert({
      'name': 'Risu',
      'promptTemplate': [
        {'type': 'jailbreak', 'role': 'system', 'text': 'jb'},
        {'type': 'chat', 'rangeStart': -4, 'rangeEnd': 'end'},
      ],
      'customPromptTemplateToggle': 'len=Length=select=Short,Long',
    });
    final prompt = ChatPrompt.fromJson(json);
    final items = prompt.standaloneItemsFromJson(json);
    final conditions = prompt.conditionsFromJson(json);
    final presets = prompt.conditionPresetsFromJson(json);
    expect(prompt.name, 'Risu');
    expect(prompt.parameters?.userMessageInChatHistory, isTrue);
    expect(items.map((i) => i.role),
        [PromptRole.system, PromptRole.system, PromptRole.chat]);
    expect(items.first.enableMode, EnableMode.conditional);
    expect(items.first.conditionId, conditions[1].id);
    expect(items.last.recentChatCount, 2);
    expect(presets.single.values.single.conditionId, conditions[1].id);
  });

  group('legacy layout', () {
    test('formatingOrder sections with @@ role switches', () {
      final items = _items({
        'mainPrompt': 'rules\n@@assistant\nok',
        'jailbreak': 'jb',
        'formatingOrder': ['main', 'chats', 'lastChat', 'jailbreak'],
      });
      expect([for (final i in items) (i['role'], i['content'])], [
        ('system', 'rules'),
        ('assistant', 'ok'),
        ('user', 'system: [Start a new chat]'),
        ('chat', ''),
        ('user', 'system: jb'),
      ]);
      expect(items.last['enableMode'], 'conditional');
    });
  });

  group('sending', () {
    final character = Character(name: 'Al');
    final persona = Persona(characterId: 1, name: 'Bo', order: 0);
    final history = [
      ChatMessage(id: 1, chatRoomId: 1, role: MessageRole.user, content: 'hi'),
      ChatMessage(id: 2, chatRoomId: 1, role: MessageRole.assistant, content: 'hello'),
    ];

    List<(String, String)> send(PromptParameters parameters) {
      final chatItem = PromptItem(role: PromptRole.chat, content: '');
      final prompt = ChatPrompt(
        name: 'p',
        parameters: parameters,
        items: [
          chatItem,
          PromptItem(role: PromptRole.user, content: 'after'),
          PromptItem(role: PromptRole.user, content: '{{#if 0}}x{{/if}}'),
        ],
      );
      final contents = PromptBuilder.buildContents(
        chatPrompt: prompt,
        character: character,
        persona: persona,
        userMessage: 'new',
        chatHistoryMap: {chatItem: history},
        systemPrompt: '',
      );
      return [
        for (final c in contents)
          (c['role'] as String, (c['parts'] as List).single['text'] as String),
      ];
    }

    test('the new message follows the history like in RisuAI', () {
      expect(send(const PromptParameters(userMessageInChatHistory: true)), [
        ('user', 'hi'),
        ('model', 'hello'),
        ('user', 'new\nafter'),
      ]);
    });

    test('native prompts keep the new message last and skip empty blocks', () {
      expect(send(const PromptParameters()), [
        ('user', 'hi'),
        ('model', 'hello'),
        ('user', 'after\nnew'),
      ]);
    });

    test('sendName and sendChatAsSystem reshape history turns', () {
      expect(
        send(const PromptParameters(sendName: true)).first,
        ('user', "<Bo's Message>\nhi\n</Bo's Message>\n"
            "<Al's Message>\nhello\n</Al's Message>\n"
            'after\n'
            "<Bo's Message>\nnew\n</Bo's Message>"),
      );
      expect(
        send(const PromptParameters(sendChatAsSystem: true)).first.$2,
        startsWith('system: user: hi\nsystem: assistant: hello'),
      );
    });
  });
}
