import 'dart:convert';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import '../models/character/character.dart';
import '../models/character/persona.dart';
import '../models/character/start_scenario.dart';
import '../models/character/lorebook_folder.dart';

class CharacterCardParser {
  /// PNG 파일에서 Character Card V2/V3 메타데이터를 추출합니다
  static Map<String, dynamic>? extractMetadataFromPng(Uint8List pngBytes) {
    try {
      final image = img.decodeImage(pngBytes);
      if (image == null) return null;

      // PNG tEXt 청크에서 'chara' 키를 찾습니다
      String? base64Data;

      // image 패키지는 텍스트 청크를 직접 제공하지 않으므로
      // PNG 파일 구조를 직접 파싱해야 합니다
      base64Data = _extractTextChunk(pngBytes, 'chara');

      if (base64Data == null) return null;

      // Base64 디코딩
      final decodedBytes = base64.decode(base64Data);
      final jsonString = utf8.decode(decodedBytes);

      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// PNG 바이트에서 특정 tEXt 청크를 추출합니다
  static String? _extractTextChunk(Uint8List bytes, String keyword) {
    try {
      int offset = 8; // PNG 시그니처 건너뛰기

      while (offset < bytes.length) {
        // 청크 길이 읽기 (4 바이트)
        if (offset + 4 > bytes.length) break;
        final length = (bytes[offset] << 24) |
            (bytes[offset + 1] << 16) |
            (bytes[offset + 2] << 8) |
            bytes[offset + 3];
        offset += 4;

        // 청크 타입 읽기 (4 바이트)
        if (offset + 4 > bytes.length) break;
        final type = String.fromCharCodes(bytes.sublist(offset, offset + 4));
        offset += 4;

        // 청크 데이터 읽기
        if (offset + length > bytes.length) break;
        final data = bytes.sublist(offset, offset + length);
        offset += length;

        // CRC 건너뛰기 (4 바이트)
        offset += 4;

        // tEXt 청크인지 확인
        if (type == 'tEXt') {
          // Null 종료자를 찾아 키워드 추출
          int nullIndex = data.indexOf(0);
          if (nullIndex != -1) {
            final chunkKeyword = String.fromCharCodes(data.sublist(0, nullIndex));
            if (chunkKeyword == keyword) {
              // 키워드 다음의 텍스트 반환
              return String.fromCharCodes(data.sublist(nullIndex + 1));
            }
          }
        }

        // IEND 청크에 도달하면 중단
        if (type == 'IEND') break;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Character Card V2/V3 JSON을 Character 객체로 변환합니다
  static Character parseCharacterCard(Map<String, dynamic> cardData) {
    final spec = cardData['spec'] as String?;

    if (spec == 'chara_card_v2' || spec == 'chara_card_v3') {
      final data = cardData['data'] as Map<String, dynamic>;

      List<String> tags = [];
      if (data['tags'] != null) {
        tags = (data['tags'] as List).map((e) => e.toString()).toList();
      }

      return Character(
        name: data['name'] as String? ?? 'Unknown',
        creatorNotes: data['creator_notes'] as String?,
        tags: tags,
        description: data['description'] as String?,
        isDraft: false,
      );
    }

    // 알 수 없는 형식
    throw FormatException('Unsupported character card format: $spec');
  }

  /// Character Card V2/V3에서 personas를 추출합니다
  /// Flan에서는 personality를 지원하지 않으므로 빈 배열 반환
  static List<Persona> parsePersonas(
      Map<String, dynamic> cardData, int characterId) {
    return [];
  }

  /// Character Card V2/V3에서 start scenarios를 추출합니다
  /// Flan에서는 scenario를 지원하지 않으므로 first_mes만 사용
  static List<StartScenario> parseStartScenarios(
      Map<String, dynamic> cardData, int characterId) {
    try {
      final data = cardData['data'] as Map<String, dynamic>;
      final firstMessage = data['first_mes'] as String?;

      if (firstMessage != null && firstMessage.isNotEmpty) {
        return [
          StartScenario(
            characterId: characterId,
            name: '기본 시나리오',
            order: 0,
            startSetting: null,
            startMessage: firstMessage,
          ),
        ];
      }
    } catch (e) {
      // 에러 무시
    }

    return [];
  }

  /// Character Card V2/V3에서 lorebooks를 추출합니다
  static List<Lorebook> parseLorebooks(
      Map<String, dynamic> cardData, int characterId) {
    try {
      final data = cardData['data'] as Map<String, dynamic>;
      final characterBook = data['character_book'] as Map<String, dynamic>?;

      if (characterBook != null) {
        final entries = characterBook['entries'] as List?;
        if (entries != null) {
          return entries.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value as Map<String, dynamic>;

            return Lorebook(
              characterId: characterId,
              name: item['name'] as String? ?? 'Lorebook ${idx + 1}',
              order: idx,
              content: item['content'] as String?,
              activationKeys: (item['keys'] as List?)
                  ?.map((k) => k.toString())
                  .toList() ?? [],
              activationCondition: (item['enabled'] as bool? ?? false)
                  ? LorebookActivationCondition.keyBased
                  : LorebookActivationCondition.disabled,
              deploymentOrder: item['insertion_order'] as int? ?? 0,
            );
          }).toList();
        }
      }
    } catch (e) {
      // 에러 무시
    }

    return [];
  }

  /// Character를 Character Card V2 형식으로 변환합니다
  static Map<String, dynamic> toCharacterCardV2({
    required Character character,
    List<Persona>? personas,
    List<StartScenario>? startScenarios,
    List<Lorebook>? lorebooks,
  }) {
    final scenario = startScenarios?.isNotEmpty == true ? startScenarios!.first : null;

    return {
      'spec': 'chara_card_v2',
      'spec_version': '2.0',
      'data': {
        'name': character.name,
        'description': character.description ?? '',
        'personality': '',
        'scenario': '',
        'first_mes': scenario?.startMessage ?? '',
        'mes_example': '',
        'creator_notes': character.creatorNotes ?? '',
        'system_prompt': '',
        'post_history_instructions': '',
        'alternate_greetings': [],
        'character_book': lorebooks != null && lorebooks.isNotEmpty
            ? {
                'entries': lorebooks.map((l) => {
                  'keys': l.activationKeys,
                  'content': l.content ?? '',
                  'extensions': {},
                  'enabled': l.activationCondition != LorebookActivationCondition.disabled,
                  'insertion_order': l.deploymentOrder,
                  'name': l.name,
                }).toList(),
              }
            : null,
        'tags': character.tags,
        'creator': '',
        'character_version': '',
        'extensions': {},
      },
    };
  }

  /// PNG 이미지에 Character Card 메타데이터를 임베드합니다
  static Uint8List? embedMetadataInPng(
      Uint8List pngBytes, Map<String, dynamic> metadata) {
    try {
      // JSON을 base64로 인코딩
      final jsonString = json.encode(metadata);
      final utf8Bytes = utf8.encode(jsonString);
      final base64Data = base64.encode(utf8Bytes);

      // tEXt 청크 생성
      final textChunk = _createTextChunk('chara', base64Data);

      // IEND 청크 앞에 tEXt 청크를 삽입
      return _insertChunkBeforeIEND(pngBytes, textChunk);
    } catch (e) {
      return null;
    }
  }

  /// tEXt 청크를 생성합니다
  static Uint8List _createTextChunk(String keyword, String text) {
    final keywordBytes = utf8.encode(keyword);
    final textBytes = utf8.encode(text);

    // 길이 = 키워드 + null 종료자 + 텍스트
    final length = keywordBytes.length + 1 + textBytes.length;

    final chunk = BytesBuilder();

    // 길이 (4 바이트, big-endian)
    chunk.add([
      (length >> 24) & 0xFF,
      (length >> 16) & 0xFF,
      (length >> 8) & 0xFF,
      length & 0xFF,
    ]);

    // 타입 (4 바이트)
    chunk.add(utf8.encode('tEXt'));

    // 데이터 (키워드 + null + 텍스트)
    chunk.add(keywordBytes);
    chunk.addByte(0); // null 종료자
    chunk.add(textBytes);

    // CRC 계산 (타입 + 데이터)
    final crcData = BytesBuilder();
    crcData.add(utf8.encode('tEXt'));
    crcData.add(keywordBytes);
    crcData.addByte(0);
    crcData.add(textBytes);
    final crc = _calculateCrc32(crcData.toBytes());

    // CRC (4 바이트, big-endian)
    chunk.add([
      (crc >> 24) & 0xFF,
      (crc >> 16) & 0xFF,
      (crc >> 8) & 0xFF,
      crc & 0xFF,
    ]);

    return chunk.toBytes();
  }

  /// IEND 청크 앞에 새 청크를 삽입합니다
  static Uint8List _insertChunkBeforeIEND(Uint8List pngBytes, Uint8List newChunk) {
    // IEND 청크 찾기
    int iendOffset = -1;
    int offset = 8; // PNG 시그니처 건너뛰기

    while (offset < pngBytes.length) {
      if (offset + 4 > pngBytes.length) break;
      final length = (pngBytes[offset] << 24) |
          (pngBytes[offset + 1] << 16) |
          (pngBytes[offset + 2] << 8) |
          pngBytes[offset + 3];

      if (offset + 8 + length > pngBytes.length) break;
      final type = String.fromCharCodes(pngBytes.sublist(offset + 4, offset + 8));

      if (type == 'IEND') {
        iendOffset = offset;
        break;
      }

      offset += 12 + length; // 길이(4) + 타입(4) + 데이터(length) + CRC(4)
    }

    if (iendOffset == -1) return pngBytes;

    // IEND 앞에 새 청크 삽입
    final result = BytesBuilder();
    result.add(pngBytes.sublist(0, iendOffset));
    result.add(newChunk);
    result.add(pngBytes.sublist(iendOffset));

    return result.toBytes();
  }

  /// CRC32 체크섬을 계산합니다
  static int _calculateCrc32(Uint8List data) {
    const crcTable = <int>[
      0x00000000, 0x77073096, 0xEE0E612C, 0x990951BA, 0x076DC419, 0x706AF48F, 0xE963A535, 0x9E6495A3,
      0x0EDB8832, 0x79DCB8A4, 0xE0D5E91E, 0x97D2D988, 0x09B64C2B, 0x7EB17CBD, 0xE7B82D07, 0x90BF1D91,
      0x1DB71064, 0x6AB020F2, 0xF3B97148, 0x84BE41DE, 0x1ADAD47D, 0x6DDDE4EB, 0xF4D4B551, 0x83D385C7,
      0x136C9856, 0x646BA8C0, 0xFD62F97A, 0x8A65C9EC, 0x14015C4F, 0x63066CD9, 0xFA0F3D63, 0x8D080DF5,
      0x3B6E20C8, 0x4C69105E, 0xD56041E4, 0xA2677172, 0x3C03E4D1, 0x4B04D447, 0xD20D85FD, 0xA50AB56B,
      0x35B5A8FA, 0x42B2986C, 0xDBBBC9D6, 0xACBCF940, 0x32D86CE3, 0x45DF5C75, 0xDCD60DCF, 0xABD13D59,
      0x26D930AC, 0x51DE003A, 0xC8D75180, 0xBFD06116, 0x21B4F4B5, 0x56B3C423, 0xCFBA9599, 0xB8BDA50F,
      0x2802B89E, 0x5F058808, 0xC60CD9B2, 0xB10BE924, 0x2F6F7C87, 0x58684C11, 0xC1611DAB, 0xB6662D3D,
      0x76DC4190, 0x01DB7106, 0x98D220BC, 0xEFD5102A, 0x71B18589, 0x06B6B51F, 0x9FBFE4A5, 0xE8B8D433,
      0x7807C9A2, 0x0F00F934, 0x9609A88E, 0xE10E9818, 0x7F6A0DBB, 0x086D3D2D, 0x91646C97, 0xE6635C01,
      0x6B6B51F4, 0x1C6C6162, 0x856530D8, 0xF262004E, 0x6C0695ED, 0x1B01A57B, 0x8208F4C1, 0xF50FC457,
      0x65B0D9C6, 0x12B7E950, 0x8BBEB8EA, 0xFCB9887C, 0x62DD1DDF, 0x15DA2D49, 0x8CD37CF3, 0xFBD44C65,
      0x4DB26158, 0x3AB551CE, 0xA3BC0074, 0xD4BB30E2, 0x4ADFA541, 0x3DD895D7, 0xA4D1C46D, 0xD3D6F4FB,
      0x4369E96A, 0x346ED9FC, 0xAD678846, 0xDA60B8D0, 0x44042D73, 0x33031DE5, 0xAA0A4C5F, 0xDD0D7CC9,
      0x5005713C, 0x270241AA, 0xBE0B1010, 0xC90C2086, 0x5768B525, 0x206F85B3, 0xB966D409, 0xCE61E49F,
      0x5EDEF90E, 0x29D9C998, 0xB0D09822, 0xC7D7A8B4, 0x59B33D17, 0x2EB40D81, 0xB7BD5C3B, 0xC0BA6CAD,
      0xEDB88320, 0x9ABFB3B6, 0x03B6E20C, 0x74B1D29A, 0xEAD54739, 0x9DD277AF, 0x04DB2615, 0x73DC1683,
      0xE3630B12, 0x94643B84, 0x0D6D6A3E, 0x7A6A5AA8, 0xE40ECF0B, 0x9309FF9D, 0x0A00AE27, 0x7D079EB1,
      0xF00F9344, 0x8708A3D2, 0x1E01F268, 0x6906C2FE, 0xF762575D, 0x806567CB, 0x196C3671, 0x6E6B06E7,
      0xFED41B76, 0x89D32BE0, 0x10DA7A5A, 0x67DD4ACC, 0xF9B9DF6F, 0x8EBEEFF9, 0x17B7BE43, 0x60B08ED5,
      0xD6D6A3E8, 0xA1D1937E, 0x38D8C2C4, 0x4FDFF252, 0xD1BB67F1, 0xA6BC5767, 0x3FB506DD, 0x48B2364B,
      0xD80D2BDA, 0xAF0A1B4C, 0x36034AF6, 0x41047A60, 0xDF60EFC3, 0xA867DF55, 0x316E8EEF, 0x4669BE79,
      0xCB61B38C, 0xBC66831A, 0x256FD2A0, 0x5268E236, 0xCC0C7795, 0xBB0B4703, 0x220216B9, 0x5505262F,
      0xC5BA3BBE, 0xB2BD0B28, 0x2BB45A92, 0x5CB36A04, 0xC2D7FFA7, 0xB5D0CF31, 0x2CD99E8B, 0x5BDEAE1D,
      0x9B64C2B0, 0xEC63F226, 0x756AA39C, 0x026D930A, 0x9C0906A9, 0xEB0E363F, 0x72076785, 0x05005713,
      0x95BF4A82, 0xE2B87A14, 0x7BB12BAE, 0x0CB61B38, 0x92D28E9B, 0xE5D5BE0D, 0x7CDCEFB7, 0x0BDBDF21,
      0x86D3D2D4, 0xF1D4E242, 0x68DDB3F8, 0x1FDA836E, 0x81BE16CD, 0xF6B9265B, 0x6FB077E1, 0x18B74777,
      0x88085AE6, 0xFF0F6A70, 0x66063BCA, 0x11010B5C, 0x8F659EFF, 0xF862AE69, 0x616BFFD3, 0x166CCF45,
      0xA00AE278, 0xD70DD2EE, 0x4E048354, 0x3903B3C2, 0xA7672661, 0xD06016F7, 0x4969474D, 0x3E6E77DB,
      0xAED16A4A, 0xD9D65ADC, 0x40DF0B66, 0x37D83BF0, 0xA9BCAE53, 0xDEBB9EC5, 0x47B2CF7F, 0x30B5FFE9,
      0xBDBDF21C, 0xCABAC28A, 0x53B39330, 0x24B4A3A6, 0xBAD03605, 0xCDD70693, 0x54DE5729, 0x23D967BF,
      0xB3667A2E, 0xC4614AB8, 0x5D681B02, 0x2A6F2B94, 0xB40BBE37, 0xC30C8EA1, 0x5A05DF1B, 0x2D02EF8D,
    ];

    int crc = 0xFFFFFFFF;
    for (final byte in data) {
      crc = crcTable[(crc ^ byte) & 0xFF] ^ (crc >> 8);
    }
    return crc ^ 0xFFFFFFFF;
  }
}
