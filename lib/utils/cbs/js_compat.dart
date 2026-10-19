import 'dart:convert';
import 'dart:math' as math;

/// JavaScript value semantics that RisuAI's CBS functions rely on.
///
/// CBS was written against JS coercion rules (`Number('')` is 0,
/// `parseFloat('12abc')` is 12, `(1).toString()` is "1"). Reproducing them
/// keeps imported RisuAI templates producing the same text here.
class Js {
  Js._();

  static final RegExp _decimalLiteral =
      RegExp(r'^[+-]?(\d+\.?\d*|\.\d+)([eE][+-]?\d+)?$');
  static final RegExp _floatPrefix =
      RegExp(r'^[+-]?(Infinity|(\d+\.?\d*|\.\d+)([eE][+-]?\d+)?)');

  /// `Number(value)`; `null` stands in for `undefined`.
  static double number(String? value) {
    if (value == null) return double.nan;
    final s = value.trim();
    if (s.isEmpty) return 0;
    if (s == 'Infinity' || s == '+Infinity') return double.infinity;
    if (s == '-Infinity') return double.negativeInfinity;
    final radix = RegExp(r'^0([xXoObB])([0-9a-fA-F]+)$').firstMatch(s);
    if (radix != null) {
      final base = switch (radix.group(1)!.toLowerCase()) {
        'x' => 16,
        'o' => 8,
        _ => 2,
      };
      final parsed = BigInt.tryParse(radix.group(2)!, radix: base);
      return parsed == null ? double.nan : parsed.toDouble();
    }
    if (!_decimalLiteral.hasMatch(s)) return double.nan;
    return double.parse(s);
  }

  /// `parseFloat(value)`: the longest leading decimal literal.
  static double parseFloat(String? value) {
    if (value == null) return double.nan;
    final m = _floatPrefix.firstMatch(value.trimLeft());
    if (m == null) return double.nan;
    final text = m.group(0)!;
    if (text.endsWith('Infinity')) {
      return text.startsWith('-') ? double.negativeInfinity : double.infinity;
    }
    return double.parse(text);
  }

  /// `parseInt(value, radix)`; an omitted radix auto-detects a `0x` prefix.
  static double parseInt(String? value, [int? radix]) {
    if (value == null) return double.nan;
    var s = value.trimLeft();
    var sign = 1;
    if (s.startsWith('-') || s.startsWith('+')) {
      if (s.startsWith('-')) sign = -1;
      s = s.substring(1);
    }
    final hasHexPrefix = s.startsWith('0x') || s.startsWith('0X');
    final base = radix ?? (hasHexPrefix ? 16 : 10);
    if (base == 16 && hasHexPrefix) s = s.substring(2);
    final digits = RegExp('^[${_digitClass(base)}]+').firstMatch(s);
    if (digits == null) return double.nan;
    return sign * BigInt.parse(digits.group(0)!, radix: base).toDouble();
  }

  static String _digitClass(int radix) {
    if (radix <= 10) return '0-${radix - 1}';
    final last = String.fromCharCode('a'.codeUnitAt(0) + radix - 11);
    return '0-9a-${last}A-${last.toUpperCase()}';
  }

  /// `Number.prototype.toString()` for the values CBS produces.
  static String numToString(num value) {
    final d = value.toDouble();
    if (d.isNaN) return 'NaN';
    if (d.isInfinite) return d > 0 ? 'Infinity' : '-Infinity';
    if (d == d.truncateToDouble() && d.abs() < 1e21) {
      return BigInt.from(d).toString();
    }
    var s = d.toString();
    // Dart prints 1e-7 as "1e-7" and 1e21 as "1e+21", matching JS.
    if (s.contains('e') && !s.contains('e-') && !s.contains('e+')) {
      s = s.replaceFirst('e', 'e+');
    }
    return s;
  }

  /// `Number.prototype.toFixed(digits)`.
  static String toFixed(double value, double digits) {
    final n = digits.isNaN ? 0 : digits.truncate();
    if (n < 0 || n > 100) throw RangeError('toFixed() digits out of range');
    if (value.isNaN) return 'NaN';
    if (value.abs() >= 1e21 || value.isInfinite) return numToString(value);
    return value.toStringAsFixed(n > 20 ? 20 : n);
  }

  /// `Math.round`: halves round toward +Infinity.
  static double round(double x) {
    if (x.isNaN || x.isInfinite) return x;
    var r = x.floorToDouble();
    if (x - r >= 0.5) r += 1;
    return r;
  }

  /// `String(value)` for decoded JSON values.
  static String stringOf(Object? value) {
    if (value == null) return 'null';
    if (value is String) return value;
    if (value is num) return numToString(value);
    if (value is bool) return value.toString();
    return jsonStringify(value);
  }

  /// `JSON.stringify` with JS number formatting (1.0 prints as "1").
  static String jsonStringify(Object? value) => jsonEncode(_jsNumbers(value));

  static Object? _jsNumbers(Object? value) {
    if (value is double && value == value.truncateToDouble() && value.abs() < 9e15) {
      return value.toInt();
    }
    if (value is List) return value.map(_jsNumbers).toList();
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), _jsNumbers(v)));
    }
    return value;
  }

  /// JS truthiness for values that flow through the calculator.
  static bool truthy(Object? value) {
    if (value == null) return false;
    if (value is num) return value != 0 && !value.isNaN;
    if (value is String) return value.isNotEmpty;
    if (value is bool) return value;
    return true;
  }

  /// `ToInt32`.
  static int toInt32(num x) {
    final d = x.toDouble();
    if (d.isNaN || d.isInfinite) return 0;
    final i = BigInt.from(d.truncateToDouble()) & BigInt.from(0xFFFFFFFF);
    return i.toInt().toSigned(32);
  }

  /// `ToUint32`.
  static int toUint32(num x) => toInt32(x) & 0xFFFFFFFF;

  /// Array index semantics of `Array.prototype.at`.
  static int? atIndex(int length, double index) {
    var i = index.isNaN ? 0 : index.truncate();
    if (i < 0) i += length;
    if (i < 0 || i >= length) return null;
    return i;
  }

  static const List<String> _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June', 'July',
    'August', 'September', 'October', 'November', 'December',
  ];
  static const List<String> _weekdayNames = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
  ];

  static String monthLong(DateTime d) => _monthNames[d.month - 1];
  static String monthShort(DateTime d) => monthLong(d).substring(0, 3);
  static String weekdayLong(DateTime d) => _weekdayNames[d.weekday - 1];
  static String weekdayShort(DateTime d) => weekdayLong(d).substring(0, 3);
}

/// Port of RisuAI's `calcString` (process/infunctions.ts): a shunting-yard
/// evaluator over + - * / ^ % < > <= >= == != && || ! with `$var` and
/// `@globalvar` substitution. Returns null where JS would yield `undefined`.
class CbsCalculator {
  CbsCalculator._();

  static const Map<String, (int, bool)> _operators = {
    '+': (2, true), '-': (2, true), '*': (3, true), '/': (3, true),
    '^': (4, true), '%': (3, true), '<': (1, true), '>': (1, true),
    '|': (1, true), '&': (1, true), '≤': (1, true), '≥': (1, true),
    '=': (1, true), '≠': (1, true), '!': (5, false),
  };

  static double? calc(
    String text, {
    required String Function(String) chatVar,
    required String Function(String) globalVar,
  }) {
    final depth = <StringBuffer>[StringBuffer()];
    for (var i = 0; i < text.length; i++) {
      final ch = text[i];
      if (ch == '(') {
        depth.add(StringBuffer());
      } else if (ch == ')' && depth.length > 1) {
        final inner = depth.removeLast().toString();
        depth.last.write(Js.numToString(
            _execute(inner, chatVar, globalVar) ?? double.nan));
      } else {
        depth.last.write(ch);
      }
    }
    return _execute(depth.map((b) => b.toString()).join(), chatVar, globalVar);
  }

  static double? _execute(
    String text,
    String Function(String) chatVar,
    String Function(String) globalVar,
  ) {
    String asNumber(String v) {
      final parsed = Js.parseFloat(v);
      return parsed.isNaN ? '0' : Js.numToString(parsed);
    }

    final prepared = text
        .replaceAllMapped(RegExp(r'\$([a-zA-Z0-9_]+)'), (m) => asNumber(chatVar(m[1]!)))
        .replaceAllMapped(RegExp(r'@([a-zA-Z0-9_]+)'), (m) => asNumber(globalVar(m[1]!)))
        .replaceAll('&&', '&')
        .replaceAll('||', '|')
        .replaceAll('<=', '≤')
        .replaceAll('>=', '≥')
        .replaceAll('==', '=')
        .replaceAll('!=', '≠')
        .replaceAll(RegExp('null', caseSensitive: false), '0');
    return _calculateRpn(_toRpn(prepared));
  }

  static bool _isNumberToken(String token) =>
      token == '0' || Js.truthy(Js.parseFloat(token));

  static String _toRpn(String raw) {
    final expression = raw.replaceAll(RegExp(r'\s+'), '');
    final tokens = <String>[];
    var last = '';
    for (var i = 0; i < expression.length; i++) {
      final ch = expression[i];
      if (ch == '-' &&
          (i == 0 ||
              _operators.containsKey(expression[i - 1]) ||
              expression[i - 1] == '(')) {
        last += ch;
      } else if (_operators.containsKey(ch)) {
        tokens.add(last.isNotEmpty ? last : '0');
        last = '';
        tokens.add(ch);
      } else {
        last += ch;
      }
    }
    tokens.add(last.isNotEmpty ? last : '0');

    final output = <String>[];
    final stack = <String>[];
    for (final token in tokens) {
      if (_isNumberToken(token)) {
        output.add(token);
      } else if (_operators.containsKey(token)) {
        final (precedence, leftAssoc) = _operators[token]!;
        while (stack.isNotEmpty) {
          final top = _operators[stack.last]!.$1;
          final pop = leftAssoc ? precedence <= top : precedence < top;
          if (!pop) break;
          output.add(stack.removeLast());
        }
        stack.add(token);
      }
    }
    while (stack.isNotEmpty) {
      output.add(stack.removeLast());
    }
    return output.join(' ');
  }

  static double? _calculateRpn(String expression) {
    final stack = <double?>[];
    double? pop() => stack.isEmpty ? null : stack.removeLast();
    double n(double? v) => v ?? double.nan;

    for (final token in expression.split(' ')) {
      if (_isNumberToken(token)) {
        stack.add(Js.parseFloat(token));
        continue;
      }
      final b = pop();
      final a = pop();
      switch (token) {
        case '+':
          stack.add(n(a) + n(b));
        case '-':
          stack.add(n(a) - n(b));
        case '*':
          stack.add(n(a) * n(b));
        case '/':
          stack.add(n(a) / n(b));
        case '^':
          stack.add(math.pow(n(a), n(b)).toDouble());
        case '%':
          stack.add(n(a).remainder(n(b)));
        case '<':
          stack.add(n(a) < n(b) ? 1 : 0);
        case '>':
          stack.add(n(a) > n(b) ? 1 : 0);
        case '|':
          stack.add(Js.truthy(a) ? a : b);
        case '&':
          stack.add(Js.truthy(a) ? b : a);
        case '≤':
          stack.add(n(a) <= n(b) ? 1 : 0);
        case '≥':
          stack.add(n(a) >= n(b) ? 1 : 0);
        case '=':
          stack.add(n(a) == n(b) ? 1 : 0);
        case '≠':
          stack.add(n(a) != n(b) ? 1 : 0);
        case '!':
          stack.add(Js.truthy(b) ? 0 : 1);
      }
    }
    if (stack.isEmpty) return 0;
    return stack.removeLast();
  }
}

/// Port of RisuAI's `pickHashRand` + `sfc32` (util.ts): a seeded value in
/// [0, 1) that stays fixed for the same seed word and message count.
double pickHashRand(int cid, String word) {
  double hashAddress = 5515;
  double hash(String w) {
    for (final unit in w.codeUnits) {
      final shifted = Js.toInt32(Js.toInt32(hashAddress) << 5);
      hashAddress = shifted + hashAddress + unit;
    }
    return hashAddress;
  }

  final next = _sfc32(hash(word), hash(word), hash(word), hash(word));
  final skip = cid % 1000;
  for (var i = 0; i < skip; i++) {
    next();
  }
  return next();
}

double Function() _sfc32(double a0, double b0, double c0, double d0) {
  var a = Js.toInt32(a0), b = Js.toInt32(b0);
  var c = Js.toInt32(c0), d = Js.toInt32(d0);
  return () {
    final t = Js.toInt32(Js.toInt32(a + b) + d);
    d = Js.toInt32(d + 1);
    a = Js.toInt32(b ^ (Js.toUint32(b) >> 9));
    b = Js.toInt32(c + Js.toInt32(c << 3));
    c = Js.toInt32(Js.toInt32(c << 21) | (Js.toUint32(c) >> 11));
    c = Js.toInt32(c + t);
    return Js.toUint32(t) / 4294967296;
  };
}
