import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive.dart';
import '../../widgets/common/common_fab.dart';
import '../../providers/theme_provider.dart';
import '../../database/database_helper.dart';
import '../../models/character/character.dart';
import '../../models/character/persona.dart';
import '../../models/character/start_scenario.dart';
import '../../models/character/character_book_folder.dart';
import '../../models/character/cover_image.dart';
import 'package:path/path.dart' as p;
import '../../utils/common_dialog.dart';
import '../../utils/character_card_parser.dart';
import '../../utils/character_image_storage.dart';
import '../../utils/streaming_zip_writer.dart';
import 'character_edit_screen.dart';
import 'character_view_screen.dart';
import '../../widgets/character/character_card.dart';
import '../../widgets/character/character_list_item.dart';
import '../../widgets/common/common_appbar.dart';
import '../agent/agent_chat_screen.dart';

class CharacterScreen extends StatefulWidget {
  const CharacterScreen({super.key});

  @override
  State<CharacterScreen> createState() => _CharacterScreenState();
}

enum SortMethod {
  nameAsc,
  nameDesc,
  updatedAtAsc,
  updatedAtDesc,
  createdAtAsc,
  createdAtDesc,
  custom,
}

class _CharacterScreenState extends State<CharacterScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  bool _isGridView = true;
  SortMethod _sortMethod = SortMethod.createdAtDesc;
  List<Character> _characters = [];
  bool _isLoading = true;
  Map<int, Uint8List?> _characterCoverImages = {};
  bool _isEditMode = false;
  final Set<int> _selectedCharacterIds = {};

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _loadCharacters();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _isGridView = prefs.getBool('character_is_grid_view') ?? true;
      final sortMethodString = prefs.getString('character_sort_method') ?? 'createdAtDesc';
      _sortMethod = SortMethod.values.firstWhere(
        (e) => e.name == sortMethodString,
        orElse: () => SortMethod.createdAtDesc,
      );
    });
  }

  Future<void> _saveViewPreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('character_is_grid_view', _isGridView);
  }

  Future<void> _saveSortPreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('character_sort_method', _sortMethod.name);
  }

  Future<void> _loadCharacters() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final characters = await _db.readAllCharacters();

      // 각 캐릭터의 표지 이미지 로드
      final coverImages = <int, Uint8List?>{};
      for (var character in characters) {
        final images = await _db.readCoverImages(character.id!);
        if (images.isNotEmpty) {
          CoverImage selectedImage;
          if (character.selectedCoverImageId != null) {
            selectedImage = images.firstWhere(
              (img) => img.id == character.selectedCoverImageId,
              orElse: () => images.first,
            );
          } else {
            selectedImage = images.first;
          }
          coverImages[character.id!] = await selectedImage.resolveImageData();
        }
      }

      if (!mounted) return;
      setState(() {
        _characters = characters;
        _characterCoverImages = coverImages;
        _sortCharacters();
      });
    } catch (e) {
      if (mounted) {
        CommonDialog.showSnackBar(
          context: context,
          message: '캐릭터 목록을 불러오는데 실패했습니다: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _sortCharacters() {
    switch (_sortMethod) {
      case SortMethod.nameAsc:
        _characters.sort((a, b) => a.name.compareTo(b.name));
        break;
      case SortMethod.nameDesc:
        _characters.sort((a, b) => b.name.compareTo(a.name));
        break;
      case SortMethod.updatedAtAsc:
        _characters.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
        break;
      case SortMethod.updatedAtDesc:
        _characters.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        break;
      case SortMethod.createdAtAsc:
        _characters.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case SortMethod.createdAtDesc:
        _characters.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case SortMethod.custom:
        _characters.sort((a, b) {
          if (a.sortOrder == null && b.sortOrder == null) return 0;
          if (a.sortOrder == null) return 1;
          if (b.sortOrder == null) return -1;
          return a.sortOrder!.compareTo(b.sortOrder!);
        });
        break;
    }
  }

  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
      if (!_isEditMode) {
        _selectedCharacterIds.clear();
      }
    });
  }

  void _toggleCharacterSelection(int id) {
    setState(() {
      if (_selectedCharacterIds.contains(id)) {
        _selectedCharacterIds.remove(id);
      } else {
        _selectedCharacterIds.add(id);
      }
    });
  }

  Future<void> _reorderCharacters(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    setState(() {
      final character = _characters.removeAt(oldIndex);
      _characters.insert(newIndex, character);
    });

    try {
      for (int i = 0; i < _characters.length; i++) {
        final updatedCharacter = _characters[i].copyWith(sortOrder: i);
        await _db.updateCharacter(updatedCharacter);
        _characters[i] = updatedCharacter;
      }
    } catch (e) {
      if (mounted) {
        CommonDialog.showSnackBar(
          context: context,
          message: '순서 변경에 실패했습니다: $e',
        );
      }
      await _loadCharacters();
    }
  }

  Future<void> _deleteSelectedCharacters() async {
    if (_selectedCharacterIds.isEmpty) return;

    final confirm = await CommonDialog.showConfirmation(
      context: context,
      title: '캐릭터 삭제',
      content: '선택한 ${_selectedCharacterIds.length}개의 캐릭터를 삭제하시겠습니까? 관련된 모든 데이터가 삭제됩니다.',
      confirmText: '삭제',
      isDestructive: true,
    );

    if (confirm == true) {
      try {
        for (final id in _selectedCharacterIds) {
          await _db.deleteCharacter(id);
        }
        setState(() {
          _selectedCharacterIds.clear();
          _isEditMode = false;
        });
        await _loadCharacters();
        if (mounted) {
          CommonDialog.showSnackBar(
            context: context,
            message: '선택한 캐릭터가 삭제되었습니다',
          );
        }
      } catch (e) {
        if (mounted) {
          CommonDialog.showSnackBar(
            context: context,
            message: '캐릭터 삭제에 실패했습니다: $e',
          );
        }
      }
    }
  }

  Future<void> _duplicateCharacter(int characterId) async {
    try {
      final character = await _db.readCharacter(characterId);
      if (character == null) throw Exception('캐릭터를 찾을 수 없습니다');

      final personas = await _db.readPersonas(characterId);
      final startScenarios = await _db.readStartScenarios(characterId);
      final characterBookFolders = await _db.readCharacterBookFolders(characterId);
      final standaloneCharacterBooks = await _db.readCharacterBooks(characterId);
      final coverImages = await _db.readCoverImages(characterId);

      for (final folder in characterBookFolders) {
        folder.characterBooks.addAll(await _db.readCharacterBooksByFolder(folder.id!));
      }

      final newCharacterId = await _db.createCharacter(
        Character(
          name: '${character.name} (복사본)',
          nickname: character.nickname,
          creatorNotes: character.creatorNotes,
          tags: List<String>.from(character.tags),
          description: character.description,
          isDraft: character.isDraft,
        ),
      );

      for (final persona in personas) {
        await _db.createPersona(persona.copyWith(id: null, characterId: newCharacterId));
      }

      for (final scenario in startScenarios) {
        await _db.createStartScenario(scenario.copyWith(id: null, characterId: newCharacterId));
      }

      for (final folder in characterBookFolders) {
        final newFolderId = await _db.createCharacterBookFolder(
          folder.copyWith(id: null, characterId: newCharacterId),
        );
        for (final book in folder.characterBooks) {
          await _db.createCharacterBook(
            book.copyWith(id: null, characterId: newCharacterId, folderId: newFolderId),
          );
        }
      }

      for (final book in standaloneCharacterBooks) {
        await _db.createCharacterBook(book.copyWith(id: null, characterId: newCharacterId));
      }

      for (final image in coverImages) {
        await _db.createCoverImage(image.copyWith(id: null, characterId: newCharacterId));
      }

      await _loadCharacters();
      if (mounted) {
        CommonDialog.showSnackBar(
          context: context,
          message: '캐릭터가 복사되었습니다',
        );
      }
    } catch (e) {
      if (mounted) {
        CommonDialog.showSnackBar(
          context: context,
          message: '캐릭터 복사에 실패했습니다: $e',
        );
      }
    }
  }

  Future<void> _deleteCharacter(int id) async {
    final confirm = await CommonDialog.showConfirmation(
      context: context,
      title: '캐릭터 삭제',
      content: '이 캐릭터를 삭제하시겠습니까? 관련된 모든 데이터가 삭제됩니다.',
      confirmText: '삭제',
      isDestructive: true,
    );

    if (confirm == true) {
      try {
        await _db.deleteCharacter(id);
        await _loadCharacters();
        if (mounted) {
          CommonDialog.showSnackBar(
            context: context,
            message: '캐릭터가 삭제되었습니다',
          );
        }
      } catch (e) {
        if (mounted) {
          CommonDialog.showSnackBar(
            context: context,
            message: '캐릭터 삭제에 실패했습니다: $e',
          );
        }
      }
    }
  }

  // ─── Export: format selection dialog ───────────────────────────────────────

  Future<void> _exportCharacter(int characterId) async {
    final format = await _showExportFormatDialog();
    if (format == null || !mounted) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: Center(child: CircularProgressIndicator()),
      ),
    );

    try {
      await _runExport(characterId, format);
    } catch (e) {
      if (mounted) {
        CommonDialog.showSnackBar(context: context, message: '내보내기 실패: $e');
      }
    } finally {
      if (mounted) Navigator.pop(context);
    }
  }

  /// Returns a format string or null if cancelled.
  /// Formats: 'flan' | 'v2_png' | 'v3_charx' | 'v3_charx_jpeg' | 'v3_png' | 'v3_json'
  Future<String?> _showExportFormatDialog() async {
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('내보내기 형식 선택'),
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Flan 형식'),
              subtitle: const Text('앱 전용 JSON (이미지 포함)'),
              onTap: () => Navigator.pop(ctx, 'flan'),
            ),
            ListTile(
              title: const Text('캐릭터카드 v2'),
              subtitle: const Text('PNG — 일부 데이터 잘릴 수 있음'),
              onTap: () => Navigator.pop(ctx, 'v2_png'),
            ),
            const Divider(height: 1),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('캐릭터카드 v3', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            ListTile(
              leading: const SizedBox(width: 16),
              title: const Text('charx'),
              onTap: () => Navigator.pop(ctx, 'v3_charx'),
            ),
            ListTile(
              leading: const SizedBox(width: 16),
              title: const Text('charx-JPEG'),
              onTap: () => Navigator.pop(ctx, 'v3_charx_jpeg'),
            ),
            ListTile(
              leading: const SizedBox(width: 16),
              title: const Text('PNG'),
              onTap: () => Navigator.pop(ctx, 'v3_png'),
            ),
            ListTile(
              leading: const SizedBox(width: 16),
              title: const Text('JSON'),
              onTap: () => Navigator.pop(ctx, 'v3_json'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
        ],
      ),
    );
  }

  // ─── Export: data loading helper ────────────────────────────────────────────

  Future<_CharacterExportData> _loadExportData(int characterId) async {
    final character = await _db.readCharacter(characterId);
    if (character == null) throw Exception('캐릭터를 찾을 수 없습니다');

    final personas = await _db.readPersonas(characterId);
    final startScenarios = await _db.readStartScenarios(characterId);
    final characterBookFolders = await _db.readCharacterBookFolders(characterId);
    final standaloneCharacterBooks = await _db.readCharacterBooks(characterId);
    final coverImages = await _db.readCoverImages(characterId);
    final additionalImages = await _db.readAdditionalImages(characterId);

    for (final folder in characterBookFolders) {
      folder.characterBooks.addAll(await _db.readCharacterBooksByFolder(folder.id!));
    }

    // Flatten all character books for CharacterCard formats
    final allCharacterBooks = [
      ...characterBookFolders.expand((f) => f.characterBooks),
      ...standaloneCharacterBooks,
    ];

    // Merge cover + additional images for export
    final allImages = [...coverImages, ...additionalImages];

    return _CharacterExportData(
      character: character,
      personas: personas,
      startScenarios: startScenarios,
      characterBookFolders: characterBookFolders,
      standaloneCharacterBooks: standaloneCharacterBooks,
      allCharacterBooks: allCharacterBooks,
      coverImages: allImages,
    );
  }

  // ─── Export: file save helpers ───────────────────────────────────────────────

  Future<void> _saveTextFile(String fileName, String content) async {
    if (Platform.isAndroid) {
      const platform = MethodChannel('com.flanapp.flan/file_saver');
      final ok = await platform.invokeMethod<bool>('saveToDownloads', {
        'fileName': fileName,
        'content': content,
      });
      if (mounted) {
        CommonDialog.showSnackBar(
          context: context,
          message: ok == true
              ? '내보내기 완료: /storage/emulated/0/Download/$fileName'
              : '파일 저장에 실패했습니다',
        );
      }
    } else if (Platform.isIOS) {
      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/$fileName';
      await File(path).writeAsString(content);
      if (mounted) {
        CommonDialog.showSnackBar(context: context, message: '내보내기 완료: $path');
      }
    }
  }

  Future<void> _saveBinaryFile(String fileName, List<int> bytes) async {
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/$fileName');
    await tempFile.writeAsBytes(bytes);
    try {
      if (Platform.isAndroid) {
        const platform = MethodChannel('com.flanapp.flan/file_saver');
        final ok = await platform.invokeMethod<bool>('copyFileToDownloads', {
          'sourcePath': tempFile.path,
          'fileName': fileName,
        });
        if (mounted) {
          CommonDialog.showSnackBar(
            context: context,
            message: ok == true
                ? '내보내기 완료: /storage/emulated/0/Download/$fileName'
                : '파일 저장에 실패했습니다',
          );
        }
      } else if (Platform.isIOS) {
        final dir = await getApplicationDocumentsDirectory();
        final path = '${dir.path}/$fileName';
        await tempFile.copy(path);
        if (mounted) {
          CommonDialog.showSnackBar(context: context, message: '내보내기 완료: $path');
        }
      }
    } finally {
      if (await tempFile.exists()) await tempFile.delete();
    }
  }

  // ─── Export: format dispatch ─────────────────────────────────────────────────

  Future<void> _runExport(int characterId, String format) async {
    final data = await _loadExportData(characterId);

    switch (format) {
      case 'flan':
        await _exportFlan(data);
      case 'v2_png':
        await _exportV2Png(data);
      case 'v3_json':
        await _exportV3Json(data);
      case 'v3_png':
        await _exportV3Png(data);
      case 'v3_charx':
        await _exportV3Charx(data);
      case 'v3_charx_jpeg':
        await _exportV3CharxJpeg(data);
    }
  }

  // ─── Export: Flan format (ZIP: character.json + images/) ──────────────────

  Future<void> _exportFlan(_CharacterExportData data) async {
    // Build cover image entries WITHOUT imageData (references only)
    final imageEntries = <CoverImage>[];
    final imageFiles = <({String zipPath, CoverImage image})>[];

    for (final image in data.coverImages) {
      final ext = image.path != null
          ? p.extension(image.path!).replaceFirst('.', '').toLowerCase()
          : 'png';
      final zipPath = 'images/${image.name}.${ext.isNotEmpty ? ext : 'png'}';

      imageEntries.add(CoverImage(
        characterId: image.characterId,
        name: image.name,
        order: image.order,
        isExpanded: image.isExpanded,
        imageType: image.imageType,
      ));
      imageFiles.add((zipPath: zipPath, image: image));
    }

    final jsonData = data.character.toJson(
      personas: data.personas,
      startScenarios: data.startScenarios,
      characterBookFolders: data.characterBookFolders,
      standaloneCharacterBooks: data.standaloneCharacterBooks,
      coverImages: imageEntries,
    );

    // Stream to ZIP: character.json + image files (one at a time)
    final tempDir = await getTemporaryDirectory();
    final fileName = '${data.character.name}.flan';
    final tempZipPath = '${tempDir.path}/$fileName';

    final zipWriter = await StreamingZipWriter.open(tempZipPath);

    final jsonBytes = utf8.encode(const JsonEncoder.withIndent('  ').convert(jsonData));
    await zipWriter.addFile('character.json', jsonBytes);

    for (final entry in imageFiles) {
      final bytes = await entry.image.resolveImageData();
      if (bytes == null) continue;
      await zipWriter.addFile(entry.zipPath, bytes);
    }

    await zipWriter.close();

    await _saveBinaryFile(fileName, await File(tempZipPath).readAsBytes());
    await File(tempZipPath).delete();
  }

  // ─── Export: Character Card V2 PNG ──────────────────────────────────────────

  Future<void> _exportV2Png(_CharacterExportData data) async {
    final cardJson = CharacterCardParser.toCharacterCardV2(
      character: data.character,
      personas: data.personas,
      startScenarios: data.startScenarios,
      characterBooks: data.allCharacterBooks,
    );

    final coverBytes = await _resolveCoverPng(data);
    final pngBytes = CharacterCardParser.embedMetadataInPng(coverBytes, cardJson);
    if (pngBytes == null) throw Exception('PNG 메타데이터 삽입 실패');

    await _saveBinaryFile('${data.character.name}.png', pngBytes);
  }

  // ─── Export: Character Card V3 JSON ─────────────────────────────────────────

  Future<void> _exportV3Json(_CharacterExportData data) async {
    final imageAssets = await _buildDataUriAssets(data);

    final cardJson = CharacterCardParser.toCharacterCardV3WithDataAssets(
      character: data.character,
      personas: data.personas,
      startScenarios: data.startScenarios,
      characterBooks: data.allCharacterBooks,
      imageAssets: imageAssets,
    );

    await _saveTextFile(
      '${data.character.name}.json',
      const JsonEncoder.withIndent('  ').convert(cardJson),
    );
  }

  // ─── Export: Character Card V3 PNG ──────────────────────────────────────────

  Future<void> _exportV3Png(_CharacterExportData data) async {
    final imageAssets = await _buildDataUriAssets(data);

    final cardJson = CharacterCardParser.toCharacterCardV3WithDataAssets(
      character: data.character,
      personas: data.personas,
      startScenarios: data.startScenarios,
      characterBooks: data.allCharacterBooks,
      imageAssets: imageAssets,
    );

    final coverBytes = await _resolveCoverPng(data);
    final pngBytes = CharacterCardParser.embedMetadataInPng(coverBytes, cardJson);
    if (pngBytes == null) throw Exception('PNG 메타데이터 삽입 실패');

    await _saveBinaryFile('${data.character.name}.png', pngBytes);
  }

  // ─── Export: Character Card V3 charx ────────────────────────────────────────

  Future<void> _exportV3Charx(_CharacterExportData data) async {
    final assetFiles = await _buildCharxAssets(data, asJpeg: false);

    final charxBytes = CharacterCardParser.buildCharxBytes(
      character: data.character,
      personas: data.personas,
      startScenarios: data.startScenarios,
      characterBooks: data.allCharacterBooks,
      assetFiles: assetFiles,
    );

    await _saveBinaryFile('${data.character.name}.charx', charxBytes);
  }

  // ─── Export: Character Card V3 charx-JPEG ───────────────────────────────────

  Future<void> _exportV3CharxJpeg(_CharacterExportData data) async {
    final assetFiles = await _buildCharxAssets(data, asJpeg: true);

    final charxBytes = CharacterCardParser.buildCharxBytes(
      character: data.character,
      personas: data.personas,
      startScenarios: data.startScenarios,
      characterBooks: data.allCharacterBooks,
      assetFiles: assetFiles,
    );

    // Polyglot: JPEG cover + ZIP concatenated
    final List<int> polyglot;
    if (assetFiles.isNotEmpty) {
      polyglot = [...assetFiles.first.bytes, ...charxBytes];
    } else {
      polyglot = charxBytes;
    }

    await _saveBinaryFile('${data.character.name}.charx', polyglot);
  }

  // ─── Export: image helpers ───────────────────────────────────────────────────

  /// Returns PNG bytes for the cover image (or a 1×1 white placeholder).
  Future<Uint8List> _resolveCoverPng(_CharacterExportData data) async {
    final covers = data.coverImages.where((i) => i.imageType == 'cover').toList()
      ..sort((CoverImage a, CoverImage b) => a.order.compareTo(b.order));

    final selected = covers.isEmpty ? null : (data.character.selectedCoverImageId != null
        ? covers.firstWhere(
            (i) => i.id == data.character.selectedCoverImageId,
            orElse: () => covers.first,
          )
        : covers.first);

    if (selected != null) {
      final bytes = await selected.resolveImageData();
      if (bytes != null) {
        final png = CharacterCardParser.convertToPng(bytes);
        if (png != null) return png;
      }
    }

    // 1×1 white PNG placeholder
    return _minimalPng();
  }

  /// Builds assets list with data: URIs (for JSON/PNG exports).
  /// Uses raw bytes without re-encoding to avoid OOM.
  Future<List<({String name, String mimeType, Uint8List bytes, String imageType})>> _buildDataUriAssets(
      _CharacterExportData data) async {
    final result = <({String name, String mimeType, Uint8List bytes, String imageType})>[];
    final sorted = [...data.coverImages]
      ..sort((CoverImage a, CoverImage b) => a.order.compareTo(b.order));

    for (final image in sorted) {
      final bytes = await image.resolveImageData();
      if (bytes == null) continue;
      final mime = CharacterCardParser.detectMimeType(bytes);
      result.add((name: image.name, mimeType: mime, bytes: bytes, imageType: image.imageType));
    }

    return result;
  }

  /// Builds asset file list for CHARX archive.
  /// Only converts the first cover image to JPEG when [asJpeg] is true; others pass through.
  Future<List<({String filename, String mimeType, Uint8List bytes, String imageType})>> _buildCharxAssets(
      _CharacterExportData data, {required bool asJpeg}) async {
    final result = <({String filename, String mimeType, Uint8List bytes, String imageType})>[];
    final sorted = [...data.coverImages]
      ..sort((CoverImage a, CoverImage b) => a.order.compareTo(b.order));

    bool firstCoverDone = false;
    for (final image in sorted) {
      final raw = await image.resolveImageData();
      if (raw == null) continue;

      final Uint8List bytes;
      final String ext;
      final String mime;
      final bool isCover = image.imageType == 'cover';

      if (asJpeg && isCover && !firstCoverDone) {
        final jpeg = CharacterCardParser.convertToJpeg(raw);
        if (jpeg == null) continue;
        bytes = jpeg;
        ext = 'jpg';
        mime = 'image/jpeg';
      } else {
        bytes = raw;
        final detected = CharacterCardParser.detectMimeType(raw);
        ext = CharacterCardParser.mimeToExt(detected);
        mime = detected;
      }

      final filename = isCover ? '${image.name}.$ext' : '${image.name}.$ext';
      result.add((filename: filename, mimeType: mime, bytes: bytes, imageType: image.imageType));
      if (isCover) firstCoverDone = true;
    }

    return result;
  }

  /// Returns a minimal 1×1 white PNG as a fallback cover.
  Uint8List _minimalPng() {
    // Pre-built 1×1 white PNG bytes
    return Uint8List.fromList([
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG signature
      0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, // IHDR length + type
      0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, // width=1, height=1
      0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53, // bit depth, color type, crc
      0xDE, 0x00, 0x00, 0x00, 0x0C, 0x49, 0x44, 0x41, // IDAT length + type
      0x54, 0x08, 0xD7, 0x63, 0xF8, 0xFF, 0xFF, 0x3F, // deflate stream
      0x00, 0x05, 0xFE, 0x02, 0xFE, 0xDC, 0xCC, 0x59, // data + crc
      0xE7, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, // IEND length + type
      0x44, 0xAE, 0x42, 0x60, 0x82,                   // IEND crc
    ]);
  }

  Future<void> _importCharacter() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );

      if (result == null || result.files.isEmpty) return;

      if (!mounted) return;
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
          throw FormatException('지원하지 않는 형식입니다: ${format ?? spec}');
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
            final filePath = await CharacterImageStorage.saveImage(
              character.name,
              baseName,
              'png',
              pngBytes,
            );
            coverImages = [
              CoverImage(
                characterId: 0,
                name: '표지 1',
                order: 0,
                path: filePath,
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
        // Flan ZIP 형식: character.json + images/
        final rawBytes = await file.readAsBytes();
        final archive = ZipDecoder().decodeBytes(rawBytes, verify: false);

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
              final savedPath = await CharacterImageStorage.saveImage(
                character.name, name, ext, imgBytes,
              );
              coverImages.add(CoverImage(
                characterId: 0,
                name: name,
                order: order,
                path: savedPath,
                imageType: imageType,
              ));
            } catch (_) {
              // Skip unreadable images
            }
          }
        }
      } else {
        throw FormatException('지원하지 않는 파일 형식입니다');
      }

      // DB에 저장
      final characterId = await _db.createCharacter(character);

      // 관련 데이터 저장
      if (personas != null) {
        for (final persona in personas) {
          await _db.createPersona(persona.copyWith(characterId: characterId));
        }
      }

      if (startScenarios != null) {
        for (final scenario in startScenarios) {
          await _db.createStartScenario(
              scenario.copyWith(characterId: characterId));
        }
      }

      if (characterBookFolders != null) {
        for (final folder in characterBookFolders) {
          final folderId = await _db.createCharacterBookFolder(
              folder.copyWith(characterId: characterId));

          // 폴더 내 캐릭터북 저장
          for (final characterBook in folder.characterBooks) {
            await _db.createCharacterBook(
                characterBook.copyWith(characterId: characterId, folderId: folderId));
          }
        }
      }

      if (standaloneCharacterBooks != null) {
        for (final characterBook in standaloneCharacterBooks) {
          await _db.createCharacterBook(
              characterBook.copyWith(characterId: characterId));
        }
      }

      int? firstCoverImageId;
      if (coverImages != null) {
        for (final image in coverImages) {
          final imageId = await _db.createCoverImage(image.copyWith(characterId: characterId));
          firstCoverImageId ??= imageId;
        }
      }

      if (additionalImages != null) {
        for (final image in additionalImages) {
          await _db.createCoverImage(image.copyWith(characterId: characterId));
        }
      }

      // 표지 이미지가 있으면 첫번째를 선택 상태로 설정
      if (firstCoverImageId != null) {
        await _db.updateCharacter(character.copyWith(
          id: characterId,
          selectedCoverImageId: firstCoverImageId,
        ));
      }

      await _loadCharacters();

      if (mounted) {
        Navigator.pop(context); // dismiss loading
        CommonDialog.showSnackBar(
          context: context,
          message: '캐릭터를 성공적으로 가져왔습니다',
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // dismiss loading
        CommonDialog.showSnackBar(
          context: context,
          message: '캐릭터 가져오기 실패: $e',
        );
      }
    }
  }

  String _getSortMethodLabel() {
    switch (_sortMethod) {
      case SortMethod.nameAsc:
        return '정렬방식: 캐릭터명 (오름차순)';
      case SortMethod.nameDesc:
        return '정렬방식: 캐릭터명 (내림차순)';
      case SortMethod.updatedAtAsc:
        return '정렬방식: 수정일시 (오름차순)';
      case SortMethod.updatedAtDesc:
        return '정렬방식: 수정일시 (내림차순)';
      case SortMethod.createdAtAsc:
        return '정렬방식: 생성일시 (오름차순)';
      case SortMethod.createdAtDesc:
        return '정렬방식: 생성일시 (내림차순)';
      case SortMethod.custom:
        return '정렬방식: 사용자 지정';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: _isEditMode
          ? '${_selectedCharacterIds.length}개 선택됨'
          : '캐릭터',
        showBackButton: false,
        showCloseButton: _isEditMode,
        onClosePressed: _toggleEditMode,
        actions: [
          if (!_isEditMode)
            CommonAppBarIconButton(
              icon: Icons.auto_awesome,
              offsetX: 10.0,
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AgentChatScreen(),
                  ),
                );
                _loadCharacters();
              },
              tooltip: 'Flan Agent',
            ),
          if (!_isEditMode)
            CommonAppBarIconButton(
              icon: Icons.edit_outlined,
              onPressed: _toggleEditMode,
              tooltip: '편집',
            ),
          if (_isEditMode)
            CommonAppBarIconButton(
              icon: Icons.delete_outline,
              onPressed: _selectedCharacterIds.isEmpty ? null : _deleteSelectedCharacters,
              tooltip: '삭제',
            ),
          if (!_isEditMode)
            CommonAppBarPopupMenuButton<String>(
              tooltip: '더보기',
              onSelected: (value) {
                if (value == 'import') {
                  _importCharacter();
                }
              },
              itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem<String>(
                  value: 'import',
                  child: Row(
                    children: [
                      Icon(Icons.download_outlined, size: 20),
                      SizedBox(width: 12),
                      Text('가져오기'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem<String>(
                  enabled: false,
                  child: Text(
                    '보기 방식',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'view_grid',
                  onTap: () {
                    setState(() {
                      _isGridView = true;
                    });
                    _saveViewPreference();
                  },
                  child: Row(
                    children: [
                      if (_isGridView)
                        const Icon(Icons.check, size: 20)
                      else
                        const SizedBox(width: 20),
                      const SizedBox(width: 12),
                      const Text('격자뷰'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'view_list',
                  onTap: () {
                    setState(() {
                      _isGridView = false;
                    });
                    _saveViewPreference();
                  },
                  child: Row(
                    children: [
                      if (!_isGridView)
                        const Icon(Icons.check, size: 20)
                      else
                        const SizedBox(width: 20),
                      const SizedBox(width: 12),
                      const Text('리스트뷰'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem<String>(
                  enabled: false,
                  child: Text(
                    '테마 선택',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'theme_light',
                  child: Consumer<ThemeProvider>(
                    builder: (context, themeProvider, child) {
                      return InkWell(
                        onTap: () {
                          themeProvider.setThemeMode(ThemeMode.light);
                          Navigator.pop(context);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          child: Row(
                            children: [
                              if (themeProvider.themeMode == ThemeMode.light)
                                const Icon(Icons.check, size: 20)
                              else
                                const SizedBox(width: 20),
                              const SizedBox(width: 12),
                              const Text('라이트 모드'),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'theme_dark',
                  child: Consumer<ThemeProvider>(
                    builder: (context, themeProvider, child) {
                      return InkWell(
                        onTap: () {
                          themeProvider.setThemeMode(ThemeMode.dark);
                          Navigator.pop(context);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          child: Row(
                            children: [
                              if (themeProvider.themeMode == ThemeMode.dark)
                                const Icon(Icons.check, size: 20)
                              else
                                const SizedBox(width: 20),
                              const SizedBox(width: 12),
                              const Text('다크 모드'),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'theme_system',
                  child: Consumer<ThemeProvider>(
                    builder: (context, themeProvider, child) {
                      return InkWell(
                        onTap: () {
                          themeProvider.setThemeMode(ThemeMode.system);
                          Navigator.pop(context);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          child: Row(
                            children: [
                              if (themeProvider.themeMode == ThemeMode.system)
                                const Icon(Icons.check, size: 20)
                              else
                                const SizedBox(width: 20),
                              const SizedBox(width: 12),
                              const Text('시스템 설정'),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ];
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 0.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                PopupMenuButton<SortMethod>(
                  offset: const Offset(0, 32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  onSelected: (selectedMethod) {
                    if (selectedMethod != _sortMethod) {
                      setState(() {
                        _sortMethod = selectedMethod;
                        _sortCharacters();
                      });
                      _saveSortPreference();
                    }
                  },
                  itemBuilder: (BuildContext context) {
                    return [
                      PopupMenuItem<SortMethod>(
                        value: SortMethod.nameAsc,
                        child: Row(
                          children: [
                            if (_sortMethod == SortMethod.nameAsc)
                              const Icon(Icons.check, size: 20)
                            else
                              const SizedBox(width: 20),
                            const SizedBox(width: 12),
                            const Text('캐릭터명 (오름차순)'),
                          ],
                        ),
                      ),
                      PopupMenuItem<SortMethod>(
                        value: SortMethod.nameDesc,
                        child: Row(
                          children: [
                            if (_sortMethod == SortMethod.nameDesc)
                              const Icon(Icons.check, size: 20)
                            else
                              const SizedBox(width: 20),
                            const SizedBox(width: 12),
                            const Text('캐릭터명 (내림차순)'),
                          ],
                        ),
                      ),
                      PopupMenuItem<SortMethod>(
                        value: SortMethod.updatedAtAsc,
                        child: Row(
                          children: [
                            if (_sortMethod == SortMethod.updatedAtAsc)
                              const Icon(Icons.check, size: 20)
                            else
                              const SizedBox(width: 20),
                            const SizedBox(width: 12),
                            const Text('수정일시 (오름차순)'),
                          ],
                        ),
                      ),
                      PopupMenuItem<SortMethod>(
                        value: SortMethod.updatedAtDesc,
                        child: Row(
                          children: [
                            if (_sortMethod == SortMethod.updatedAtDesc)
                              const Icon(Icons.check, size: 20)
                            else
                              const SizedBox(width: 20),
                            const SizedBox(width: 12),
                            const Text('수정일시 (내림차순)'),
                          ],
                        ),
                      ),
                      PopupMenuItem<SortMethod>(
                        value: SortMethod.createdAtAsc,
                        child: Row(
                          children: [
                            if (_sortMethod == SortMethod.createdAtAsc)
                              const Icon(Icons.check, size: 20)
                            else
                              const SizedBox(width: 20),
                            const SizedBox(width: 12),
                            const Text('생성일시 (오름차순)'),
                          ],
                        ),
                      ),
                      PopupMenuItem<SortMethod>(
                        value: SortMethod.createdAtDesc,
                        child: Row(
                          children: [
                            if (_sortMethod == SortMethod.createdAtDesc)
                              const Icon(Icons.check, size: 20)
                            else
                              const SizedBox(width: 20),
                            const SizedBox(width: 12),
                            const Text('생성일시 (내림차순)'),
                          ],
                        ),
                      ),
                      PopupMenuItem<SortMethod>(
                        value: SortMethod.custom,
                        child: Row(
                          children: [
                            if (_sortMethod == SortMethod.custom)
                              const Icon(Icons.check, size: 20)
                            else
                              const SizedBox(width: 20),
                            const SizedBox(width: 12),
                            const Text('사용자 지정'),
                          ],
                        ),
                      ),
                    ];
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Text(
                          _getSortMethodLabel(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_drop_down,
                          size: 18,
                          color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isGridView ? _buildGridView() : _buildListView(),
          ),
        ],
      ),
      floatingActionButton: _isEditMode ? null : CommonFab(
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => const CharacterEditScreen(),
            ),
          );
          if (result == true) {
            _loadCharacters();
          }
        },
      ),
    );
  }

  Widget _buildGridView() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_characters.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_add_outlined,
              size: 80,
              color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              '캐릭터가 없습니다',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '+ 버튼을 눌러 새 캐릭터를 추가해보세요',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth * 0.05;
    final spacing = screenWidth * 0.025;

    final gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      childAspectRatio: 0.592,
      crossAxisSpacing: spacing,
      mainAxisSpacing: spacing,
    );

    final padding = EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16.0);

    Widget buildCharacterCard(int index) {
      return CharacterCard(
        key: ValueKey(_characters[index].id),
        title: _characters[index].name,
        description: _characters[index].creatorNotes ?? '',
        tags: _characters[index].tags,
        imageData: _characterCoverImages[_characters[index].id],
        isEditMode: _isEditMode,
        isSelected: _selectedCharacterIds.contains(_characters[index].id),
        onTap: () async {
          if (_isEditMode) {
            _toggleCharacterSelection(_characters[index].id!);
          } else {
            final result = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (context) => CharacterViewScreen(characterId: _characters[index].id!),
              ),
            );
            if (result == true) {
              _loadCharacters();
            }
          }
        },
        onEdit: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => CharacterEditScreen(characterId: _characters[index].id),
            ),
          );
          if (result == true) {
            _loadCharacters();
          }
        },
        onCopy: () => _duplicateCharacter(_characters[index].id!),
        onExport: () => _exportCharacter(_characters[index].id!),
        onDelete: () => _deleteCharacter(_characters[index].id!),
      );
    }

    if (_sortMethod == SortMethod.custom) {
      return ReorderableGridView.builder(
        padding: padding,
        itemCount: _characters.length,
        onReorder: _reorderCharacters,
        gridDelegate: gridDelegate,
        itemBuilder: (context, index) => buildCharacterCard(index),
      );
    }

    return GridView.builder(
      padding: padding,
      itemCount: _characters.length,
      gridDelegate: gridDelegate,
      itemBuilder: (context, index) => buildCharacterCard(index),
    );
  }

  Widget _buildListView() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_characters.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_add_outlined,
              size: 80,
              color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              '캐릭터가 없습니다',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '+ 버튼을 눌러 새 캐릭터를 추가해보세요',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth * 0.05;

    if (_sortMethod == SortMethod.custom) {
      return ReorderableListView.builder(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16.0),
        itemCount: _characters.length,
        onReorder: _reorderCharacters,
        itemBuilder: (context, index) {
          return Padding(
            key: ValueKey(_characters[index].id),
            padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
            
            child: CharacterListItem(
              title: _characters[index].name,
              description: _characters[index].creatorNotes ?? '',
              tags: _characters[index].tags,
              imageData: _characterCoverImages[_characters[index].id],
              isEditMode: _isEditMode,
              isSelected: _selectedCharacterIds.contains(_characters[index].id),
              onTap: () async {
                if (_isEditMode) {
                  _toggleCharacterSelection(_characters[index].id!);
                } else {
                  final result = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CharacterViewScreen(characterId: _characters[index].id!),
                    ),
                  );
                  if (result == true) {
                    _loadCharacters();
                  }
                }
              },
              onEdit: () async {
                final result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CharacterEditScreen(characterId: _characters[index].id),
                  ),
                );
                if (result == true) {
                  _loadCharacters();
                }
              },
              onExport: () => _exportCharacter(_characters[index].id!),
              onDelete: () => _deleteCharacter(_characters[index].id!),
            ),
          );
        },

      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16.0),
      itemCount: _characters.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: CharacterListItem(
            title: _characters[index].name,
            description: _characters[index].creatorNotes ?? '',
            tags: _characters[index].tags,
            imageData: _characterCoverImages[_characters[index].id],
            isEditMode: _isEditMode,
            isSelected: _selectedCharacterIds.contains(_characters[index].id),
            onTap: () async {
              if (_isEditMode) {
                _toggleCharacterSelection(_characters[index].id!);
              } else {
                final result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CharacterViewScreen(characterId: _characters[index].id!),
                  ),
                );
                if (result == true) {
                  _loadCharacters();
                }
              }
            },
            onEdit: () async {
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (context) => CharacterEditScreen(characterId: _characters[index].id),
                ),
              );
              if (result == true) {
                _loadCharacters();
              }
            },
            onExport: () => _exportCharacter(_characters[index].id!),
            onDelete: () => _deleteCharacter(_characters[index].id!),
          ),
        );
      },
    );
  }
}

class _CharacterExportData {
  final Character character;
  final List<Persona> personas;
  final List<StartScenario> startScenarios;
  final List<CharacterBookFolder> characterBookFolders;
  final List<CharacterBook> standaloneCharacterBooks;
  final List<CharacterBook> allCharacterBooks;
  final List<CoverImage> coverImages;

  _CharacterExportData({
    required this.character,
    required this.personas,
    required this.startScenarios,
    required this.characterBookFolders,
    required this.standaloneCharacterBooks,
    required this.allCharacterBooks,
    required this.coverImages,
  });
}
