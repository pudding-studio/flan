import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Decodes RisuAI `.risup` binary presets to the raw `botPreset` JSON map
/// that [RisuPresetConverter] already understands.
///
/// The `.risup` container mirrors RisuAI's own `importPreset` pipeline
/// (see `src/ts/storage/database.svelte.ts` on kwaroran/RisuAI):
///
///   raw bytes
///     → RPack byte-substitution (rpack_map.bin decode table)
///     → zlib/fflate decompress
///     → MessagePack decode → { preset | pres: <encrypted bytes> }
///     → AES-GCM decrypt (key = SHA-256("risupreset"), IV = 12 zero bytes)
///     → MessagePack decode → botPreset object
class RisupBinaryDecoder {
  static const String _rpackAssetPath = 'assets/risu/rpack_map.bin';
  static const String _presetKey = 'risupreset';

  static Uint8List? _decodeMapCache;

  /// Decode a `.risup` file's raw bytes into the botPreset map.
  static Future<Map<String, dynamic>> decode(Uint8List risupBytes) async {
    final unpacked = await _decodeRPack(risupBytes);
    final decompressed = _zlibDecompress(unpacked);

    final outer = _MsgpackReader(decompressed).read();
    if (outer is! Map) {
      throw const FormatException(
        'risup: outer MessagePack payload is not a map',
      );
    }

    final encryptedPreset = outer['preset'] ?? outer['pres'];
    if (encryptedPreset is! Uint8List && encryptedPreset is! List<int>) {
      throw const FormatException(
        'risup: missing or invalid encrypted preset field',
      );
    }
    final cipherBytes = encryptedPreset is Uint8List
        ? encryptedPreset
        : Uint8List.fromList(encryptedPreset as List<int>);

    final plaintext = await _aesGcmDecrypt(cipherBytes, _presetKey);
    final inner = _MsgpackReader(plaintext).read();
    if (inner is! Map) {
      throw const FormatException(
        'risup: inner MessagePack payload is not a map',
      );
    }

    return _stringKeyed(inner) as Map<String, dynamic>;
  }

  /// Apply Risu's RPack byte-substitution using the shipped 512-byte lookup
  /// table (encodeMap = bytes 0..255, decodeMap = bytes 256..511).
  static Future<Uint8List> _decodeRPack(Uint8List data) async {
    final map = await _loadDecodeMap();
    final out = Uint8List(data.length);
    for (int i = 0; i < data.length; i++) {
      out[i] = map[data[i]];
    }
    return out;
  }

  static Future<Uint8List> _loadDecodeMap() async {
    final cached = _decodeMapCache;
    if (cached != null) return cached;

    final byteData = await rootBundle.load(_rpackAssetPath);
    if (byteData.lengthInBytes < 512) {
      throw StateError(
        'rpack_map.bin must be 512 bytes, got ${byteData.lengthInBytes}',
      );
    }
    final decode = Uint8List.view(byteData.buffer, 256, 256);
    _decodeMapCache = decode;
    return decode;
  }

  /// fflate.decompressSync accepts zlib / gzip / raw-deflate. Risu's presets
  /// use the zlib format in practice; fall back to raw deflate for safety.
  static Uint8List _zlibDecompress(Uint8List data) {
    try {
      return Uint8List.fromList(ZLibDecoder().decodeBytes(data));
    } catch (_) {
      return Uint8List.fromList(Inflate(data).getBytes());
    }
  }

  static Future<Uint8List> _aesGcmDecrypt(
    Uint8List ciphertext,
    String keyString,
  ) async {
    if (ciphertext.length < 16) {
      throw const FormatException(
        'risup: ciphertext shorter than GCM tag length',
      );
    }
    // SubtleCrypto's AES-GCM output layout: [ciphertext][16-byte auth tag].
    final macBytes = ciphertext.sublist(ciphertext.length - 16);
    final cipherOnly = ciphertext.sublist(0, ciphertext.length - 16);

    final keyDigest = await Sha256().hash(utf8.encode(keyString));
    final secretKey = SecretKey(keyDigest.bytes);

    final secretBox = SecretBox(
      cipherOnly,
      nonce: List<int>.filled(12, 0),
      mac: Mac(macBytes),
    );

    final decrypted = await AesGcm.with256bits().decrypt(
      secretBox,
      secretKey: secretKey,
    );
    return Uint8List.fromList(decrypted);
  }

  /// Recursively coerce Map<dynamic, dynamic>/List<dynamic> from MessagePack
  /// into a JSON-shaped tree with String keys — what the downstream converter
  /// expects. Non-map/list values pass through untouched.
  static dynamic _stringKeyed(dynamic value) {
    if (value is Map) {
      final out = <String, dynamic>{};
      value.forEach((k, v) {
        out[k.toString()] = _stringKeyed(v);
      });
      return out;
    }
    if (value is List) {
      return value.map(_stringKeyed).toList();
    }
    return value;
  }
}

/// Minimal recursive MessagePack decoder covering the value types Risu
/// presets use: nil, bool, int (all widths), float 32/64, str (all widths),
/// bin (all widths), array, map. Extension types are not needed and throw.
class _MsgpackReader {
  final ByteData _view;
  final Uint8List _bytes;
  int _pos = 0;

  _MsgpackReader(Uint8List bytes)
      : _bytes = bytes,
        _view = ByteData.view(bytes.buffer, bytes.offsetInBytes, bytes.length);

  dynamic read() {
    if (_pos >= _bytes.length) {
      throw const FormatException('msgpack: unexpected end of data');
    }
    final b = _bytes[_pos++];

    // Positive fixint (0x00–0x7f)
    if (b <= 0x7f) return b;
    // Negative fixint (0xe0–0xff)
    if (b >= 0xe0) return b - 0x100;
    // Fixstr (0xa0–0xbf)
    if (b >= 0xa0 && b <= 0xbf) return _readStr(b & 0x1f);
    // Fixarray (0x90–0x9f)
    if (b >= 0x90 && b <= 0x9f) return _readArray(b & 0x0f);
    // Fixmap (0x80–0x8f)
    if (b >= 0x80 && b <= 0x8f) return _readMap(b & 0x0f);

    switch (b) {
      case 0xc0:
        return null;
      case 0xc2:
        return false;
      case 0xc3:
        return true;
      case 0xc4:
        return _readBin(_readU8());
      case 0xc5:
        return _readBin(_readU16());
      case 0xc6:
        return _readBin(_readU32());
      case 0xca:
        return _readF32();
      case 0xcb:
        return _readF64();
      case 0xcc:
        return _readU8();
      case 0xcd:
        return _readU16();
      case 0xce:
        return _readU32();
      case 0xcf:
        return _readU64();
      case 0xd0:
        return _readI8();
      case 0xd1:
        return _readI16();
      case 0xd2:
        return _readI32();
      case 0xd3:
        return _readI64();
      case 0xd9:
        return _readStr(_readU8());
      case 0xda:
        return _readStr(_readU16());
      case 0xdb:
        return _readStr(_readU32());
      case 0xdc:
        return _readArray(_readU16());
      case 0xdd:
        return _readArray(_readU32());
      case 0xde:
        return _readMap(_readU16());
      case 0xdf:
        return _readMap(_readU32());
      default:
        throw FormatException(
          'msgpack: unsupported type byte 0x${b.toRadixString(16)}',
        );
    }
  }

  int _readU8() => _bytes[_pos++];

  int _readU16() {
    final v = _view.getUint16(_pos, Endian.big);
    _pos += 2;
    return v;
  }

  int _readU32() {
    final v = _view.getUint32(_pos, Endian.big);
    _pos += 4;
    return v;
  }

  int _readU64() {
    final v = _view.getUint64(_pos, Endian.big);
    _pos += 8;
    return v;
  }

  int _readI8() {
    final v = _view.getInt8(_pos);
    _pos += 1;
    return v;
  }

  int _readI16() {
    final v = _view.getInt16(_pos, Endian.big);
    _pos += 2;
    return v;
  }

  int _readI32() {
    final v = _view.getInt32(_pos, Endian.big);
    _pos += 4;
    return v;
  }

  int _readI64() {
    final v = _view.getInt64(_pos, Endian.big);
    _pos += 8;
    return v;
  }

  double _readF32() {
    final v = _view.getFloat32(_pos, Endian.big);
    _pos += 4;
    return v;
  }

  double _readF64() {
    final v = _view.getFloat64(_pos, Endian.big);
    _pos += 8;
    return v;
  }

  String _readStr(int length) {
    final slice = _bytes.sublist(_pos, _pos + length);
    _pos += length;
    return utf8.decode(slice, allowMalformed: true);
  }

  Uint8List _readBin(int length) {
    final slice = Uint8List.fromList(_bytes.sublist(_pos, _pos + length));
    _pos += length;
    return slice;
  }

  List<dynamic> _readArray(int length) {
    final out = List<dynamic>.filled(length, null, growable: false);
    for (int i = 0; i < length; i++) {
      out[i] = read();
    }
    return out;
  }

  Map<dynamic, dynamic> _readMap(int length) {
    final out = <dynamic, dynamic>{};
    for (int i = 0; i < length; i++) {
      final k = read();
      final v = read();
      out[k] = v;
    }
    return out;
  }
}
