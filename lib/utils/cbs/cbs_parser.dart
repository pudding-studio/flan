import 'cbs_context.dart';
import 'cbs_functions.dart';
import 'js_compat.dart';

/// Settings for one top-level render, mirroring RisuAI's matcher arguments.
class CbsRun {
  final CbsContext context;

  /// Index of the message being rendered; -1 while assembling a prompt.
  final int chatId;

  /// Strip variable writes (`setvar`, `addvar`, ...) without running them.
  final bool rmVar;

  /// Execute variable writes against [CbsContext.chatVars].
  final bool runVar;

  /// Rendering for on-screen display rather than for the model.
  final bool displaying;
  final String? role;
  final bool firstMsg;
  final String? chatRole;

  final Map<String, CbsUserFunction> functions = {};
  final Set<String> declarations = {};
  int depth = 0;

  CbsRun(
    this.context, {
    this.chatId = -1,
    this.rmVar = false,
    this.runVar = false,
    this.displaying = false,
    this.role,
    this.firstMsg = false,
    this.chatRole,
  });
}

class CbsUserFunction {
  final String body;
  final List<String> params;

  const CbsUserFunction(this.body, this.params);
}

/// What a CBS function sees while it runs: the run settings, the parse's
/// temp variables, and the text rendered so far (for `bkspc`/`erase`).
class CbsCall {
  final CbsRun run;
  final Map<String, String> tempVars;
  final List<StringBuffer> _nested;

  CbsCall(this.run, this.tempVars, this._nested);

  CbsContext get ctx => run.context;

  String get root => _nested[0].toString();

  set root(String value) {
    _nested[0]
      ..clear()
      ..write(value);
  }

  /// Renders [text] in the same run, as RisuAI does for descriptions.
  String render(String text) => CbsParser.render(text, run);
}

enum _Block {
  ignore,
  parse,
  nothing,
  ifPure,
  pure,
  each,
  function,
  pureDisplay,
  normalize,
  escape,
  newIf,
  newIfFalsy,
}

class _BlockMatch {
  final _Block type;
  final String? type2;
  final List<String>? funcArg;
  final String? mode;

  const _BlockMatch(this.type, {this.type2, this.funcArg, this.mode});

  bool get opensPureMode => const {
        _Block.ignore,
        _Block.pure,
        _Block.each,
        _Block.function,
        _Block.pureDisplay,
        _Block.escape,
      }.contains(type);
}

/// Port of RisuAI's `risuChatParser` (src/ts/parser/parser.svelte.ts).
///
/// Deliberate differences from upstream, all outside normal templates:
/// - recursion is limited by real nesting depth (upstream counts every
///   nested render cumulatively, so a 21st `{{description}}` errors);
/// - output text is accumulated in buffers instead of string `+=`;
/// - input growth from `#each` expansion is capped.
class CbsParser {
  CbsParser._();

  static const int _maxDepth = 20;
  static const int _maxInputLength = 2000000;
  static const int _stackTypeCbs = 1;
  static const int _stackTypeBlock = 5;
  static const int _stackTypePureNested = 6;

  static final RegExp _angleMacro =
      RegExp(r'<(user|char|bot)>', caseSensitive: false);

  static String render(String text, CbsRun run) {
    if (run.depth >= _maxDepth) return 'ERROR: Call stack limit reached';
    run.depth++;
    try {
      return _parse(text, run);
    } finally {
      run.depth--;
    }
  }

  static String _parse(String input, CbsRun run) {
    var da = input.replaceAllMapped(_angleMacro, (m) => '{{${m[1]}}}');
    if (!da.contains('{')) return da;

    var pointer = 0;
    final nested = <StringBuffer>[StringBuffer()];
    final stackType = <int, int>{};
    final pureModeNest = <int>{};
    final blockNestType = <int, _BlockMatch>{};
    final tempVars = <String, String>{};
    final call = CbsCall(run, tempVars, nested);

    void unshift(int type) {
      nested.insert(0, StringBuffer());
      stackType[nested.length] = type;
    }

    String shift() => nested.removeAt(0).toString();

    while (pointer < da.length) {
      final ch = da[pointer];
      final next = pointer + 1 < da.length ? da[pointer + 1] : '';
      switch (ch) {
        case '{':
          if (next != '{' && next != '#') {
            nested[0].write(ch);
            break;
          }
          pointer++;
          unshift(_stackTypeCbs);
          break;
        case '#':
          // Legacy `{#if x ... #}` block, deprecated upstream.
          if (next != '}' ||
              nested.length == 1 ||
              stackType[nested.length] != _stackTypeCbs) {
            nested[0].write(ch);
            break;
          }
          pointer++;
          final dat = shift();
          nested[0].write(_legacyBlock(dat) ?? '{#$dat#}');
          break;
        case '}':
          if (next != '}' ||
              nested.length == 1 ||
              stackType[nested.length] != _stackTypeCbs) {
            nested[0].write(ch);
            break;
          }
          pointer++;
          final dat = shift();
          final isPure = pureModeNest.isNotEmpty;

          if (dat.startsWith('#') || dat.startsWith(':')) {
            if (isPure) {
              nested[0].write('{{$dat}}');
              if (dat != ':else') unshift(_stackTypePureNested);
              break;
            }
            final match = _blockStart(dat, run);
            if (match.type == _Block.nothing) {
              nested[0].write('{{$dat}}');
              break;
            }
            unshift(_stackTypeBlock);
            blockNestType[nested.length] = match;
            if (match.opensPureMode) pureModeNest.add(nested.length);
            break;
          }

          if (dat.startsWith('/') && !dat.startsWith('//')) {
            if (stackType[nested.length] == _stackTypeBlock) {
              final block = blockNestType.remove(nested.length)!;
              if (block.opensPureMode) pureModeNest.remove(nested.length);
              final body = shift();
              final result = _blockEnd(body, block);
              switch (block.type) {
                case _Block.each:
                  final expanded = _expandEach(result, block);
                  if (expanded != null &&
                      da.length + expanded.length <= _maxInputLength) {
                    da = da.substring(0, pointer + 1) +
                        expanded +
                        da.substring(pointer + 1);
                  }
                case _Block.function:
                  run.functions[block.funcArg![0]] =
                      CbsUserFunction(result, block.funcArg!.sublist(1));
                case _Block.pureDisplay:
                  nested[0].write(result
                      .replaceAll('{{', r'\{\{')
                      .replaceAll('}}', r'\}\}'));
                default:
                  nested[0].write(result);
              }
              break;
            }
            if (stackType[nested.length] == _stackTypePureNested) {
              final inner = shift();
              nested[0].write('$inner{{$dat}}');
              break;
            }
          }

          if (dat.startsWith('call::')) {
            final argData = dat.split('::').sublist(1);
            final fn = run.functions[argData[0]];
            if (fn != null) {
              var body = fn.body;
              for (var i = 0; i < argData.length; i++) {
                body = body.replaceAll('{{arg::$i}}', argData[i]);
              }
              nested[0].write(render(body, run));
              break;
            }
          }

          final result = isPure ? null : _match(dat, call);
          nested[0].write(result ?? '{{$dat}}');
          if (tempVars.containsKey('__force_return__')) {
            return tempVars['__return__'] ?? 'null';
          }
          break;
        default:
          final stop = _nextSpecial(da, pointer);
          nested[0].write(da.substring(pointer, stop));
          pointer = stop - 1;
      }
      pointer++;
    }

    if (nested.length == 1) return nested[0].toString();
    // Unclosed `{{` are re-emitted literally, innermost last.
    final tail = StringBuffer();
    final pending = <String>[];
    while (nested.length > 1) {
      final opener = stackType[nested.length] == _stackTypeCbs ? '{{' : '<';
      pending.insert(0, '$opener${shift()}');
    }
    tail
      ..write(nested[0].toString())
      ..writeAll(pending);
    return tail.toString();
  }

  static int _nextSpecial(String s, int from) {
    for (var i = from + 1; i < s.length; i++) {
      final c = s.codeUnitAt(i);
      if (c == 0x7B || c == 0x7D || c == 0x23) return i; // { } #
    }
    return s.length;
  }

  /// RisuAI `matcher`: `? expr`, then `name::args` (or `name:args`).
  static String? _match(String p1, CbsCall call) {
    try {
      final ctx = call.ctx;
      final keyword = ctx.keywords[p1];
      if (keyword != null) {
        return ctx.parsedKeywords.contains(p1) ? call.render(keyword) : keyword;
      }
      // Upstream registers `{{// ...}}` as documentation only, so its parser
      // leaves the comment in the text sent to the model. It is documented
      // as a comment, and the app already strips it from SillyTavern
      // presets, so it renders empty here.
      if (p1.startsWith('//')) return '';
      if (p1.startsWith('? ')) {
        final value = CbsCalculator.calc(
          p1.substring(2),
          chatVar: ctx.chatVar,
          globalVar: ctx.globalVar,
        );
        return Js.numToString(value!);
      }
      final colon = p1.indexOf(':');
      final parts = (colon != -1 && colon + 1 < p1.length && p1[colon + 1] == ':')
          ? p1.split('::')
          : p1.split(':');
      final name = normalizeCbsName(parts[0]);
      final fn = cbsFunctions[name];
      if (fn == null) return null;
      return fn(call, parts.sublist(1), p1);
    } catch (_) {
      return null;
    }
  }

  static List<String> _splitLimit(String s, String sep, int limit) {
    final parts = s.split(sep);
    return parts.length > limit ? parts.sublist(0, limit) : parts;
  }

  static bool _truthy(String? s) => s == 'true' || s == '1';

  static _BlockMatch _blockStart(String p1, CbsRun run) {
    if (p1.startsWith('#if') || p1.startsWith('#if_pure ')) {
      final statement = _splitLimit(p1, ' ', 2);
      final state = statement.length > 1 ? statement[1] : null;
      if (_truthy(state)) {
        return _BlockMatch(
            p1.startsWith('#if_pure') ? _Block.ifPure : _Block.parse);
      }
      return const _BlockMatch(_Block.ignore);
    }

    if (p1.startsWith('#when')) {
      if (p1.startsWith('#when ')) {
        final statement = _splitLimit(p1, ' ', 2);
        final state = statement.length > 1 ? statement[1] : null;
        return _BlockMatch(_truthy(state) ? _Block.newIf : _Block.newIfFalsy);
      }
      if (p1.startsWith('#when::')) {
        return _whenOperators(p1.split('::').sublist(1), run);
      }
      return const _BlockMatch(_Block.newIfFalsy);
    }

    if (p1 == '#pure') return const _BlockMatch(_Block.pure);
    if (p1 == '#pure_display' || p1 == '#puredisplay') {
      return const _BlockMatch(_Block.pureDisplay);
    }
    if (p1 == '#code') return const _BlockMatch(_Block.normalize);
    if (p1.startsWith('#escape')) {
      final t2 = p1.substring(7).trim();
      return _BlockMatch(_Block.escape, mode: t2 == '::keep' ? 'keep' : null);
    }
    if (p1.startsWith('#each')) {
      var t2 = p1.substring(5).trim();
      String? mode;
      if (t2.startsWith('::keep ')) {
        mode = 'keep';
        t2 = t2.substring(7).trim();
      }
      if (t2.startsWith('as ')) t2 = t2.substring(3).trim();
      return _BlockMatch(_Block.each, type2: t2, mode: mode);
    }
    if (p1.startsWith('#func')) {
      final statement = p1.split(' ');
      if (statement.length > 1) {
        return _BlockMatch(_Block.function, funcArg: statement.sublist(1));
      }
    }
    return const _BlockMatch(_Block.nothing);
  }

  /// `#when::` operators, folded right to left exactly as upstream does.
  static _BlockMatch _whenOperators(List<String> statement, CbsRun run) {
    if (statement.length == 1) {
      return _BlockMatch(
          _truthy(statement[0]) ? _Block.newIf : _Block.newIfFalsy);
    }
    final ctx = run.context;
    var mode = 'normal';
    String bool01(bool v) => v ? '1' : '0';
    String? pop() => statement.isEmpty ? null : statement.removeLast();

    while (statement.length > 1) {
      final condition = pop();
      final op = pop();
      switch (op) {
        case 'not':
          statement.add(bool01(!_truthy(condition)));
        case 'keep':
          mode = 'keep';
          statement.add(condition!);
        case 'legacy':
          mode = 'legacy';
          statement.add(condition!);
        case 'and':
          final c2 = pop();
          statement.add(bool01(_truthy(condition) && _truthy(c2)));
        case 'or':
          final c2 = pop();
          statement.add(bool01(_truthy(condition) || _truthy(c2)));
        case 'is':
          statement.add(bool01(condition == pop()));
        case 'isnot':
          statement.add(bool01(condition != pop()));
        case 'var':
          statement.add(bool01(_truthy(ctx.chatVar(condition!))));
        case 'toggle':
          statement.add(bool01(_truthy(ctx.globalVar('toggle_$condition'))));
        case 'vis':
          statement.add(bool01(ctx.chatVar(pop() ?? '') == condition));
        case 'visnot':
          statement.add(bool01(ctx.chatVar(pop() ?? '') != condition));
        case 'tis':
          statement.add(bool01(ctx.globalVar('toggle_${pop()}') == condition));
        case 'tisnot':
          statement.add(bool01(ctx.globalVar('toggle_${pop()}') != condition));
        case '>':
          statement.add(bool01(Js.parseFloat(pop()) > Js.parseFloat(condition)));
        case '<':
          statement.add(bool01(Js.parseFloat(pop()) < Js.parseFloat(condition)));
        case '>=':
          statement.add(bool01(Js.parseFloat(pop()) >= Js.parseFloat(condition)));
        case '<=':
          statement.add(bool01(Js.parseFloat(pop()) <= Js.parseFloat(condition)));
        default:
          statement.add(bool01(_truthy(condition)));
      }
    }

    final truthy = _truthy(statement.isEmpty ? null : statement[0]);
    return switch (mode) {
      'keep' => _BlockMatch(truthy ? _Block.newIf : _Block.newIfFalsy,
          type2: 'keep'),
      'legacy' => _BlockMatch(truthy ? _Block.parse : _Block.ignore),
      _ => _BlockMatch(truthy ? _Block.newIf : _Block.newIfFalsy),
    };
  }

  static String _trimLines(String p1) =>
      p1.split('\n').map((v) => v.trimLeft()).join('\n').trim();

  static String _blockEnd(String p1, _BlockMatch block) {
    final trimmed = p1.trim();
    switch (block.type) {
      case _Block.pure:
      case _Block.pureDisplay:
      case _Block.function:
        return trimmed;
      case _Block.parse:
        return _trimLines(trimmed);
      case _Block.each:
        return block.mode == 'keep' ? p1 : _trimLines(trimmed);
      case _Block.ifPure:
        return p1;
      case _Block.newIf:
      case _Block.newIfFalsy:
        return _newIfBody(p1, block);
      case _Block.normalize:
        return _normalizeCode(trimmed);
      case _Block.escape:
        return cbsEscape(block.mode == 'keep' ? p1 : trimmed);
      default:
        return '';
    }
  }

  static String _newIfBody(String p1, _BlockMatch block) {
    final isTrue = block.type == _Block.newIf;
    final lines = p1.split('\n');
    if (lines.length == 1) {
      final elseIndex = p1.indexOf('{{:else}}');
      if (elseIndex != -1) {
        return isTrue ? p1.substring(0, elseIndex) : p1.substring(elseIndex + 9);
      }
      return isTrue ? p1 : '';
    }

    final elseLine = lines.indexWhere((v) => v.trim() == '{{:else}}');
    var kept = lines;
    if (elseLine != -1 && isTrue) kept = lines.sublist(0, elseLine);
    if (elseLine != -1 && !isTrue) kept = lines.sublist(elseLine + 1);
    if (elseLine == -1 && !isTrue) return '';

    if (block.type2 != 'keep') {
      var start = 0, end = kept.length;
      while (start < end && kept[start].trim().isEmpty) {
        start++;
      }
      while (end > start && kept[end - 1].trim().isEmpty) {
        end--;
      }
      kept = kept.sublist(start, end);
    }
    return kept.join('\n');
  }

  static String _normalizeCode(String text) {
    return text
        .replaceAll('\n', '')
        .replaceAll('\t', '')
        .replaceAllMapped(RegExp(r'\\u([0-9A-Fa-f]{4})'),
            (m) => String.fromCharCode(int.parse(m[1]!, radix: 16)))
        .replaceAllMapped(RegExp(r'\\(.)'), (m) {
      return switch (m[1]) {
        'n' => '\n',
        'r' => '\r',
        't' => '\t',
        'b' => '\b',
        'f' => '\f',
        'v' => '\v',
        'a' => 'a', // JS '\a' is just 'a'
        'x' => '\x00',
        _ => m[1]!,
      };
    });
  }

  /// `#each` expansion text, or null when upstream outputs nothing.
  static String? _expandEach(String body, _BlockMatch block) {
    final type2 = block.type2!;
    final asIndex = type2.lastIndexOf(' as ');
    String sub;
    List<Object?> array;
    if (asIndex == -1) {
      final space = type2.lastIndexOf(' ');
      if (space == -1) return null;
      sub = type2.substring(space + 1);
      array = cbsParseArray(type2.substring(0, space));
    } else {
      sub = type2.substring(asIndex + 4).trim();
      array = cbsParseArray(type2.substring(0, asIndex));
    }
    final out = StringBuffer();
    for (final element in array) {
      out.write(body.replaceAll('{{slot::$sub}}',
          element is String ? element : Js.jsonStringify(element)));
    }
    final added = out.toString();
    return block.mode == 'keep' ? added : added.trim();
  }

  static String? _legacyBlock(String p1) {
    final bn = p1.indexOf('\n');
    if (bn == -1) return null;
    final logic = p1.substring(0, bn);
    final content = p1.substring(bn + 1);
    final statement = _splitLimit(logic, ' ', 2);
    if (statement[0] != 'if') return null;
    final state = statement.length > 1 ? statement[1] : null;
    if (state != null && const ['', '0', '-1'].contains(state)) return '';
    return content.trim();
  }
}

/// RisuAI's lookup key: lower case with whitespace, `_` and `-` removed.
String normalizeCbsName(String name) =>
    name.toLowerCase().replaceAll(RegExp(r'[\s_-]'), '');

/// `risuEscape`: braces and parentheses become private-use characters so
/// they survive later parsing; [cbsUnescape] turns them back.
String cbsEscape(String text) => text.replaceAllMapped(
    RegExp(r'[{}()]'),
    (m) => switch (m[0]) {
          '{' => '',
          '}' => '',
          '(' => '',
          _ => '',
        });

const List<String> _unescapes = ['{', '}', '(', ')', '&lt;', '&gt;', ':', ';'];

/// `risuUnescape`.
String cbsUnescape(String text) => text.replaceAllMapped(
    RegExp('[-]'),
    (m) => _unescapes[m[0]!.codeUnitAt(0) - 0xE9B8]);
