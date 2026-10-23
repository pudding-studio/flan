import 'dart:convert';
import 'dart:math' as math;

import 'cbs_context.dart';
import 'cbs_parser.dart';
import 'js_compat.dart';

/// A CBS function: returns the replacement text, or null to leave the
/// `{{...}}` in place (RisuAI's "not handled" result).
typedef CbsFunction = String? Function(
    CbsCall call, List<String> args, String raw);

/// Port of the RisuAI CBS function table (src/ts/cbs.ts), keyed by the
/// normalized lookup name. Functions tied to RisuAI-only data (assets,
/// modules, jailbreak toggles, triggers) return what RisuAI returns when
/// that data is absent.
final Map<String, CbsFunction> cbsFunctions = _buildCbsFunctions();

String? _arg(List<String> args, int i) => i < args.length ? args[i] : null;

double _num(List<String> args, int i) => Js.number(_arg(args, i));

String _bool(bool v) => v ? '1' : '0';

String _hms(Duration d) {
  final total = d.inMilliseconds ~/ 1000;
  final hours = total ~/ 3600;
  final minutes = (total ~/ 60) % 60;
  final seconds = total % 60;
  return '$hours:${minutes.toString().padLeft(2, '0')}:'
      '${seconds.toString().padLeft(2, '0')}';
}

/// RisuAI `makeArray`: JSON array with `::` in strings escaped.
String cbsMakeArray(Iterable<Object?> items) => Js.jsonStringify(items
    .map((e) => e is String ? e.replaceAll('::', r'::') : e)
    .toList());

/// RisuAI `parseArray`: a JSON array, else the text split on `§`.
List<Object?> cbsParseArray(String text) {
  try {
    final decoded = jsonDecode(text);
    if (decoded is List) return List<Object?>.of(decoded);
  } catch (_) {}
  return text.split('§');
}

Object? _parseDict(String text) {
  try {
    return jsonDecode(text);
  } catch (_) {
    return <String, Object?>{};
  }
}

Object? _index(Object? container, String key) {
  if (container is Map) return container[key];
  if (container is List) {
    final i = int.tryParse(key);
    return (i != null && i >= 0 && i < container.length) ? container[i] : null;
  }
  if (container is String) {
    final i = int.tryParse(key);
    return (i != null && i >= 0 && i < container.length) ? container[i] : null;
  }
  return null;
}

String _elementText(Object? element) =>
    (element is Map || element is List) ? Js.jsonStringify(element) : Js.stringOf(element);

double _jsonNumber(Object? v) {
  if (v is num) return v.toDouble();
  if (v is bool) return v ? 1 : 0;
  if (v == null) return 0;
  if (v is String) return Js.number(v);
  return double.nan;
}

List<double> _numbers(List<String> args) {
  final values = args.length > 1 ? args : cbsParseArray(args[0]);
  return values.map((f) {
    final n = _jsonNumber(f);
    return n.isNaN ? 0.0 : n;
  }).toList();
}

String _dateTimeFormat(String main, double time, DateTime now) {
  final date = time == 0
      ? now
      : DateTime.fromMillisecondsSinceEpoch(time.truncate());
  if (main.isEmpty) return '';
  if (main.startsWith(':')) main = main.substring(1);
  if (main.length > 300) return '';
  final dayOfYear =
      date.difference(DateTime(date.year, 1, 0)).inMilliseconds ~/ 86400000;
  String two(int v) => v.toString().padLeft(2, '0');
  return main
      .replaceAll('YYYY', '${date.year}')
      .replaceAll('YY', '${date.year}'.substring(2))
      .replaceAll('MMMM', Js.monthLong(date))
      .replaceAll('MMM', Js.monthShort(date))
      .replaceAll('MM', two(date.month))
      .replaceAll('DDDD', '$dayOfYear')
      .replaceAll('DD', two(date.day))
      .replaceAll('dddd', Js.weekdayLong(date))
      .replaceAll('ddd', Js.weekdayShort(date))
      .replaceAll('HH', two(date.hour))
      .replaceAll('hh', two(date.hour % 12 == 0 ? 12 : date.hour % 12))
      .replaceAll('mm', two(date.minute))
      .replaceAll('ss', two(date.second))
      .replaceAll('X', '${date.millisecondsSinceEpoch ~/ 1000}')
      .replaceAll('x', '${date.millisecondsSinceEpoch}')
      .replaceAll('A', date.hour >= 12 ? 'PM' : 'AM');
}

String? _formattedTime(CbsCall call, List<String> args, bool dateOnly) {
  final now = call.ctx.now();
  if (args.isEmpty) {
    return dateOnly
        ? '${now.year}-${now.month}-${now.day}'
        : '${now.hour}:${now.minute}:${now.second}';
  }
  var t = 0.0;
  final second = _arg(args, 1);
  if (second != null && second.isNotEmpty) {
    t = Js.number(second) / 1000;
    if (t.isNaN) t = 0;
  }
  return _dateTimeFormat(args[0], t, now);
}

String _randomPick(List<String> args, double rand) {
  if (args.isEmpty) return Js.numToString(rand);
  final List<Object?> items;
  if (args.length == 1) {
    final a = args[0];
    items = (a.startsWith('[') && a.endsWith(']'))
        ? cbsParseArray(a)
        : a.replaceAll(r'\,', '§X').split(RegExp(r':|,'));
  } else {
    items = args;
  }
  final element = items[(rand * items.length).floor()];
  return element is String
      ? element.replaceAll('§X', ',')
      : Js.jsonStringify(element);
}

String _roll(List<String> args, double Function(int i) rand) {
  if (args.isEmpty) return '1';
  final notation = args[0].split('d');
  var num = 1.0;
  var sides = 6.0;
  if (notation.length == 2) {
    num = Js.number(notation[0].isEmpty ? '1' : notation[0]);
    sides = Js.number(notation[1].isEmpty ? '6' : notation[1]);
  } else if (notation.length == 1) {
    sides = Js.number(notation[0]);
  }
  if (num.isNaN || sides.isNaN || num < 1 || sides < 1) return 'NaN';
  var total = 0;
  for (var i = 0; i < num; i++) {
    total += (rand(i) * sides).floor() + 1;
  }
  return '$total';
}

/// Storing JS `undefined` reads back as a missing variable ("null").
void _writeVar(CbsCall call, String key, String? value) {
  if (value == null) {
    call.ctx.chatVars.remove(key);
  } else {
    call.ctx.chatVars[key] = value;
  }
}

String? _setVar(CbsCall call, void Function() write) {
  if (call.run.rmVar) return '';
  if (call.run.runVar) {
    write();
    return '';
  }
  return null;
}

String _historyEntry(CbsCall call, CbsMessage m) =>
    Js.jsonStringify({...m.toJson(), 'data': call.render(m.data)});

Map<String, CbsFunction> _buildCbsFunctions() {
  final f = <String, CbsFunction>{};
  void reg(List<String> names, CbsFunction fn) {
    for (final name in names) {
      f[normalizeCbsName(name)] = fn;
    }
  }

  // ── Character / user / chat info ──
  reg(['char', 'bot'], (c, a, r) => c.ctx.charName);
  reg(['user'], (c, a, r) => c.ctx.userName);
  reg(['triggerid', 'trigger_id'], (c, a, r) => 'null');
  reg(['previouscharchat', 'lastcharmessage'], (c, a, r) {
    final msgs = c.ctx.messages;
    var p = c.run.chatId != -1 ? c.run.chatId - 1 : msgs.length - 1;
    for (; p >= 0; p--) {
      if (msgs[p].role == 'char') return msgs[p].data;
    }
    return c.ctx.firstMessage;
  });
  reg(['previoususerchat', 'lastusermessage'], (c, a, r) {
    if (c.run.chatId == -1) return '';
    final msgs = c.ctx.messages;
    for (var p = c.run.chatId - 1; p >= 0; p--) {
      if (msgs[p].role == 'user') return msgs[p].data;
    }
    return c.ctx.firstMessage;
  });
  reg(['personality', 'charpersona'], (c, a, r) => '');
  reg(['description', 'chardesc'], (c, a, r) => c.render(c.ctx.charDescription));
  reg(['scenario'], (c, a, r) => c.render(c.ctx.scenario));
  reg(['exampledialogue', 'examplemessage', 'example_dialogue'],
      (c, a, r) => '');
  reg(['persona', 'userpersona'], (c, a, r) => c.render(c.ctx.personaPrompt));
  reg(['mainprompt', 'systemprompt', 'main_prompt'], (c, a, r) => '');
  reg(['lorebook', 'worldinfo'],
      (c, a, r) => cbsMakeArray(c.ctx.lorebook.map(Js.jsonStringify)));
  reg(['userhistory', 'usermessages', 'user_history'], (c, a, r) =>
      cbsMakeArray(c.ctx.messages
          .where((m) => m.role == 'user')
          .map((m) => _historyEntry(c, m))));
  reg(['charhistory', 'charmessages', 'char_history'], (c, a, r) =>
      cbsMakeArray(c.ctx.messages
          .where((m) => m.role == 'char')
          .map((m) => _historyEntry(c, m))));
  reg(['jb', 'jailbreak'], (c, a, r) => '');
  reg(['globalnote', 'systemnote', 'ujb'], (c, a, r) => '');
  reg(['authornote', 'author_note'], (c, a, r) =>
      c.ctx.authorNote.isNotEmpty ? c.render(c.ctx.authorNote) : '');
  reg(['chatindex', 'chat_index'], (c, a, r) => '${c.run.chatId}');
  reg(['firstmsgindex', 'firstmessageindex', 'first_msg_index'],
      (c, a, r) => '-1');
  reg(['blank', 'none'], (c, a, r) => '');
  reg(['messagetime', 'message_time'], (c, a, r) {
    final m = _messageAt(c);
    if (m == null) return '[Cannot get time]';
    if (m.timeMs == null) {
      return '[Cannot get time, message was sent in older version]';
    }
    final d = DateTime.fromMillisecondsSinceEpoch(m.timeMs!);
    return '${d.hour}:${d.minute.toString().padLeft(2, '0')}:'
        '${d.second.toString().padLeft(2, '0')}';
  });
  reg(['messagedate', 'message_date'], (c, a, r) {
    final m = _messageAt(c);
    if (m == null) return '[Cannot get time]';
    if (m.timeMs == null) {
      return '[Cannot get time, message was sent in older version]';
    }
    final d = DateTime.fromMillisecondsSinceEpoch(m.timeMs!);
    return '${d.month}/${d.day}/${d.year}';
  });
  reg(['messageunixtimearray', 'message_unixtime_array'],
      (c, a, r) => cbsMakeArray(c.ctx.messages.map((m) => '${m.timeMs ?? 0}')));
  reg(['unixtime'], (c, a, r) =>
      Js.toFixed(c.ctx.now().millisecondsSinceEpoch / 1000, 0));
  reg(['time'], (c, a, r) => _formattedTime(c, a, false));
  reg(['date', 'datetimeformat'], (c, a, r) => _formattedTime(c, a, true));
  reg(['isotime'], (c, a, r) {
    final n = c.ctx.now().toUtc();
    return '${n.hour}:${n.minute}:${n.second}';
  });
  reg(['isodate'], (c, a, r) {
    final n = c.ctx.now().toUtc();
    return '${n.year}-${n.month}-${n.day}';
  });
  reg(['messageidleduration', 'message_idle_duration'], (c, a, r) {
    if (c.run.chatId == -1) return '[Cannot get time]';
    final msgs = c.ctx.messages;
    CbsMessage? last, previous;
    for (var p = c.run.chatId; p >= 0; p--) {
      if (msgs[p].role != 'user') continue;
      if (last == null) {
        last = msgs[p];
      } else {
        previous = msgs[p];
        break;
      }
    }
    if (last == null) return '[No user message found]';
    if (previous == null) return '[No previous user message found]';
    if (last.timeMs == null) {
      return '[Cannot get time, message was sent in older version]';
    }
    if (previous.timeMs == null) {
      return '[Cannot get time, previous message was sent in older version]';
    }
    return _hms(Duration(milliseconds: last.timeMs! - previous.timeMs!));
  });
  reg(['idleduration', 'idle_duration'], (c, a, r) {
    final msgs = c.ctx.messages;
    if (msgs.isEmpty) return '00:00:00';
    final t = msgs.last.timeMs;
    if (t == null) return '[Cannot get time, message was sent in older version]';
    return _hms(Duration(
        milliseconds: c.ctx.now().millisecondsSinceEpoch - t));
  });
  reg(['br', 'newline'], (c, a, r) => '\n');
  reg(['model'], (c, a, r) => c.ctx.modelId);
  reg(['axmodel'], (c, a, r) => '');
  reg(['role'], (c, a, r) {
    if (c.run.chatRole != null) return c.run.chatRole;
    if (c.run.firstMsg) return 'char';
    final m = _messageAt(c);
    if (m != null) return m.role;
    return c.run.role ?? 'null';
  });
  reg(['isfirstmsg', 'isfirstmessage'], (c, a, r) => _bool(c.run.firstMsg));
  reg(['jbtoggled'], (c, a, r) =>
      _bool(c.ctx.globalVar('toggle_$cbsJailbreakToggleKey') == '1'));
  reg(['maxcontext'], (c, a, r) => '${c.ctx.maxContext ?? 0}');
  reg(['lastmessage'], (c, a, r) => c.ctx.messages.last.data);
  reg(['lastmessageid', 'lastmessageindex'],
      (c, a, r) => '${c.ctx.messages.length - 1}');
  reg(['previouschatlog', 'previous_chat_log'], (c, a, r) {
    final n = _num(a, 0);
    final msgs = c.ctx.messages;
    if (n.isNaN || n != n.truncateToDouble() || n < 0 || n >= msgs.length) {
      return 'Out of range';
    }
    return msgs[n.toInt()].data;
  });
  reg(['history', 'messages'], (c, a, r) {
    if (a.isEmpty) {
      return cbsMakeArray([
        CbsMessage(role: 'char', data: c.ctx.firstMessage),
        ...c.ctx.messages,
      ].map((m) => _historyEntry(c, m)));
    }
    return cbsMakeArray(c.ctx.messages
        .map((m) => '${a.contains('role') ? '${m.role}: ' : ''}${m.data}'));
  });
  reg(['emotionlist'], (c, a, r) => cbsMakeArray(c.ctx.emotions));
  reg(['assetlist'], (c, a, r) => cbsMakeArray(const []));
  reg(['chardisplayasset'], (c, a, r) => cbsMakeArray(const []));
  reg(['prefillsupported', 'prefill_supported', 'prefill'],
      (c, a, r) => _bool(c.ctx.modelId.startsWith('claude')));
  reg(['screenwidth', 'screen_width'], (c, a, r) => '0');
  reg(['screenheight', 'screen_height'], (c, a, r) => '0');
  reg(['moduleenabled', 'module_enabled'], (c, a, r) => '0');
  reg(['moduleassetlist', 'module_assetlist'], (c, a, r) => '');
  reg(['metadata'], (c, a, r) {
    final ctx = c.ctx;
    return switch (a[0].toLowerCase()) {
      'mobile' => '1',
      'local' => '1',
      'node' => '0',
      'version' => ctx.appVersion,
      'majorversion' || 'majorver' || 'major' => ctx.appVersion.split('.')[0],
      'language' || 'locale' || 'lang' => ctx.language,
      'browserlanguage' || 'browserlocale' || 'browserlang' => ctx.language,
      'modelshortname' || 'modelname' || 'modelinternalid' => ctx.modelId,
      'modelformat' || 'modelprovider' || 'modeltokenizer' => '0',
      'imateapot' => '🫖',
      'risutype' => 'local',
      'maxcontext' => '${ctx.maxContext ?? 0}',
      _ => 'Error: ${a[0]} is not a valid metadata key.',
    };
  });

  // ── Variables ──
  reg(['tempvar', 'gettempvar'], (c, a, r) => c.tempVars[a[0]] ?? '');
  reg(['settempvar'], (c, a, r) {
    c.tempVars[a[0]] = _arg(a, 1) ?? '';
    return '';
  });
  reg(['return'], (c, a, r) {
    c.tempVars['__return__'] = a[0];
    c.tempVars['__force_return__'] = '1';
    return '';
  });
  reg(['getvar'], (c, a, r) => c.ctx.chatVar(a[0]));
  reg(['setvar'], (c, a, r) => _setVar(c, () => _writeVar(c, a[0], _arg(a, 1))));
  reg(['addvar'], (c, a, r) => _setVar(c, () {
        c.ctx.chatVars[a[0]] = Js.numToString(
            Js.number(c.ctx.chatVar(a[0])) + _num(a, 1));
      }));
  reg(['setdefaultvar'], (c, a, r) => _setVar(c, () {
        final current = c.ctx.chatVar(a[0]);
        if (current.isEmpty || current == 'null') _writeVar(c, a[0], _arg(a, 1));
      }));
  reg(['getglobalvar'], (c, a, r) => c.ctx.globalVar(a[0]));
  reg(['declare'], (c, a, r) {
    c.run.declarations.add(a[0]);
    return '';
  });

  // ── Comparison / logic ──
  reg(['equal'], (c, a, r) => _bool(_arg(a, 0) == _arg(a, 1)));
  reg(['notequal', 'not_equal'], (c, a, r) => _bool(_arg(a, 0) != _arg(a, 1)));
  reg(['greater'], (c, a, r) => _bool(_num(a, 0) > _num(a, 1)));
  reg(['less'], (c, a, r) => _bool(_num(a, 0) < _num(a, 1)));
  reg(['greaterequal', 'greater_equal'], (c, a, r) => _bool(_num(a, 0) >= _num(a, 1)));
  reg(['lessequal', 'less_equal'], (c, a, r) => _bool(_num(a, 0) <= _num(a, 1)));
  reg(['and'], (c, a, r) => _bool(_arg(a, 0) == '1' && _arg(a, 1) == '1'));
  reg(['or'], (c, a, r) => _bool(_arg(a, 0) == '1' || _arg(a, 1) == '1'));
  reg(['not'], (c, a, r) => _arg(a, 0) == '1' ? '0' : '1');
  reg(['all'], (c, a, r) => _bool(
      (a.length > 1 ? a : cbsParseArray(a[0])).every((v) => v == '1')));
  reg(['any'], (c, a, r) => _bool(
      (a.length > 1 ? a : cbsParseArray(a[0])).any((v) => v == '1')));
  reg(['iserror'], (c, a, r) => _bool(a[0].toLowerCase().startsWith('error:')));

  // ── Math ──
  reg(['calc'], (c, a, r) => Js.numToString(CbsCalculator.calc(a[0],
      chatVar: c.ctx.chatVar, globalVar: c.ctx.globalVar)!));
  reg(['round'], (c, a, r) => Js.numToString(Js.round(_num(a, 0))));
  reg(['floor'], (c, a, r) => Js.numToString(_num(a, 0).floorToDouble()));
  reg(['ceil'], (c, a, r) => Js.numToString(_num(a, 0).ceilToDouble()));
  reg(['abs'], (c, a, r) => Js.numToString(_num(a, 0).abs()));
  reg(['remaind'], (c, a, r) => Js.numToString(_num(a, 0).remainder(_num(a, 1))));
  reg(['pow'], (c, a, r) =>
      Js.numToString(math.pow(_num(a, 0), _num(a, 1)).toDouble()));
  reg(['fixnum', 'fixnumber'], (c, a, r) => Js.toFixed(_num(a, 0), _num(a, 1)));
  reg(['tonumber'], (c, a, r) => String.fromCharCodes(a[0].runes.where((cp) {
        final ch = String.fromCharCode(cp);
        return !Js.number(ch).isNaN || ch == '.';
      })));
  reg(['min'], (c, a, r) =>
      Js.numToString(_numbers(a).fold(double.infinity, math.min)));
  reg(['max'], (c, a, r) =>
      Js.numToString(_numbers(a).fold(double.negativeInfinity, math.max)));
  reg(['sum'], (c, a, r) => Js.numToString(_numbers(a).fold(0.0, (x, y) => x + y)));
  reg(['average'], (c, a, r) {
    final values = _numbers(a);
    return Js.numToString(values.fold(0.0, (x, y) => x + y) / values.length);
  });
  reg(['fromhex'], (c, a, r) => Js.numToString(Js.parseInt(a[0], 16)));
  reg(['tohex'], (c, a, r) {
    final v = Js.parseInt(a[0]);
    if (v.isNaN) return 'NaN';
    return BigInt.from(v).toRadixString(16);
  });

  // ── Random ──
  double pickRand(CbsCall c, int offset) =>
      pickHashRand(c.ctx.messages.length + offset, c.ctx.pickSeed);
  reg(['random'], (c, a, r) => _randomPick(a, c.ctx.random.nextDouble()));
  reg(['pick'], (c, a, r) => _randomPick(a, pickRand(c, 0)));
  reg(['roll'], (c, a, r) => _roll(a, (_) => c.ctx.random.nextDouble()));
  reg(['rollp', 'rollpick'], (c, a, r) => _roll(a, (i) => pickRand(c, i * 15)));
  reg(['randint'], (c, a, r) {
    final min = _num(a, 0), max = _num(a, 1);
    if (min.isNaN || max.isNaN) return 'NaN';
    return Js.numToString(
        (c.ctx.random.nextDouble() * (max - min + 1)).floorToDouble() + min);
  });
  reg(['dice'], (c, a, r) {
    final notation = a[0].split('d');
    final num = Js.number(notation[0]);
    final sides = Js.number(_arg(notation, 1));
    if (num.isNaN || sides.isNaN) return 'NaN';
    var total = 0;
    for (var i = 0; i < num; i++) {
      total += (c.ctx.random.nextDouble() * sides).floor() + 1;
    }
    return '$total';
  });
  reg(['hash'], (c, a, r) =>
      Js.toFixed(pickHashRand(0, a[0]) * 10000000 + 1, 0).padLeft(7, '0'));

  // ── Strings ──
  reg(['startswith'], (c, a, r) => _bool(a[0].startsWith(a[1])));
  reg(['endswith'], (c, a, r) => _bool(a[0].endsWith(a[1])));
  reg(['contains'], (c, a, r) => _bool(a[0].contains(a[1])));
  reg(['replace'], (c, a, r) => a[0].replaceAll(a[1], a[2]));
  reg(['split'], (c, a, r) => cbsMakeArray(a[0].split(a[1])));
  reg(['join'], (c, a, r) => cbsParseArray(a[0])
      .map((e) => e == null ? '' : _elementText(e))
      .join(_arg(a, 1) ?? ','));
  reg(['spread'], (c, a, r) =>
      cbsParseArray(a[0]).map((e) => e == null ? '' : _elementText(e)).join('::'));
  reg(['trim'], (c, a, r) => a[0].trim());
  reg(['length'], (c, a, r) => '${a[0].length}');
  reg(['lower'], (c, a, r) => a[0].toLowerCase());
  reg(['upper'], (c, a, r) => a[0].toUpperCase());
  reg(['capitalize'], (c, a, r) =>
      a[0].isEmpty ? '' : a[0][0].toUpperCase() + a[0].substring(1));
  reg(['reverse'], (c, a, r) =>
      String.fromCharCodes((_arg(a, 0) ?? '').runes.toList().reversed));
  reg(['unicodeencode', 'unicode_encode'], (c, a, r) {
    final index = (_arg(a, 1)?.isNotEmpty ?? false) ? Js.number(a[1]) : 0.0;
    final i = index.isNaN ? 0 : index.truncate();
    if (i < 0 || i >= a[0].length) return 'NaN';
    return '${a[0].codeUnitAt(i)}';
  });
  String fromCharCode(double v) =>
      String.fromCharCode(v.isNaN || v.isInfinite ? 0 : Js.toUint32(v) & 0xFFFF);
  reg(['unicodedecode', 'unicode_decode'], (c, a, r) => fromCharCode(_num(a, 0)));
  reg(['u', 'unicodedecodefromhex'], (c, a, r) => fromCharCode(Js.parseInt(a[0], 16)));
  reg(['ue', 'unicodeencodefromhex'], (c, a, r) => fromCharCode(Js.parseInt(a[0], 16)));
  reg(['crypt', 'crypto', 'caesar', 'encrypt', 'decrypt'], (c, a, r) {
    var shift = (_arg(a, 1)?.isNotEmpty ?? false) ? Js.number(a[1]) : 32768.0;
    if (shift.isNaN) shift = 32768;
    final out = StringBuffer();
    for (final unit in a[0].codeUnits) {
      var shifted = unit + shift.truncate();
      if (shifted > 65535) shifted -= 65536;
      out.writeCharCode(shifted & 0xFFFF);
    }
    return out.toString();
  });
  reg(['xor', 'xorencrypt', 'xorencode', 'xore'], (c, a, r) =>
      base64Encode(utf8.encode(a[0]).map((b) => b ^ 0xFF).toList()));
  reg(['xordecrypt', 'xordecode', 'xord'], (c, a, r) {
    final bytes = base64Decode(base64.normalize(
        a[0].replaceAll(RegExp(r'[^A-Za-z0-9+/=_-]'), '')));
    return utf8.decode(bytes.map((b) => b ^ 0xFF).toList(), allowMalformed: true);
  });

  // ── Arrays / dicts ──
  reg(['arraylength'], (c, a, r) => '${cbsParseArray(a[0]).length}');
  reg(['arrayelement'], (c, a, r) {
    final arr = cbsParseArray(a[0]);
    final i = Js.atIndex(arr.length, _num(a, 1));
    return _elementText(i == null ? 'null' : (arr[i] ?? 'null'));
  });
  reg(['dictelement', 'objectelement'], (c, a, r) =>
      _elementText(_index(_parseDict(a[0]), a[1]) ?? 'null'));
  reg(['objectassert', 'dictassert', 'object_assert'], (c, a, r) {
    final dict = _parseDict(a[0]);
    if (dict is Map && !Js.truthy(dict[a[1]])) dict[a[1]] = _arg(a, 2);
    return Js.jsonStringify(dict);
  });
  reg(['element', 'ele'], (c, a, r) {
    Object? current = a[0];
    for (final key in a.sublist(1)) {
      if (current is! String) return 'null';
      final parsed = jsonDecode(current);
      if (parsed is! Map && parsed is! List) return 'null';
      current = _index(parsed, key);
      if (!Js.truthy(current)) return 'null';
    }
    return current is String ? current : _elementText(current);
  });
  reg(['arrayshift'], (c, a, r) {
    final arr = cbsParseArray(a[0]);
    if (arr.isNotEmpty) arr.removeAt(0);
    return cbsMakeArray(arr);
  });
  reg(['arraypop'], (c, a, r) {
    final arr = cbsParseArray(a[0]);
    if (arr.isNotEmpty) arr.removeLast();
    return cbsMakeArray(arr);
  });
  reg(['arraypush'], (c, a, r) =>
      cbsMakeArray([...cbsParseArray(a[0]), _arg(a, 1)]));
  reg(['arraysplice'], (c, a, r) {
    final arr = cbsParseArray(a[0]);
    final rawStart = _num(a, 1);
    var start = rawStart.isNaN ? 0 : rawStart.truncate();
    if (start < 0) start = math.max(arr.length + start, 0);
    if (start > arr.length) start = arr.length;
    final rawDelete = _num(a, 2);
    final delete = (rawDelete.isNaN ? 0 : rawDelete.truncate())
        .clamp(0, arr.length - start);
    arr.replaceRange(start, start + delete, [_arg(a, 3)]);
    return cbsMakeArray(arr);
  });
  reg(['arrayassert'], (c, a, r) {
    final arr = cbsParseArray(a[0]);
    final index = _num(a, 1);
    if (!index.isNaN && index == index.truncateToDouble() && index >= arr.length) {
      while (arr.length < index) {
        arr.add(null);
      }
      arr.add(_arg(a, 2));
    }
    return cbsMakeArray(arr);
  });
  reg(['makearray', 'array', 'a'], (c, a, r) => cbsMakeArray(a));
  reg(['makedict', 'dict', 'd', 'makeobject', 'object', 'o'], (c, a, r) {
    final out = <String, Object?>{};
    for (final current in a) {
      final eq = current.indexOf('=');
      if (eq == -1) continue;
      out[current.substring(0, eq)] = current.substring(eq + 1);
    }
    return Js.jsonStringify(out);
  });
  reg(['range'], (c, a, r) {
    final arr = cbsParseArray(a[0]);
    final start = arr.length > 1 ? _jsonNumber(arr[0]) : 0.0;
    final end = arr.length > 1 ? _jsonNumber(arr[1]) : _jsonNumber(arr[0]);
    final step = arr.length > 2 ? _jsonNumber(arr[2]) : 1.0;
    final out = <String>[];
    for (var i = start; i < end && out.length < 100000; i += step) {
      out.add(Js.numToString(i));
      if (step <= 0 || step.isNaN) break;
    }
    return cbsMakeArray(out);
  });
  reg(['filter'], (c, a, r) {
    final arr = cbsParseArray(a[0]);
    final mode = ['all', 'nonempty', 'unique'].indexOf(_arg(a, 1) ?? '');
    final kept = <Object?>[];
    for (var i = 0; i < arr.length; i++) {
      final v = arr[i];
      final first = arr.indexWhere((e) => e == v) == i;
      final nonEmpty = v != '';
      final keep = switch (mode) { 1 => nonEmpty, 2 => first, _ => nonEmpty && first };
      if (keep) kept.add(v);
    }
    return cbsMakeArray(kept);
  });

  // ── Formatting / escapes / display ──
  reg(['cbr', 'cnl', 'cnewline'], (c, a, r) {
    if (a.isEmpty) return r'\n';
    final n = _num(a, 0);
    return r * (n.isNaN || n < 1 ? 1 : n.truncate());
  });
  reg(['decbo', 'displayescapedcurlybracketopen'], (c, a, r) => '');
  reg(['decbc', 'displayescapedcurlybracketclose'], (c, a, r) => '');
  reg(['bo', 'ddecbo', 'doubledisplayescapedcurlybracketopen'],
      (c, a, r) => '');
  reg(['bc', 'ddecbc', 'doubledisplayescapedcurlybracketclose'],
      (c, a, r) => '');
  reg(['displayescapedbracketopen', 'debo', '('], (c, a, r) => '');
  reg(['displayescapedbracketclose', 'debc', ')'], (c, a, r) => '');
  reg(['displayescapedanglebracketopen', 'deabo', '<'], (c, a, r) => '');
  reg(['displayescapedanglebracketclose', 'deabc', '>'], (c, a, r) => '');
  reg(['displayescapedcolon', 'dec', ':'], (c, a, r) => '');
  reg(['displayescapedsemicolon', ';'], (c, a, r) => '');
  reg(['button'], (c, a, r) =>
      '<button class="button-default" risu-trigger="${_arg(a, 1)}">${a[0]}</button>');
  reg(['risu'], (c, a, r) {
    final size = (_arg(a, 0)?.isNotEmpty ?? false) ? a[0] : '45';
    return '<img src="/logo2.png" style="height:${size}px;width:${size}px" />';
  });
  reg(['file'], (c, a, r) => c.run.displaying
      ? '<br><div class="risu-file">${a[0]}</div><br>'
      : utf8.decode(base64Decode(base64.normalize(a[1])), allowMalformed: true));
  reg(['comment'], (c, a, r) =>
      c.run.displaying ? '<div class="risu-comment">${a[0]}</div>' : '');
  reg(['tex', 'latex', 'katex'], (c, a, r) => '\$\$${_arg(a, 0)}\$\$');
  reg(['ruby', 'furigana'], (c, a, r) =>
      '<ruby>${a[0]}<rp> (</rp><rt>${_arg(a, 1)}</rt><rp>) </rp></ruby>');
  reg(['codeblock'], (c, a, r) {
    final code = a.last
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;');
    if (a.length > 1) {
      return '<pre-hljs-placeholder lang="${a[0]}">$code</pre-hljs-placeholder>';
    }
    return '<pre><code>$code</code></pre>';
  });
  reg(['hiddenkey'], (c, a, r) => '');
  reg(['bkspc'], (c, a, r) {
    var root = c.root;
    if (root.isEmpty) return '';
    root = root.trimRight();
    var p = root.length - 1;
    for (; p >= 0; p--) {
      if (p == 0) break;
      final ch = root[p];
      if (ch == ' ' || ch == '\n' || ch == '\t') break;
    }
    c.root = root.substring(0, p < 0 ? 0 : p).trimRight();
    return '';
  });
  reg(['erase'], (c, a, r) {
    var root = c.root;
    if (root.isEmpty) return '';
    root = root.trimRight();
    var p = root.length - 1;
    var sentenceEnd = false;
    for (; p >= 0; p--) {
      final ch = root[p];
      if (ch == '.' || ch == '!' || ch == '?' || ch == '\n') {
        sentenceEnd = true;
        break;
      }
      if (p == 0) break;
    }
    if (p < 0) {
      p = 0;
    } else if (sentenceEnd) {
      p += 1;
    }
    c.root = root.substring(0, p).trimRight();
    return '';
  });
  reg(['__'], (c, a, r) => '');

  return f;
}

CbsMessage? _messageAt(CbsCall c) {
  final id = c.run.chatId;
  if (id < 0 || id >= c.ctx.messages.length) return null;
  return c.ctx.messages[id];
}
