import 'dart:math';

/// Global toggle that stands in for RisuAI's jailbreak switch
/// (`{{jbtoggled}}`, jailbreak prompt items).
const String cbsJailbreakToggleKey = 'risu_jailbreak';

/// Global toggle that stands in for RisuAI's chain-of-thought switch
/// (chain-of-thought prompt items).
const String cbsChainOfThoughtToggleKey = 'risu_cot';

/// RisuAI `parseKeyValue`: `key=value` lines; a line counts only when both
/// sides are non-empty, and anything after a second `=` is dropped.
Map<String, String> cbsParseKeyValue(String? text) {
  final result = <String, String>{};
  if (text == null || text.isEmpty) return result;
  for (final line in text.split('\n')) {
    final parts = line.split('=');
    if (parts.length < 2 || parts[0].isEmpty || parts[1].isEmpty) continue;
    result.putIfAbsent(parts[0], () => parts[1]);
  }
  return result;
}

/// One chat message as CBS sees it. Roles follow RisuAI: 'user' or 'char'.
class CbsMessage {
  final String role;
  final String data;
  final int? timeMs;

  const CbsMessage({required this.role, required this.data, this.timeMs});

  Map<String, Object?> toJson() =>
      {'role': role, 'data': data, if (timeMs != null) 'time': timeMs};
}

/// Everything a CBS template can read about the chat it renders for.
///
/// [keywords] are the app's own `{{name}}` placeholders. They win over CBS
/// functions on an exact name match, so prompts written for the old
/// replacement keep their meaning; values for names in [parsedKeywords] are
/// themselves rendered (RisuAI renders a character description the same way).
class CbsContext {
  final Map<String, String> keywords;
  final Set<String> parsedKeywords;

  final String charName;
  final String userName;
  final String charDescription;
  final String personaPrompt;
  final String scenario;
  final String firstMessage;
  final String authorNote;
  final List<Map<String, String>> lorebook;
  final List<CbsMessage> messages;

  final String modelId;
  final int? maxContext;
  final String appVersion;
  final String language;

  /// Chat variables (`getvar`), keyed without RisuAI's `$` prefix.
  final Map<String, String> chatVars;

  /// Values unset chat variables read (RisuAI `templateDefaultVariables`).
  final Map<String, String> defaultChatVars;

  /// Global variables (`getglobalvar`), including `toggle_<key>` entries.
  final Map<String, String> globalVars;

  /// Overrides for tests that mimic RisuAI's variable store.
  final String Function(String key)? chatVarReader;
  final String Function(String key)? globalVarReader;

  /// Seed for `pick`/`rollp`, stable for one chat (RisuAI: char id + chat id).
  final String pickSeed;
  final Random random;
  final DateTime Function() now;

  CbsContext({
    this.keywords = const {},
    this.parsedKeywords = const {},
    this.charName = '',
    this.userName = '',
    this.charDescription = '',
    this.personaPrompt = '',
    this.scenario = '',
    this.firstMessage = '',
    this.authorNote = '',
    this.lorebook = const [],
    this.messages = const [],
    this.modelId = '',
    this.maxContext,
    this.appVersion = '',
    this.language = '',
    Map<String, String>? chatVars,
    this.defaultChatVars = const {},
    this.globalVars = const {},
    this.chatVarReader,
    this.globalVarReader,
    this.pickSeed = '',
    Random? random,
    DateTime Function()? now,
  })  : chatVars = chatVars ?? {},
        random = random ?? Random(),
        now = now ?? DateTime.now;

  /// RisuAI `getChatVar`: unset values fall back to the template defaults,
  /// then read as the string "null".
  String chatVar(String key) =>
      chatVarReader?.call(key) ??
      chatVars[key] ??
      defaultChatVars[key] ??
      'null';

  /// RisuAI `getGlobalChatVar`.
  String globalVar(String key) =>
      globalVarReader?.call(key) ?? globalVars[key] ?? 'null';

  CbsContext withKeywords(Map<String, String> value) => CbsContext(
        keywords: value,
        parsedKeywords: parsedKeywords,
        charName: charName,
        userName: userName,
        charDescription: charDescription,
        personaPrompt: personaPrompt,
        scenario: scenario,
        firstMessage: firstMessage,
        authorNote: authorNote,
        lorebook: lorebook,
        messages: messages,
        modelId: modelId,
        maxContext: maxContext,
        appVersion: appVersion,
        language: language,
        chatVars: chatVars,
        defaultChatVars: defaultChatVars,
        globalVars: globalVars,
        chatVarReader: chatVarReader,
        globalVarReader: globalVarReader,
        pickSeed: pickSeed,
        random: random,
        now: now,
      );
}
