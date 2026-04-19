import 'dart:convert';
import 'dart:typed_data';
import 'package:universal_io/io.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import '../l10n/app_localizations.dart';
import '../database/database_helper.dart';
import '../models/character/character.dart';
import '../models/character/persona.dart';
import '../models/character/start_scenario.dart';
import '../models/character/character_book_folder.dart';
import '../models/character/cover_image.dart';
import '../utils/common_dialog.dart';
import '../utils/character_card_parser.dart';
import '../utils/character_image_storage.dart';

class CharacterImporter {
  static Future<bool> import(BuildContext context, DatabaseHelper db) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );

      if (result == null || result.files.isEmpty) return false;

      if (!context.mounted) return false;
      final l10n = AppLocalizations.of(context);
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const PopScope(
          canPop: false,
          child: Center(child: CircularProgressIndicator()),
        ),
      );

      final file = File(result.files.single.path!);
      var extension = result.files.single.extension?.toLowerCase();
      if (extension == null || extension.isEmpty) {
        final filePath = result.files.single.path ?? '';
        final dotIndex = filePath.lastIndexOf('.');
        if (dotIndex != -1 && dotIndex < filePath.length - 1) {
          extension = filePath.substring(dotIndex + 1).toLowerCase();
        }
      }

      Character? character;
      List<Persona>? personas;
      List<StartScenario>? startScenarios;
      List<CharacterBookFolder>? characterBookFolders;
      List<CharacterBook>? standaloneCharacterBooks;
      List<CoverImage>? coverImages;
      List<CoverImage>? additionalImages;

      if (extension == 'json') {
        // JSON 파일 처리
        final jsonString = await file.readAsString();
        final jsonData = json.decode(jsonString) as Map<String, dynamic>;

        final format = jsonData['format'] as String?;
        final spec = jsonData['spec'] as String?;

        if (format == 'flan_v1') {
          // 자체 형식
          character = Character.fromJson(jsonData);
          // 관련 데이터 파싱 (임시 characterId 0 사용)
          personas = (jsonData['personas'] as List?)
              ?.map((p) => Persona.fromJson(p as Map<String, dynamic>))
              .toList();
          startScenarios = (jsonData['startScenarios'] as List?)
              ?.map((s) => StartScenario.fromJson(s as Map<String, dynamic>))
              .toList();
          // 하위 호환성: 이전 키명도 지원
          characterBookFolders = (jsonData['characterBookFolders'] as List?)
              ?.map((f) => CharacterBookFolder.fromJson(f as Map<String, dynamic>))
              .toList() ?? (jsonData['lorebookFolders'] as List?)
              ?.map((f) => CharacterBookFolder.fromJson(f as Map<String, dynamic>))
              .toList();
          standaloneCharacterBooks = (jsonData['standaloneCharacterBooks'] as List?)
              ?.map((l) => CharacterBook.fromJson(l as Map<String, dynamic>))
              .toList() ?? (jsonData['standaloneLorebooks'] as List?)
              ?.map((l) => CharacterBook.fromJson(l as Map<String, dynamic>))
              .toList();
          coverImages = (jsonData['coverImages'] as List?)
              ?.map((c) => CoverImage.fromJson(c as Map<String, dynamic>))
              .toList();
        } else if (spec == 'chara_card_v2' || spec == 'chara_card_v3') {
          // Character Card V2/V3 JSON 형식
          character = CharacterCardParser.parseCharacterCard(jsonData);
          startScenarios = CharacterCardParser.parseStartScenarios(jsonData, 0);
          standaloneCharacterBooks = CharacterCardParser.parseCharacterBooks(jsonData, 0);
        } else {
          throw FormatException('Unsupported format: ${format ?? spec}');
        }
      } else if (extension == 'png') {
        // PNG 파일에서 메타데이터 추출
        final pngBytes = await file.readAsBytes();
        final metadata = CharacterCardParser.extractMetadataFromPng(pngBytes);

        if (metadata == null) {
          throw FormatException('PNG 파일에서 캐릭터 데이터를 찾을 수 없습니다');
        }

        character = CharacterCardParser.parseCharacterCard(metadata);
        startScenarios = CharacterCardParser.parseStartScenarios(metadata, 0);
        standaloneCharacterBooks = CharacterCardParser.parseCharacterBooks(metadata, 0);

        // V3 assets에서 이미지 추출 시도
        final allAssets = await CharacterCardParser.parseAssets(
          metadata,
          0,
          character.name,
        );
        if (allAssets.isNotEmpty) {
          coverImages = allAssets.where((i) => i.imageType == 'cover').toList();
          additionalImages = allAssets.where((i) => i.imageType == 'additional').toList();
        } else {
          // PNG 이미지 자체를 표지 이미지로 저장
          try {
            final fileName = p.basename(file.path);
            final dotIndex = fileName.lastIndexOf('.');
            final baseName = dotIndex > 0 ? fileName.substring(0, dotIndex) : fileName;
            final stored = await CharacterImageStorage.saveImageBytes(
              character.name,
              baseName,
              'png',
              pngBytes,
            );
            coverImages = [
              CoverImage(
                characterId: 0,
                name: l10n.characterCoverDefault,
                order: 0,
                path: stored.path,
                imageData: stored.bytes,
              ),
            ];
          } catch (_) {
            // Image save failure is non-critical
          }
        }
      } else if (extension == 'charx') {
        // CHARX (ZIP archive) 파일 처리
        // CHARX는 이미지+ZIP 폴리글롯 형태일 수 있으므로 PK 시그니처 탐색
        final rawBytes = await file.readAsBytes();
        Uint8List archiveBytes = rawBytes;
        if (rawBytes.length >= 4 &&
            !(rawBytes[0] == 0x50 && rawBytes[1] == 0x4B)) {
          int zipStart = -1;
          for (int i = 0; i < rawBytes.length - 4; i++) {
            if (rawBytes[i] == 0x50 &&
                rawBytes[i + 1] == 0x4B &&
                rawBytes[i + 2] == 0x03 &&
                rawBytes[i + 3] == 0x04) {
              zipStart = i;
              break;
            }
          }
          if (zipStart > 0) {
            archiveBytes = Uint8List.sublistView(rawBytes, zipStart);
          }
        }
        final archive = ZipDecoder().decodeBytes(archiveBytes, verify: false);

        // card.json 찾기
        final cardJsonFile = archive.findFile('card.json');
        if (cardJsonFile == null) {
          throw FormatException('CHARX 파일에서 card.json을 찾을 수 없습니다');
        }

        final jsonString = utf8.decode(cardJsonFile.content as List<int>);
        final jsonData = json.decode(jsonString) as Map<String, dynamic>;

        character = CharacterCardParser.parseCharacterCard(jsonData);
        startScenarios = CharacterCardParser.parseStartScenarios(jsonData, 0);
        standaloneCharacterBooks = CharacterCardParser.parseCharacterBooks(jsonData, 0);

        // 아카이브 파일 맵 구성 (embeded:// URI 해석용)
        final archiveFiles = <String, Uint8List>{};
        for (final file in archive) {
          if (!file.isFile) continue;
          archiveFiles[file.name] = Uint8List.fromList(file.content as List<int>);
        }

        // V3 assets에서 이미지 추출
        final allAssets = await CharacterCardParser.parseAssets(
          jsonData,
          0,
          character.name,
          archiveFiles: archiveFiles,
        );
        coverImages = allAssets.where((i) => i.imageType == 'cover').toList();
        additionalImages = allAssets.where((i) => i.imageType == 'additional').toList();
      } else if (extension == 'flan') {
        // Flan 형식: 이미지+ZIP 폴리글롯(신규) 또는 순수 ZIP(레거시).
        // 파일이 PK 시그니처로 시작하지 않으면 앞쪽 이미지 바이트를 건너뛰기 위해
        // PK\x03\x04 시그니처를 스캔한다 (charx 처리와 동일 전략).
        final rawBytes = await file.readAsBytes();
        Uint8List archiveBytes = rawBytes;
        if (rawBytes.length >= 4 &&
            !(rawBytes[0] == 0x50 && rawBytes[1] == 0x4B)) {
          int zipStart = -1;
          for (int i = 0; i < rawBytes.length - 4; i++) {
            if (rawBytes[i] == 0x50 &&
                rawBytes[i + 1] == 0x4B &&
                rawBytes[i + 2] == 0x03 &&
                rawBytes[i + 3] == 0x04) {
              zipStart = i;
              break;
            }
          }
          if (zipStart > 0) {
            archiveBytes = Uint8List.sublistView(rawBytes, zipStart);
          }
        }
        final archive = ZipDecoder().decodeBytes(archiveBytes, verify: false);

        final charJsonFile = archive.findFile('character.json');
        if (charJsonFile == null) {
          throw FormatException('.flan 파일에서 character.json을 찾을 수 없습니다');
        }

        final jsonString = utf8.decode(charJsonFile.content as List<int>);
        final jsonData = json.decode(jsonString) as Map<String, dynamic>;

        character = Character.fromJson(jsonData);
        personas = (jsonData['personas'] as List?)
            ?.map((item) => Persona.fromJson(item as Map<String, dynamic>))
            .toList();
        startScenarios = (jsonData['startScenarios'] as List?)
            ?.map((item) => StartScenario.fromJson(item as Map<String, dynamic>))
            .toList();
        characterBookFolders = (jsonData['characterBookFolders'] as List?)
            ?.map((item) => CharacterBookFolder.fromJson(item as Map<String, dynamic>))
            .toList() ?? (jsonData['lorebookFolders'] as List?)
            ?.map((item) => CharacterBookFolder.fromJson(item as Map<String, dynamic>))
            .toList();
        standaloneCharacterBooks = (jsonData['standaloneCharacterBooks'] as List?)
            ?.map((item) => CharacterBook.fromJson(item as Map<String, dynamic>))
            .toList() ?? (jsonData['standaloneLorebooks'] as List?)
            ?.map((item) => CharacterBook.fromJson(item as Map<String, dynamic>))
            .toList();

        // Restore images from ZIP entries
        final jsonCoverImages = (jsonData['coverImages'] as List?) ?? [];
        coverImages = [];
        for (final imgJson in jsonCoverImages) {
          final imgData = imgJson as Map<String, dynamic>;
          final name = imgData['name'] as String? ?? 'image';
          final imageType = (imgData['imageType'] as String?) ?? 'cover';
          final order = imgData['order'] as int? ?? 0;

          // Find matching image file in ZIP (images/{name}.*)
          ArchiveFile? found;
          for (final entry in archive) {
            if (!entry.isFile) continue;
            if (entry.name.startsWith('images/') &&
                p.basenameWithoutExtension(entry.name) == name) {
              found = entry;
              break;
            }
          }

          if (found != null) {
            final imgBytes = Uint8List.fromList(found.content as List<int>);
            final ext = p.extension(found.name).replaceFirst('.', '');
            try {
              final stored = await CharacterImageStorage.saveImageBytes(
                character.name, name, ext, imgBytes,
              );
              coverImages.add(CoverImage(
                characterId: 0,
                name: name,
                order: order,
                path: stored.path,
                imageData: stored.bytes,
                imageType: imageType,
              ));
            } catch (_) {
              // Skip unreadable images
            }
          }
        }
      } else {
        throw const FormatException('Unsupported file format');
      }

      // DB에 저장
      final characterId = await db.createCharacter(character);

      // 관련 데이터 저장
      if (personas != null) {
        for (final persona in personas) {
          await db.createPersona(persona.copyWith(characterId: characterId));
        }
      }

      if (startScenarios != null) {
        for (final scenario in startScenarios) {
          await db.createStartScenario(
              scenario.copyWith(characterId: characterId));
        }
      }

      if (characterBookFolders != null) {
        for (final folder in characterBookFolders) {
          final folderId = await db.createCharacterBookFolder(
              folder.copyWith(characterId: characterId));

          // 폴더 내 캐릭터북 저장
          for (final characterBook in folder.characterBooks) {
            await db.createCharacterBook(
                characterBook.copyWith(characterId: characterId, folderId: folderId));
          }
        }
      }

      if (standaloneCharacterBooks != null) {
        for (final characterBook in standaloneCharacterBooks) {
          await db.createCharacterBook(
              characterBook.copyWith(characterId: characterId));
        }
      }

      int? firstCoverImageId;
      if (coverImages != null) {
        for (final image in coverImages) {
          final imageId = await db.createCoverImage(image.copyWith(characterId: characterId));
          firstCoverImageId ??= imageId;
        }
      }

      if (additionalImages != null) {
        for (final image in additionalImages) {
          await db.createCoverImage(image.copyWith(characterId: characterId));
        }
      }

      // 표지 이미지가 있으면 첫번째를 선택 상태로 설정
      if (firstCoverImageId != null) {
        await db.updateCharacter(character.copyWith(
          id: characterId,
          selectedCoverImageId: firstCoverImageId,
        ));
      }

      if (context.mounted) {
        Navigator.pop(context); // dismiss loading
        CommonDialog.showSnackBar(
          context: context,
          message: l10n.characterImportSuccess,
        );
      }

      return true;
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // dismiss loading
        CommonDialog.showSnackBar(
          context: context,
          message:
              AppLocalizations.of(context).characterImportFailed(e.toString()),
        );
      }
      return false;
    }
  }
}
