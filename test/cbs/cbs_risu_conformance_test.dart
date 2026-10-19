// Expectations ported from RisuAI's own CBS tests
// (src/ts/parser/tests/cbs/{conditionals,loop,escapes,strings}.test.ts).
// Property-based (fast-check) cases are represented by fixed samples.

import 'dart:convert';

import 'package:flan/utils/cbs/cbs_context.dart';
import 'package:flan/utils/cbs/cbs_parser.dart';
import 'package:flutter_test/flutter_test.dart';

/// RisuAI's test store: reading a variable returns its own key, with the
/// `toggle_` prefix stripped for globals.
CbsContext _echoVars() => CbsContext(
      chatVarReader: (key) => key,
      globalVarReader: (key) =>
          key.startsWith('toggle_') ? key.substring('toggle_'.length) : 'null',
    );

String _parse(String text, [CbsContext? ctx]) =>
    CbsParser.render(text, CbsRun(ctx ?? _echoVars()));

String _template(String op, String body) => '0 {{$op}}$body{{/}} 9';
String _quick(String op, String body) => _parse(_template(op, body));

const _indentedBody = '\n\n  C  \n  B  \n  S  \n\n';

void main() {
  group('#if', () {
    test('renders when "1" or "true"', () {
      expect(_quick('#if 1', 'CBS'), '0 CBS 9');
      expect(_quick('#if true', 'CBS'), '0 CBS 9');
      expect(_quick('#if 1 trailing words', 'CBS'), '0 CBS 9');
    });
    test('does not render otherwise, including extra leading spaces', () {
      expect(_quick('#if 0', 'CBS'), '0  9');
      expect(_quick('#if false', 'CBS'), '0  9');
      expect(_quick('#if  1', 'CBS'), '0  9');
      expect(_quick('#if   true', 'CBS'), '0  9');
      expect(_quick('#if yes', 'CBS'), '0  9');
    });
    test('trims block ends and the start of each line', () {
      expect(_quick('#if 1', _indentedBody), '0 C  \nB  \nS 9');
    });
    test('can be nested', () {
      expect(_quick('#if 1', _template('#if 1', 'CBS')), '0 0 CBS 9 9');
      expect(_quick('#if 1', _template('#if 0', 'CBS')), '0 0  9 9');
      expect(_quick('#if 0', _template('#if 1', 'CBS')), '0  9');
      expect(_quick('#if 0', _template('#if 0', 'CBS')), '0  9');
    });
  });

  group('#if_pure', () {
    test('renders when truthy, keeps whitespace', () {
      expect(_quick('#if_pure 1', 'CBS'), '0 CBS 9');
      expect(_quick('#if_pure true', 'CBS'), '0 CBS 9');
      expect(_quick('#if_pure 1', _template('#if_pure 1', _indentedBody)),
          '0 0 $_indentedBody 9 9');
    });
    test('does not render otherwise', () {
      expect(_quick('#if_pure 0', 'CBS'), '0  9');
      expect(_quick('#if_pure false', 'CBS'), '0  9');
      expect(_quick('#if_pure  1', 'CBS'), '0  9');
      expect(_quick('#if_pure 1', _template('#if_pure 0', _indentedBody)),
          '0 0  9 9');
      expect(_quick('#if_pure 0', _template('#if_pure 1', _indentedBody)),
          '0  9');
    });
  });

  group('#when', () {
    test('truthy and falsy', () {
      expect(_quick('#when::1', 'CBS'), '0 CBS 9');
      expect(_quick('#when::true', 'CBS'), '0 CBS 9');
      expect(_quick('#when::0', 'CBS'), '0  9');
      expect(_quick('#when::false', 'CBS'), '0  9');
      expect(_quick('#when::yes', 'CBS'), '0  9');
    });
    test('removes line breaks at block start/end only', () {
      expect(_quick('#when::1', _indentedBody),
          '0 ${_indentedBody.replaceAll(RegExp(r'^\n+|\n+$'), '')} 9');
    });
    test('can be nested and can omit ::', () {
      expect(_quick('#when 1', _template('#when 1', 'CBS')), '0 0 CBS 9 9');
      expect(_quick('#when 1', _template('#when 0', 'CBS')), '0 0  9 9');
      expect(_quick('#when 0', _template('#when 1', 'CBS')), '0  9');
      expect(_quick('#when 1', 'CBS'), '0 CBS 9');
      expect(_quick('#when 0', 'CBS'), '0  9');
    });
    test('is / isnot', () {
      for (final (a, b) in [('apple', 'pear'), ('1', '2'), ('가', '나')]) {
        expect(_quick('#when::$a::is::$a', 'CBS'), '0 CBS 9');
        expect(_quick('#when::$a::is::$b', 'CBS'), '0  9');
        expect(_quick('#when::$a::isnot::$a', 'CBS'), '0  9');
        expect(_quick('#when::$a::isnot::$b', 'CBS'), '0 CBS 9');
      }
    });
    test('> >= <= <', () {
      for (final (a, b) in [(5, 3), (0, -7), (100, 99)]) {
        expect(_quick('#when::$a::>::$a', 'CBS'), '0  9');
        expect(_quick('#when::$a::>::$b', 'CBS'), '0 CBS 9');
        expect(_quick('#when::$b::>::$a', 'CBS'), '0  9');
        expect(_quick('#when::$a::>=::$a', 'CBS'), '0 CBS 9');
        expect(_quick('#when::$a::>=::$b', 'CBS'), '0 CBS 9');
        expect(_quick('#when::$b::>=::$a', 'CBS'), '0  9');
        expect(_quick('#when::$a::<=::$a', 'CBS'), '0 CBS 9');
        expect(_quick('#when::$a::<=::$b', 'CBS'), '0  9');
        expect(_quick('#when::$b::<=::$a', 'CBS'), '0 CBS 9');
        expect(_quick('#when::$a::<::$a', 'CBS'), '0  9');
        expect(_quick('#when::$a::<::$b', 'CBS'), '0  9');
        expect(_quick('#when::$b::<::$a', 'CBS'), '0 CBS 9');
      }
    });
    test('and / or / not, folded right to left', () {
      expect(_quick('#when::1::and::1', 'CBS'), '0 CBS 9');
      expect(_quick('#when::1::and::not::true', 'CBS'), '0  9');
      expect(_quick('#when::1::and::0', 'CBS'), '0  9');
      expect(_quick('#when::1::and::not::false', 'CBS'), '0 CBS 9');
      expect(_quick('#when::0::or::1', 'CBS'), '0 CBS 9');
      expect(_quick('#when::0::or::not::true', 'CBS'), '0  9');
      expect(_quick('#when::0::or::0', 'CBS'), '0  9');
      expect(_quick('#when::0::or::not::false', 'CBS'), '0 CBS 9');
      expect(_quick('#when::1::or::0::and::0', 'CBS'), '0 CBS 9');
      expect(_quick('#when::0::or::1::and::0', 'CBS'), '0  9');
      expect(_quick('#when::0::or::0::and::1', 'CBS'), '0  9');
      expect(_quick('#when::1::and::1::or::0', 'CBS'), '0 CBS 9');
      expect(_quick('#when::1::and::0::or::1', 'CBS'), '0 CBS 9');
      expect(_quick('#when::0::and::1::or::1', 'CBS'), '0  9');
    });
    test('keep and legacy whitespace modes', () {
      expect(_quick('#when::keep::1', _indentedBody), '0 $_indentedBody 9');
      expect(_quick('#when::legacy::1', _indentedBody), '0 C  \nB  \nS 9');
    });
    test('var / toggle / vis / visnot / tis / tisnot', () {
      expect(_quick('#when::var::true', 'CBS'), '0 CBS 9');
      expect(_quick('#when::toggle::true', 'CBS'), '0 CBS 9');
      expect(_quick('#when::var::nope', 'CBS'), '0  9');
      expect(_quick('#when::toggle::nope', 'CBS'), '0  9');
      for (final (a, b) in [('x', 'y'), ('hp', 'mp')]) {
        expect(_quick('#when::$a::vis::$a', 'CBS'), '0 CBS 9');
        expect(_quick('#when::$a::vis::$b', 'CBS'), '0  9');
        expect(_quick('#when::$a::tis::$a', 'CBS'), '0 CBS 9');
        expect(_quick('#when::$a::tis::$b', 'CBS'), '0  9');
        expect(_quick('#when::$a::visnot::$a', 'CBS'), '0  9');
        expect(_quick('#when::$a::visnot::$b', 'CBS'), '0 CBS 9');
        expect(_quick('#when::$a::tisnot::$a', 'CBS'), '0  9');
        expect(_quick('#when::$a::tisnot::$b', 'CBS'), '0 CBS 9');
      }
    });
    test(':else on one line and across lines', () {
      expect(_quick('#when::1', 'CBS{{:else}}SBC'), '0 CBS 9');
      expect(_quick('#when::0', 'CBS{{:else}}SBC'), '0 SBC 9');
      expect(_quick('#when::1', 'CBS\n{{:else}}\nSBC'), '0 CBS 9');
      expect(_quick('#when::0', 'CBS\n{{:else}}\nSBC'), '0 SBC 9');
    });
    test(':else with ::keep (upstream FIXMEs preserved)', () {
      final rev = String.fromCharCodes(_indentedBody.runes.toList().reversed);
      expect(_quick('#when::keep::1', '$_indentedBody{{:else}}$rev'),
          '0 ${_indentedBody.replaceAll(RegExp(r'\n$'), '')} 9');
      expect(_quick('#when::keep::0', '$_indentedBody{{:else}}$rev'),
          '0 ${rev.replaceAll(RegExp(r'^\n'), '')} 9');
    });
    test(':else in and out of a nested #when', () {
      String nested(String a, String b) => '{{#when $a}}\n'
          '{{#when $b}}CBS{{:else}}SBC{{/}}\n'
          '{{:else}}\n'
          'ABC\n'
          '{{/}}';
      expect(_parse(nested('1', '1')), 'CBS');
      expect(_parse(nested('1', '0')), 'SBC');
      expect(_parse(nested('0', '1')), 'ABC');
      expect(_parse(nested('0', '0')), 'ABC');
    });
    test(':else inside #each', () {
      const t = '{{#each [1, 2, 3] as n}}\n'
          '{{#when::n::is::2}}\n'
          'CBS{{slot::n}}\n'
          '{{:else}}\n'
          'SBC{{slot::n}}\n'
          '{{/}}\n'
          '{{/}}';
      expect(_parse(t), 'SBC1SBC2SBC3');
    });
  });

  group('#each', () {
    late CbsContext store;
    setUp(() => store = CbsContext());
    String each(String op, String body) => _parse('{{$op}}$body{{/}}', store);

    test('loops over literals and variables', () {
      expect(each('#each [1, 2, 3] as n', '{{slot::n}} '), '123');
      store.chatVars['arr'] = jsonEncode([1, 2, 3]);
      expect(each('#each {{getvar::arr}} as n', '{{slot::n}} '), '123');
    });
    test('2D arrays, nested loops, ::keep', () {
      expect(
          each('#each::keep [[1, 2], [3, 4]] as x',
              '{{#each::keep {{slot::x}} as y}}{{slot::y}}\n{{/}}'),
          '1\n2\n3\n4\n');
      store.chatVars['arr'] = jsonEncode([[1, 2], [3, 4]]);
      expect(
          each('#each::keep {{getvar::arr}} as x',
              '{{#each::keep {{slot::x}} as y}}{{slot::y}}\n{{/}}'),
          '1\n2\n3\n4\n');
      expect(
          each('#each::keep [1, 2] as x',
              '{{#each::keep [3, 4] as y}}{{slot::x}}{{slot::y}}\n{{/}}'),
          '13\n14\n23\n24\n');
      expect(each('#each::keep [1, 2, 3] as n', '  - {{slot::n}}\n'),
          '  - 1\n  - 2\n  - 3\n');
    });
    test('empty array, non-arrays passed through, body trimmed', () {
      expect(each('#each [] as n', '{{slot::n}} '), '');
      expect(each('#each a,b,c as n', '{{slot::n}} '), 'a,b,c');
      expect(each('#each {{getvar::aa}} as n', '{{slot::n}} '), 'null');
      expect(each('#each [1][2] as n', '{{slot::n}} '), '[1][2]');
      expect(each('#each [1, 2, 3] as n', ' \n - {{slot::n}}\n  '), '- 1- 2- 3');
    });
    test('works in #when ... :else and without "as"', () {
      String t(String a) => '{{#when $a}}\n{{#each [1, 2, 3] as n}}{{slot::n}}{{/}}'
          '\n{{:else}}\n{{#each [3, 2, 1] as n}}{{slot::n}}{{/}}\n{{/}}';
      expect(_parse(t('1'), store), '123');
      expect(_parse(t('0'), store), '321');
      expect(each('#each [1, 2, 3] n', '{{slot::n}} '), '123');
    });
  });

  group('escapes', () {
    String p(String s) => cbsUnescape(_parse(s));
    test('brackets and line breaks', () {
      expect(p('{{bo}}'), '{{');
      expect(p('{{bc}}'), '}}');
      expect(p('{{br}}'), '\n');
      expect(p('{{cbr}}'), r'\n');
      expect(p('{{cbr::3}}'), 'cbr::3cbr::3cbr::3'); // upstream FIXME
      expect(p('{{decbo}}'), '{');
      expect(p('{{decbc}}'), '}');
      expect(p('{{;}}'), ';');
      expect(p('{{(}}'), '(');
      expect(p('{{)}}'), ')');
      expect(p('{{<}}'), '&lt;');
      expect(p('{{>}}'), '&gt;');
    });
    test('#pure, #puredisplay, #escape', () {
      for (final a in ['  plain text  ', 'a {{getvar::x}} b', ' (x) ']) {
        expect(p('{{#pure}}$a{{/}}'), a.trim());
        expect(p('{{#puredisplay}}$a{{/}}'),
            a.trim().replaceAll('{{', r'\{\{').replaceAll('}}', r'\}\}'));
      }
      for (final a in ['plain text', '(x) [y]']) {
        expect(p('{{#escape}}\n$a\n{{/}}'), a.trim());
        expect(p('{{#escape::keep}}\n$a\n{{/}}'), '\n$a\n');
      }
    });
  });

  group('strings', () {
    String q(String op, List<Object> args) =>
        _parse('{{$op${args.isEmpty ? '' : '::'}${args.join('::')}}}');
    test('predicates, replace, split, trim, length, case, reverse', () {
      expect(q('startswith', ['Hello World', 'Hello']), '1');
      expect(q('endswith', ['Hello World', 'World']), '1');
      expect(q('contains', ['Hello World', 'lo Wo']), '1');
      expect(q('startsWith', ['abc', 'b']), '0');
      expect(q('replace', ['Hello World', 'o', '0']), 'Hell0 W0rld');
      expect(q('split', ['apple,banana,cherry', ',']),
          jsonEncode(['apple', 'banana', 'cherry']));
      expect(q('trim', ['  hello world  ']), 'hello world');
      expect(q('trim', ['  hello  \n  world  ']), 'hello  \n  world');
      expect(q('length', ['Hello']), '5');
      expect(q('capitalize', ['hello world']), 'Hello world');
      expect(q('lower', ['Hello WORLD']), 'hello world');
      expect(q('upper', ['Hello WORLD']), 'HELLO WORLD');
      expect(q('reverse', ['Hello World']), 'dlroW olleH');
      const family = '👨‍👩‍👧‍👦';
      expect(q('reverse', [family]),
          String.fromCharCodes(family.runes.toList().reversed));
    });
    test('unicode encode/decode', () {
      expect(q('unicodeencode', ['ABC', 1]), '66');
      expect(q('unicodedecode', [44032]), '가');
      expect(q('u', ['ac00']), '가');
    });
  });
}
