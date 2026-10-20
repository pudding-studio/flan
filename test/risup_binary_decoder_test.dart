// Builds `.risup` files the way RisuAI's exportPreset does and decodes them.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flan/utils/risup_binary_decoder.dart';
import 'package:flutter_test/flutter_test.dart';

/// Values msgpackr writes as extensions rather than plain MessagePack.
class _Ext {
  final List<int> bytes;
  const _Ext(this.bytes);
}

/// msgpackr's encoding of JavaScript `undefined`.
const _undefined = _Ext([0xd4, 0x00, 0x00]);

/// A 32-bit MessagePack timestamp for 2024-01-01T00:00:00Z.
const _timestamp = _Ext([0xd6, 0xff, 0x65, 0x92, 0x00, 0x80]);

void _pack(BytesBuilder out, Object? value) {
  if (value == null) {
    out.addByte(0xc0);
  } else if (value is _Ext) {
    out.add(value.bytes);
  } else if (value is bool) {
    out.addByte(value ? 0xc3 : 0xc2);
  } else if (value is int) {
    out
      ..addByte(0xd2)
      ..add((ByteData(4)..setInt32(0, value)).buffer.asUint8List());
  } else if (value is String) {
    final bytes = utf8.encode(value);
    out
      ..addByte(0xdb)
      ..add((ByteData(4)..setUint32(0, bytes.length)).buffer.asUint8List())
      ..add(bytes);
  } else if (value is Uint8List) {
    out
      ..addByte(0xc6)
      ..add((ByteData(4)..setUint32(0, value.length)).buffer.asUint8List())
      ..add(value);
  } else if (value is List) {
    out
      ..addByte(0xdd)
      ..add((ByteData(4)..setUint32(0, value.length)).buffer.asUint8List());
    for (final item in value) {
      _pack(out, item);
    }
  } else if (value is Map) {
    out
      ..addByte(0xdf)
      ..add((ByteData(4)..setUint32(0, value.length)).buffer.asUint8List());
    value.forEach((k, v) {
      _pack(out, k);
      _pack(out, v);
    });
  } else {
    throw ArgumentError(value);
  }
}

Uint8List _msgpack(Object? value) {
  final out = BytesBuilder();
  _pack(out, value);
  return out.toBytes();
}

Future<Uint8List> _risup(Map<String, Object?> preset) async {
  final key = await Sha256().hash(utf8.encode('risupreset'));
  final box = await AesGcm.with256bits().encrypt(
    _msgpack(preset),
    secretKey: SecretKey(key.bytes),
    nonce: List.filled(12, 0),
  );
  final encrypted = Uint8List.fromList([...box.cipherText, ...box.mac.bytes]);
  final compressed = const ZLibEncoder().encode(_msgpack({
    'presetVersion': 2,
    'type': 'preset',
    'preset': encrypted,
  }));
  final encodeMap =
      File('assets/risu/rpack_map.bin').readAsBytesSync().sublist(0, 256);
  return Uint8List.fromList([for (final b in compressed) encodeMap[b]]);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('decodes presets carrying msgpackr extension values', () async {
    final decoded = await RisupBinaryDecoder.decode(await _risup({
      'name': 'New preset',
      'mainPrompt': 'main',
      'globalNote': '',
      'promptTemplate': [
        {'type': 'plain', 'role': 'system', 'text': 'hi', 'name': _undefined},
      ],
      'subModel': _undefined,
      'savedAt': _timestamp,
    }));

    expect(decoded['name'], 'New preset');
    expect(decoded['subModel'], isNull);
    expect(decoded['savedAt'], '2024-01-01T00:00:00.000Z');
    expect((decoded['promptTemplate'] as List).single, {
      'type': 'plain',
      'role': 'system',
      'text': 'hi',
      'name': null,
    });
  });
}
