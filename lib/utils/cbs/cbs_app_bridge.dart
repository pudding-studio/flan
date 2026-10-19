import '../../models/character/character_book_folder.dart';
import '../../models/chat/chat_message.dart';
import '../../models/prompt/prompt_condition.dart';
import 'cbs_context.dart';

/// App keywords whose values are rendered as CBS too. RisuAI renders a
/// character's description and the persona the same way, so templates
/// inside imported cards work here as well.
const Set<String> cbsParsedAppKeywords = {
  'char_description',
  'user_description',
  'start_setting',
  'chat_memo',
  'character_book',
};

CbsMessage cbsMessageOf(ChatMessage message) => CbsMessage(
      role: message.role == MessageRole.user ? 'user' : 'char',
      data: message.content,
      timeMs: message.createdAt.millisecondsSinceEpoch,
    );

List<Map<String, String>> cbsLorebookOf(List<CharacterBook> books) => [
      for (final book in books)
        {
          'comment': book.name,
          'key': book.keys.join(','),
          'content': book.content ?? book.oneLineDescription,
        },
    ];

/// Prompt conditions exposed as RisuAI toggles (`toggle_<key>` globals),
/// in RisuAI's stored format: checkbox "1"/"0", select = option index,
/// text = the value itself. Each condition answers to both its variable
/// name and its display name, since imported templates may use either.
Map<String, String> cbsToggleVars(
  List<PromptCondition> conditions,
  Map<int, String> states,
) {
  final vars = <String, String>{};
  for (final condition in conditions) {
    final state = states[condition.id];
    if (state == null) continue;
    final value = switch (condition.type) {
      ConditionType.toggle => state == 'true' ? '1' : '0',
      ConditionType.singleSelect => () {
          final index =
              condition.options.indexWhere((o) => o.name == state);
          return index == -1 ? 'null' : '$index';
        }(),
      ConditionType.variable => state,
    };
    for (final key in {condition.variableName, condition.name}) {
      if (key != null && key.isNotEmpty) vars['toggle_$key'] = value;
    }
  }
  return vars;
}
