import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../constants/ui_constants.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/localization_provider.dart';
import '../../providers/tokenizer_provider.dart';
import '../../utils/character_image_storage.dart';
import '../../utils/token_counter.dart';
import '../../database/database_helper.dart';
import '../../models/character/character.dart';
import '../../models/character/cover_image.dart';
import '../../models/character/character_book_folder.dart';
import '../../models/character/persona.dart';
import '../../models/character/start_scenario.dart';
import '../../utils/common_dialog.dart';
import '../../widgets/common/common_custom_text_field.dart';
import '../../widgets/common/common_appbar.dart';
import '../../widgets/common/common_edit_text.dart';
import '../../widgets/common/common_title_medium.dart';
import 'tabs/additional_image_tab.dart';
import 'tabs/background_image_tab.dart';
import 'tabs/cover_image_tab.dart';
import 'tabs/character_book_tab.dart';
import 'tabs/persona_tab.dart';
import 'tabs/start_scenario_tab.dart';

class CharacterEditScreen extends StatefulWidget {
  final int? characterId;

  const CharacterEditScreen({
    super.key,
    this.characterId,
  });

  @override
  State<CharacterEditScreen> createState() => _CharacterEditScreenState();
}

class _CharacterEditScreenState extends State<CharacterEditScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _creatorNotesController = TextEditingController();
  final _keywordsController = TextEditingController();
  final _descriptionController = TextEditingController();

  // 로어북 관련 상태
  final List<CharacterBookFolder> _folders = [];
  final List<CharacterBook> _standaloneCharacterBooks = [];

  // 페르소나 관련 상태
  final List<Persona> _personas = [];

  // 시작설정 관련 상태
  final List<StartScenario> _startScenarios = [];

  // 표지 관련 상태
  final List<CoverImage> _coverImages = [];
  int? _selectedCoverImageId;

  // 추가 이미지 상태
  final List<CoverImage> _additionalImages = [];

  // 배경 이미지 상태
  final List<CoverImage> _backgroundImages = [];

  // 세계 날짜
  DateTime? _worldStartDate;
  DateTime? _originalWorldStartDate;

  // SNS 설정 컨트롤러
  final _communityNameController = TextEditingController();
  final _communityMoodController = TextEditingController();
  final _communityLanguageController = TextEditingController();

  // 데이터베이스
  final DatabaseHelper _db = DatabaseHelper.instance;
  bool _isLoading = false;
  bool _isSaving = false; // 저장 중에는 자동 저장 비활성화

  // 원본 데이터 저장 (변경 감지용)
  String _originalName = '';
  String _originalNickname = '';
  String _originalCreatorNotes = '';
  String _originalKeywords = '';
  String _originalDescription = '';
  int? _originalSelectedCoverImageId;
  List<CharacterBookFolder> _originalFolders = [];
  List<CharacterBook> _originalStandaloneCharacterBooks = [];
  List<Persona> _originalPersonas = [];
  List<StartScenario> _originalStartScenarios = [];
  List<CoverImage> _originalCoverImages = [];
  List<CoverImage> _originalAdditionalImages = [];
  List<CoverImage> _originalBackgroundImages = [];
  String _originalCommunityName = '';
  String _originalCommunityMood = '';
  String _originalCommunityLanguage = '';

  bool get _isEditMode => widget.characterId != null;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 9, vsync: this);

    // 캐릭터 데이터 로드 → 자동 저장 복원 → 기본값 채우기
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_isEditMode) {
        await _loadCharacterData();
      }
      await _checkAndRestoreAutoSave();
      if (!mounted) return;
      _fillDefaultCommunityLanguageIfEmpty();
    });

    // 텍스트 컨트롤러에 리스너 추가하여 자동 저장
    _nameController.addListener(_autoSave);
    _nicknameController.addListener(_autoSave);
    _creatorNotesController.addListener(_autoSave);
    _keywordsController.addListener(_autoSave);
    _descriptionController.addListener(_autoSave);
    _communityNameController.addListener(_autoSave);
    _communityMoodController.addListener(_autoSave);
    _communityLanguageController.addListener(_autoSave);
  }

  Future<void> _loadCharacterData() async {
    if (widget.characterId == null) return;

    setState(() => _isLoading = true);

    try {
      // 캐릭터 기본 정보 로드
      final character = await _db.readCharacter(widget.characterId!);
      if (character != null) {
        _nameController.text = character.name;
        _nicknameController.text = character.nickname ?? '';
        _creatorNotesController.text = character.creatorNotes ?? '';
        _keywordsController.text = character.tags.join(', ');
        _descriptionController.text = character.description ?? '';
        _selectedCoverImageId = character.selectedCoverImageId;

        // 원본 데이터 저장
        _originalName = character.name;
        _originalNickname = character.nickname ?? '';
        _originalCreatorNotes = character.creatorNotes ?? '';
        _originalKeywords = character.tags.join(', ');
        _originalDescription = character.description ?? '';
        _originalSelectedCoverImageId = character.selectedCoverImageId;

        _communityNameController.text = character.communityName ?? '';
        _communityMoodController.text = character.communityMood ?? '';
        _communityLanguageController.text = character.communityLanguage ?? '';
        _originalCommunityName = character.communityName ?? '';
        _originalCommunityMood = character.communityMood ?? '';
        _originalCommunityLanguage = character.communityLanguage ?? '';
        _worldStartDate = character.worldStartDate;
        _originalWorldStartDate = character.worldStartDate;
      }

      // 로어북 폴더 및 로어북 로드
      final folders = await _db.readCharacterBookFolders(widget.characterId!);
      for (var folder in folders) {
        final characterBooks = await _db.readCharacterBooksByFolder(folder.id!);
        for (final book in characterBooks) {
          await _loadBookImages(book);
        }
        folder.characterBooks.addAll(characterBooks);
      }
      _folders.addAll(folders);
      _originalFolders = _folders.map((f) => _copyFolder(f)).toList();

      // 독립형 로어북 로드
      final standaloneCharacterBooks = await _db.readStandaloneCharacterBooks(widget.characterId!);
      for (final book in standaloneCharacterBooks) {
        await _loadBookImages(book);
      }
      _standaloneCharacterBooks.addAll(standaloneCharacterBooks);
      _originalStandaloneCharacterBooks = standaloneCharacterBooks.map((lb) => _copyCharacterBook(lb)).toList();

      // 페르소나 로드
      final personas = await _db.readPersonas(widget.characterId!);
      _personas.addAll(personas);
      _originalPersonas = personas.map((p) => _copyPersona(p)).toList();

      // 시작설정 로드
      final scenarios = await _db.readStartScenarios(widget.characterId!);
      _startScenarios.addAll(scenarios);
      _originalStartScenarios = scenarios.map((s) => _copyStartScenario(s)).toList();

      // 표지 이미지 로드
      final coverImages = await _db.readCoverImages(widget.characterId!);
      _coverImages.addAll(coverImages);
      _originalCoverImages = coverImages.map((c) => _copyCoverImage(c)).toList();

      // 추가 이미지 로드
      final additionalImages = await _db.readAdditionalImages(widget.characterId!);
      _additionalImages.addAll(additionalImages);
      _originalAdditionalImages = additionalImages.map((c) => _copyCoverImage(c)).toList();

      // 배경 이미지 로드
      final backgroundImages = await _db.readBackgroundImages(widget.characterId!);
      _backgroundImages.addAll(backgroundImages);
      _originalBackgroundImages = backgroundImages.map((c) => _copyCoverImage(c)).toList();

      setState(() {});
    } catch (e) {
      if (mounted) {
        CommonDialog.showSnackBar(
          context: context,
          message: AppLocalizations.of(context).characterEditDataLoadFailed(e.toString()),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 데이터 복사 헬퍼 메서드들
  CharacterBookFolder _copyFolder(CharacterBookFolder folder) {
    final copied = CharacterBookFolder(
      id: folder.id,
      characterId: folder.characterId,
      name: folder.name,
      order: folder.order,
      isExpanded: folder.isExpanded,
    );
    copied.characterBooks.addAll(folder.characterBooks.map((lb) => _copyCharacterBook(lb)));
    return copied;
  }

  CharacterBook _copyCharacterBook(CharacterBook characterBook) {
    return CharacterBook(
      id: characterBook.id,
      characterId: characterBook.characterId,
      folderId: characterBook.folderId,
      name: characterBook.name,
      order: characterBook.order,
      isExpanded: characterBook.isExpanded,
      enabled: characterBook.enabled,
      keys: List<String>.from(characterBook.keys),
      secondaryKeyUsage: characterBook.secondaryKeyUsage,
      secondaryKeys: List<String>.from(characterBook.secondaryKeys),
      insertionOrder: characterBook.insertionOrder,
      content: characterBook.content,
      images: characterBook.images.map(_copyCoverImage).toList(),
    );
  }

  /// Pulls the character-book's image rows into the in-memory model. Called
  /// after [DatabaseHelper.readCharacterBooksByFolder] /
  /// [DatabaseHelper.readStandaloneCharacterBooks] since those queries only
  /// populate the book row itself, not its attached images.
  Future<void> _loadBookImages(CharacterBook book) async {
    if (book.id == null || book.id! <= 0) return;
    final images = await _db.readCharacterBookImages(book.id!);
    book.images
      ..clear()
      ..addAll(images);
  }

  /// Reconciles a character-book's in-memory image list with the DB.
  /// Deletes rows no longer present, inserts new ones, updates the rest —
  /// mirroring the deletion/creation pattern used for the top-level image tabs.
  Future<void> _saveBookImages(
    CharacterBook book,
    int savedBookId,
    int characterId,
  ) async {
    final bookWasPersisted = _isEditMode &&
        book.id != null &&
        book.id! > 0 &&
        book.characterId == characterId;

    if (bookWasPersisted) {
      final existing = await _db.readCharacterBookImages(book.id!);
      final currentIds = book.images
          .where((c) => c.id != null && c.id! > 0)
          .map((c) => c.id!)
          .toSet();
      for (final existingImage in existing) {
        if (!currentIds.contains(existingImage.id)) {
          if (existingImage.path != null) {
            await CharacterImageStorage.deleteImage(existingImage.path!);
          }
          await _db.deleteCoverImage(existingImage.id!);
        }
      }
    }

    for (final image in book.images) {
      final isNew = image.id == null || image.id! < 0;
      final isCopy = !bookWasPersisted || image.characterId != characterId;
      if (isNew || isCopy) {
        await _db.createCoverImage(image.copyWith(
          id: null,
          characterId: characterId,
          characterBookId: savedBookId,
          imageType: 'characterBook',
        ));
      } else {
        await _db.updateCoverImage(image.copyWith(
          characterId: characterId,
          characterBookId: savedBookId,
          imageType: 'characterBook',
        ));
      }
    }
  }

  Persona _copyPersona(Persona persona) {
    return Persona(
      id: persona.id,
      characterId: persona.characterId,
      name: persona.name,
      order: persona.order,
      isExpanded: persona.isExpanded,
      content: persona.content,
    );
  }

  StartScenario _copyStartScenario(StartScenario scenario) {
    return StartScenario(
      id: scenario.id,
      characterId: scenario.characterId,
      name: scenario.name,
      order: scenario.order,
      isExpanded: scenario.isExpanded,
      startSetting: scenario.startSetting,
      startMessage: scenario.startMessage,
    );
  }

  CoverImage _copyCoverImage(CoverImage image) {
    return CoverImage(
      id: image.id,
      characterId: image.characterId,
      name: image.name,
      order: image.order,
      isExpanded: image.isExpanded,
      imageData: image.imageData,
      path: image.path,
      imageType: image.imageType,
    );
  }

  // 데이터 변경 감지
  bool _hasChanges() {
    // 기본 정보 변경 확인
    if (_nameController.text != _originalName ||
        _nicknameController.text != _originalNickname ||
        _creatorNotesController.text != _originalCreatorNotes ||
        _keywordsController.text != _originalKeywords ||
        _descriptionController.text != _originalDescription ||
        _selectedCoverImageId != _originalSelectedCoverImageId ||
        _communityNameController.text != _originalCommunityName ||
        _communityMoodController.text != _originalCommunityMood ||
        _communityLanguageController.text != _originalCommunityLanguage ||
        _worldStartDate != _originalWorldStartDate) {
      return true;
    }

    // 로어북 폴더 변경 확인
    if (_folders.length != _originalFolders.length) return true;
    for (int i = 0; i < _folders.length; i++) {
      if (_folders[i].name != _originalFolders[i].name ||
          _folders[i].isExpanded != _originalFolders[i].isExpanded ||
          _folders[i].characterBooks.length != _originalFolders[i].characterBooks.length) {
        return true;
      }
      for (int j = 0; j < _folders[i].characterBooks.length; j++) {
        final current = _folders[i].characterBooks[j];
        final original = _originalFolders[i].characterBooks[j];
        if (current.name != original.name ||
            current.content != original.content ||
            current.enabled != original.enabled ||
            current.keys.join(',') != original.keys.join(',') ||
            _bookImagesChanged(current.images, original.images)) {
          return true;
        }
      }
    }

    // 독립형 로어북 변경 확인
    if (_standaloneCharacterBooks.length != _originalStandaloneCharacterBooks.length) return true;
    for (int i = 0; i < _standaloneCharacterBooks.length; i++) {
      final current = _standaloneCharacterBooks[i];
      final original = _originalStandaloneCharacterBooks[i];
      if (current.name != original.name ||
          current.content != original.content ||
          current.enabled != original.enabled ||
          current.keys.join(',') != original.keys.join(',') ||
          _bookImagesChanged(current.images, original.images)) {
        return true;
      }
    }

    // 페르소나 변경 확인
    if (_personas.length != _originalPersonas.length) return true;
    for (int i = 0; i < _personas.length; i++) {
      if (_personas[i].name != _originalPersonas[i].name ||
          _personas[i].content != _originalPersonas[i].content) {
        return true;
      }
    }

    // 시작설정 변경 확인
    if (_startScenarios.length != _originalStartScenarios.length) return true;
    for (int i = 0; i < _startScenarios.length; i++) {
      if (_startScenarios[i].name != _originalStartScenarios[i].name ||
          _startScenarios[i].startSetting != _originalStartScenarios[i].startSetting ||
          _startScenarios[i].startMessage != _originalStartScenarios[i].startMessage) {
        return true;
      }
    }

    // 표지 이미지 변경 확인
    if (_coverImages.length != _originalCoverImages.length) return true;
    for (int i = 0; i < _coverImages.length; i++) {
      if (_coverImages[i].name != _originalCoverImages[i].name ||
          _coverImages[i].path != _originalCoverImages[i].path) {
        return true;
      }
    }

    // 추가 이미지 변경 확인
    if (_additionalImages.length != _originalAdditionalImages.length) return true;
    for (int i = 0; i < _additionalImages.length; i++) {
      if (_additionalImages[i].name != _originalAdditionalImages[i].name ||
          _additionalImages[i].path != _originalAdditionalImages[i].path) {
        return true;
      }
    }

    // 배경 이미지 변경 확인
    if (_backgroundImages.length != _originalBackgroundImages.length) return true;
    for (int i = 0; i < _backgroundImages.length; i++) {
      if (_backgroundImages[i].name != _originalBackgroundImages[i].name ||
          _backgroundImages[i].path != _originalBackgroundImages[i].path) {
        return true;
      }
    }

    return false;
  }

  /// CharacterBook.toMap() plus the runtime-only images list. Used by the
  /// autosave payload so unsaved image entries survive accidental exits.
  Map<String, dynamic> _bookAutoSaveMap(CharacterBook book) {
    final map = book.toMap();
    map['images'] = book.images.map((c) => c.toMap()).toList();
    return map;
  }

  /// Inverse of [_bookAutoSaveMap]: rebuilds a CharacterBook plus its image
  /// list from the autosave JSON shape.
  CharacterBook _restoreBookFromAutoSaveMap(Map<String, dynamic> map) {
    final book = CharacterBook.fromMap(map);
    final rawImages = map['images'];
    if (rawImages is List) {
      for (final imageMap in rawImages) {
        book.images.add(CoverImage.fromMap(imageMap as Map<String, dynamic>));
      }
    }
    return book;
  }

  bool _bookImagesChanged(List<CoverImage> current, List<CoverImage> original) {
    if (current.length != original.length) return true;
    for (int i = 0; i < current.length; i++) {
      if (current[i].name != original[i].name ||
          current[i].path != original[i].path ||
          current[i].id != original[i].id) {
        return true;
      }
    }
    return false;
  }

  // 입력된 데이터가 있는지 확인 (새 캐릭터 추가 모드용)
  bool _hasInputData() {
    // 이름이 비어있으면 데이터가 없는 것으로 간주
    if (_nameController.text.isEmpty) return false;

    // 기본 정보 확인
    if (_creatorNotesController.text.isNotEmpty ||
        _keywordsController.text.isNotEmpty ||
        _descriptionController.text.isNotEmpty ||
        _selectedCoverImageId != null) {
      return true;
    }

    // 하위 데이터 확인
    if (_folders.isNotEmpty ||
        _standaloneCharacterBooks.isNotEmpty ||
        _personas.isNotEmpty ||
        _startScenarios.isNotEmpty ||
        _coverImages.isNotEmpty ||
        _additionalImages.isNotEmpty ||
        _backgroundImages.isNotEmpty) {
      return true;
    }

    // 이름만 입력되어 있는 경우도 데이터가 있는 것으로 간주
    return _nameController.text.isNotEmpty;
  }

  @override
  void dispose() {
    // 뒤로가기 시 변경사항 없으면 임시저장 데이터 삭제 (동기적으로)
    if (_isEditMode && !_hasChanges()) {
      _clearAutoSaveSync();
    } else if (!_isEditMode && !_hasInputData()) {
      _clearAutoSaveSync();
    }

    _tabController.dispose();
    _nameController.dispose();
    _nicknameController.dispose();
    _creatorNotesController.dispose();
    _keywordsController.dispose();
    _descriptionController.dispose();
    _communityNameController.dispose();
    _communityMoodController.dispose();
    _communityLanguageController.dispose();
    super.dispose();
  }

  void _clearAutoSaveSync() {
    SharedPreferences.getInstance().then((prefs) {
      prefs.remove(_getAutoSaveKey());
    }).catchError((e) {
      debugPrint('자동 저장 데이터 삭제 실패: $e');
    });
  }

  String _getAutoSaveKey() {
    // 편집 모드면 characterId 기반, 생성 모드면 'new' 키 사용
    return _isEditMode ? 'autosave_character_${widget.characterId}' : 'autosave_character_new';
  }

  void _fillDefaultCommunityLanguageIfEmpty() {
    if (_communityLanguageController.text.isNotEmpty) return;
    final defaultLanguage =
        context.read<LocalizationProvider>().effectiveAiLanguageName;
    _communityLanguageController.text = defaultLanguage;
    if (_isEditMode) {
      _originalCommunityLanguage = defaultLanguage;
    }
  }

  Future<void> _autoSave() async {
    // 저장 중이면 자동 저장하지 않음
    if (_isSaving) return;

    // 편집 모드: 변경된 데이터가 없으면 자동 저장하지 않음
    if (_isEditMode && !_hasChanges()) return;

    // 추가 모드: 입력된 데이터가 없으면 자동 저장하지 않음
    if (!_isEditMode && !_hasInputData()) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'name': _nameController.text,
        'nickname': _nicknameController.text,
        'creatorNotes': _creatorNotesController.text,
        'keywords': _keywordsController.text,
        'description': _descriptionController.text,
        'selectedCoverImageId': _selectedCoverImageId,
        'folders': _folders.map((f) {
          final folderMap = f.toMap();
          folderMap['characterBooks'] = f.characterBooks.map(_bookAutoSaveMap).toList();
          return folderMap;
        }).toList(),
        'standaloneCharacterBooks': _standaloneCharacterBooks.map(_bookAutoSaveMap).toList(),
        'personas': _personas.map((p) => p.toMap()).toList(),
        'startScenarios': _startScenarios.map((s) => s.toMap()).toList(),
        'coverImages': _coverImages.map((c) => c.toMap()).toList(),
        'additionalImages': _additionalImages.map((c) => c.toMap()).toList(),
        'backgroundImages': _backgroundImages.map((c) => c.toMap()).toList(),
        'communityName': _communityNameController.text,
        'communityMood': _communityMoodController.text,
        'communityLanguage': _communityLanguageController.text,
        'worldStartDate': _worldStartDate?.toIso8601String(),
        'timestamp': DateTime.now().toIso8601String(),
      };
      await prefs.setString(_getAutoSaveKey(), jsonEncode(data));
    } catch (e) {
      debugPrint('자동 저장 실패: $e');
    }
  }

  Future<void> _checkAndRestoreAutoSave() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final autoSaveData = prefs.getString(_getAutoSaveKey());

      if (autoSaveData == null) return;

      final data = jsonDecode(autoSaveData) as Map<String, dynamic>;
      final timestamp = DateTime.parse(data['timestamp'] as String);

      // 자동 저장된 시간이 너무 오래되었으면 무시 (7일)
      if (DateTime.now().difference(timestamp).inDays > 7) {
        await prefs.remove(_getAutoSaveKey());
        return;
      }

      // 편집 모드에서는 자동 저장 데이터가 있으면 복원 여부 묻기
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);

      final shouldRestore = await CommonDialog.showConfirmation(
        context: context,
        title: l10n.characterEditDraftFoundTitle,
        content: l10n.characterEditDraftFoundContent(_formatTimestamp(timestamp, l10n)),
        confirmText: l10n.characterEditDraftLoad,
        cancelText: l10n.commonCancel,
      );

      if (shouldRestore == true && mounted) {
        setState(() {
          _nameController.text = data['name'] as String? ?? '';
          _nicknameController.text = data['nickname'] as String? ?? '';
          _creatorNotesController.text = data['creatorNotes'] as String? ?? '';
          _keywordsController.text = data['keywords'] as String? ?? '';
          _descriptionController.text = data['description'] as String? ?? '';
          _selectedCoverImageId = data['selectedCoverImageId'] as int?;

          // 로어북 폴더 복원
          _folders.clear();
          if (data['folders'] != null) {
            for (var folderMap in data['folders'] as List) {
              final folder = CharacterBookFolder.fromMap(folderMap as Map<String, dynamic>);
              if (folderMap['characterBooks'] != null) {
                for (var lbMap in folderMap['characterBooks'] as List) {
                  folder.characterBooks.add(_restoreBookFromAutoSaveMap(lbMap as Map<String, dynamic>));
                }
              }
              _folders.add(folder);
            }
          }

          // 독립형 로어북 복원
          _standaloneCharacterBooks.clear();
          if (data['standaloneCharacterBooks'] != null) {
            for (var lbMap in data['standaloneCharacterBooks'] as List) {
              _standaloneCharacterBooks.add(_restoreBookFromAutoSaveMap(lbMap as Map<String, dynamic>));
            }
          }

          // 페르소나 복원
          _personas.clear();
          if (data['personas'] != null) {
            for (var pMap in data['personas'] as List) {
              _personas.add(Persona.fromMap(pMap as Map<String, dynamic>));
            }
          }

          // 시작설정 복원
          _startScenarios.clear();
          if (data['startScenarios'] != null) {
            for (var sMap in data['startScenarios'] as List) {
              _startScenarios.add(StartScenario.fromMap(sMap as Map<String, dynamic>));
            }
          }

          // 표지 이미지 복원
          _coverImages.clear();
          if (data['coverImages'] != null) {
            for (var cMap in data['coverImages'] as List) {
              _coverImages.add(CoverImage.fromMap(cMap as Map<String, dynamic>));
            }
          }

          // 추가 이미지 복원
          _additionalImages.clear();
          if (data['additionalImages'] != null) {
            for (var cMap in data['additionalImages'] as List) {
              _additionalImages.add(CoverImage.fromMap(cMap as Map<String, dynamic>));
            }
          }

          // 배경 이미지 복원
          _backgroundImages.clear();
          if (data['backgroundImages'] != null) {
            for (var cMap in data['backgroundImages'] as List) {
              _backgroundImages.add(CoverImage.fromMap(cMap as Map<String, dynamic>));
            }
          }

          // SNS 설정 복원
          _communityNameController.text = data['communityName'] as String? ?? '';
          _communityMoodController.text = data['communityMood'] as String? ?? '';
          _communityLanguageController.text = data['communityLanguage'] as String? ?? '';

          // 세계 날짜 복원
          final wsd = data['worldStartDate'] as String?;
          _worldStartDate = wsd != null ? DateTime.tryParse(wsd) : null;
        });

        // 복원한 데이터를 원본으로 설정 (편집 모드인 경우)
        if (_isEditMode) {
          _originalName = _nameController.text;
          _originalNickname = _nicknameController.text;
          _originalCreatorNotes = _creatorNotesController.text;
          _originalKeywords = _keywordsController.text;
          _originalDescription = _descriptionController.text;
          _originalSelectedCoverImageId = _selectedCoverImageId;
          _originalFolders = _folders.map((f) => _copyFolder(f)).toList();
          _originalStandaloneCharacterBooks = _standaloneCharacterBooks.map((lb) => _copyCharacterBook(lb)).toList();
          _originalPersonas = _personas.map((p) => _copyPersona(p)).toList();
          _originalStartScenarios = _startScenarios.map((s) => _copyStartScenario(s)).toList();
          _originalCoverImages = _coverImages.map((c) => _copyCoverImage(c)).toList();
          _originalAdditionalImages = _additionalImages.map((c) => _copyCoverImage(c)).toList();
          _originalBackgroundImages = _backgroundImages.map((c) => _copyCoverImage(c)).toList();
          _originalCommunityName = _communityNameController.text;
          _originalCommunityMood = _communityMoodController.text;
          _originalCommunityLanguage = _communityLanguageController.text;
          _originalWorldStartDate = _worldStartDate;
        }
      } else if (shouldRestore == false) {
        // 사용자가 취소를 선택하면 자동 저장 데이터 삭제
        await prefs.remove(_getAutoSaveKey());
      }
    } catch (e) {
      debugPrint('자동 저장 데이터 복원 실패: $e');
    }
  }

  String _formatTimestamp(DateTime timestamp, AppLocalizations l10n) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) {
      return l10n.characterEditJustNow;
    } else if (diff.inHours < 1) {
      return l10n.characterEditMinutesAgo(diff.inMinutes);
    } else if (diff.inDays < 1) {
      return l10n.characterEditHoursAgo(diff.inHours);
    } else {
      return l10n.characterEditDaysAgo(diff.inDays);
    }
  }

  Future<void> _clearAutoSave() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_getAutoSaveKey());
    } catch (e) {
      debugPrint('자동 저장 데이터 삭제 실패: $e');
    }
  }

  Future<void> _handleSave() async {
    // 현재 포커스된 EditText의 값을 커밋하기 위해 포커스 해제
    FocusScope.of(context).unfocus();
    await Future.delayed(Duration.zero);

    // 이름만 필수로 체크
    if (_nameController.text.isEmpty) {
      CommonDialog.showSnackBar(
        context: context,
        message: AppLocalizations.of(context).characterEditNameRequired,
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _isSaving = true; // 저장 시작
    });

    try {
      int characterId;

      if (_isEditMode) {
        // 기존 캐릭터 수정
        characterId = widget.characterId!;
        final tags = _keywordsController.text.isEmpty
            ? <String>[]
            : _keywordsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

        final character = Character(
          id: characterId,
          name: _nameController.text,
          nickname: _nicknameController.text.isEmpty ? null : _nicknameController.text,
          creatorNotes: _creatorNotesController.text.isEmpty ? null : _creatorNotesController.text,
          tags: tags,
          description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
          selectedCoverImageId: _selectedCoverImageId,
          updatedAt: DateTime.now(),
          isDraft: false,
          communityName: _communityNameController.text.isEmpty ? null : _communityNameController.text,
          communityMood: _communityMoodController.text.isEmpty ? null : _communityMoodController.text,
          communityLanguage: _communityLanguageController.text.isEmpty ? null : _communityLanguageController.text,
          worldStartDate: _worldStartDate,
        );
        await _db.updateCharacter(character);
      } else {
        // 새 캐릭터 생성
        final tags = _keywordsController.text.isEmpty
            ? <String>[]
            : _keywordsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

        final character = Character(
          name: _nameController.text,
          nickname: _nicknameController.text.isEmpty ? null : _nicknameController.text,
          creatorNotes: _creatorNotesController.text.isEmpty ? null : _creatorNotesController.text,
          tags: tags,
          description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
          selectedCoverImageId: _selectedCoverImageId,
          isDraft: false,
          communityName: _communityNameController.text.isEmpty ? null : _communityNameController.text,
          communityMood: _communityMoodController.text.isEmpty ? null : _communityMoodController.text,
          communityLanguage: _communityLanguageController.text.isEmpty ? null : _communityLanguageController.text,
          worldStartDate: _worldStartDate,
        );
        characterId = await _db.createCharacter(character);
      }

      // 하위 데이터 저장
      await _saveSubData(characterId);

      // 저장 성공 시 자동 저장 데이터 삭제
      await _clearAutoSave();

      if (mounted) {
        setState(() {
          _isLoading = false;
          _isSaving = false;
        });

        final l10n = AppLocalizations.of(context);
        CommonDialog.showSnackBar(
          context: context,
          message: _isEditMode ? l10n.characterEditUpdated : l10n.characterEditCreated,
        );
        Navigator.pop(context, true); // true를 반환하여 목록 새로고침 유도
      }
    } catch (e) {
      if (mounted) {
        CommonDialog.showSnackBar(
          context: context,
          message: AppLocalizations.of(context).characterEditSaveFailed(e.toString()),
        );
        setState(() {
          _isLoading = false;
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _saveSubData(int characterId) async {
    debugPrint('=== _saveSubData 시작 ===');
    debugPrint('characterId: $characterId');
    debugPrint('_isEditMode: $_isEditMode');
    debugPrint('_folders.length: ${_folders.length}');

    // Edit 모드일 때: DB에 있지만 메모리에 없는 항목들 삭제
    if (_isEditMode) {
      // 로어북 폴더 삭제 처리
      final existingFolders = await _db.readCharacterBookFolders(characterId);
      final currentFolderIds = _folders
          .where((f) => f.id != null && f.id! > 0)
          .map((f) => f.id!)
          .toSet();
      for (var existingFolder in existingFolders) {
        if (!currentFolderIds.contains(existingFolder.id)) {
          await _db.deleteCharacterBookFolder(existingFolder.id!);
          debugPrint('폴더 삭제: ${existingFolder.id}');
        }
      }

      // 독립형 로어북 삭제 처리
      final existingStandaloneCharacterBooks = await _db.readStandaloneCharacterBooks(characterId);
      final currentStandaloneLbIds = _standaloneCharacterBooks
          .where((lb) => lb.id != null && lb.id! > 0)
          .map((lb) => lb.id!)
          .toSet();
      for (var existingLb in existingStandaloneCharacterBooks) {
        if (!currentStandaloneLbIds.contains(existingLb.id)) {
          await _db.deleteCharacterBook(existingLb.id!);
          debugPrint('독립형 로어북 삭제: ${existingLb.id}');
        }
      }

      // 페르소나 삭제 처리
      final existingPersonas = await _db.readPersonas(characterId);
      final currentPersonaIds = _personas
          .where((p) => p.id != null && p.id! > 0)
          .map((p) => p.id!)
          .toSet();
      for (var existingPersona in existingPersonas) {
        if (!currentPersonaIds.contains(existingPersona.id)) {
          await _db.deletePersona(existingPersona.id!);
          debugPrint('페르소나 삭제: ${existingPersona.id}');
        }
      }

      // 시작설정 삭제 처리
      final existingScenarios = await _db.readStartScenarios(characterId);
      final currentScenarioIds = _startScenarios
          .where((s) => s.id != null && s.id! > 0)
          .map((s) => s.id!)
          .toSet();
      for (var existingScenario in existingScenarios) {
        if (!currentScenarioIds.contains(existingScenario.id)) {
          await _db.deleteStartScenario(existingScenario.id!);
          debugPrint('시작설정 삭제: ${existingScenario.id}');
        }
      }

      // 표지 이미지 삭제 처리
      final existingCoverImages = await _db.readCoverImages(characterId);
      final currentCoverImageIds = _coverImages
          .where((c) => c.id != null && c.id! > 0)
          .map((c) => c.id!)
          .toSet();
      for (var existingCover in existingCoverImages) {
        if (!currentCoverImageIds.contains(existingCover.id)) {
          await _db.deleteCoverImage(existingCover.id!);
          debugPrint('표지 이미지 삭제: ${existingCover.id}');
        }
      }

      // 추가 이미지 삭제 처리
      final existingAdditionalImages = await _db.readAdditionalImages(characterId);
      final currentAdditionalIds = _additionalImages
          .where((c) => c.id != null && c.id! > 0)
          .map((c) => c.id!)
          .toSet();
      for (var existing in existingAdditionalImages) {
        if (!currentAdditionalIds.contains(existing.id)) {
          await _db.deleteCoverImage(existing.id!);
          debugPrint('추가 이미지 삭제: ${existing.id}');
        }
      }

      // 배경 이미지 삭제 처리
      final existingBackgroundImages = await _db.readBackgroundImages(characterId);
      final currentBackgroundIds = _backgroundImages
          .where((c) => c.id != null && c.id! > 0)
          .map((c) => c.id!)
          .toSet();
      for (var existing in existingBackgroundImages) {
        if (!currentBackgroundIds.contains(existing.id)) {
          await _db.deleteCoverImage(existing.id!);
          debugPrint('배경 이미지 삭제: ${existing.id}');
        }
      }
    }

    // 로어북 폴더 및 로어북 저장
    for (var folder in _folders) {
      debugPrint('--- 폴더 처리 시작 ---');
      debugPrint('folder.id: ${folder.id}');
      debugPrint('folder.characterId: ${folder.characterId}');
      debugPrint('folder.name: ${folder.name}');

      int folderId;

      if (folder.id == null || folder.id! < 0) {
        debugPrint('분기: 새 폴더 생성 (id null or < 0)');
        // 새 폴더 생성
        folderId = await _db.createCharacterBookFolder(folder.copyWith(
          id: null,
          characterId: characterId,
        ));
        debugPrint('생성된 folderId: $folderId');
      } else if (!_isEditMode || folder.characterId != characterId) {
        debugPrint('분기: 새 캐릭터로 복사 (!_isEditMode || folder.characterId != characterId)');
        // 새 캐릭터로 복사하는 경우 새로 생성
        folderId = await _db.createCharacterBookFolder(folder.copyWith(
          id: null,
          characterId: characterId,
        ));
        debugPrint('생성된 folderId: $folderId');
      } else {
        debugPrint('분기: 기존 폴더 업데이트');
        // 기존 폴더 업데이트 (같은 캐릭터, 기존 ID)
        await _db.updateCharacterBookFolder(folder.copyWith(
          characterId: characterId,
        ));
        folderId = folder.id!;
        debugPrint('업데이트된 folderId: $folderId');
      }

      // 폴더 내 로어북 삭제 처리 (Edit 모드이고 기존 폴더인 경우)
      if (_isEditMode && folder.id != null && folder.id! > 0) {
        final existingCharacterBooks = await _db.readCharacterBooksByFolder(folderId);
        final currentLbIds = folder.characterBooks
            .where((lb) => lb.id != null && lb.id! > 0)
            .map((lb) => lb.id!)
            .toSet();
        for (var existingLb in existingCharacterBooks) {
          if (!currentLbIds.contains(existingLb.id)) {
            await _db.deleteCharacterBook(existingLb.id!);
            debugPrint('폴더 내 로어북 삭제: ${existingLb.id}');
          }
        }
      }

      // 폴더 내 로어북 저장
      for (var characterBook in folder.characterBooks) {
        int savedBookId;
        if (characterBook.id == null || characterBook.id! < 0) {
          savedBookId = await _db.createCharacterBook(characterBook.copyWith(
            id: null,
            characterId: characterId,
            folderId: folderId,
          ));
        } else if (!_isEditMode || characterBook.characterId != characterId) {
          // 새 캐릭터로 복사하는 경우 새로 생성
          savedBookId = await _db.createCharacterBook(characterBook.copyWith(
            id: null,
            characterId: characterId,
            folderId: folderId,
          ));
        } else {
          await _db.updateCharacterBook(characterBook.copyWith(
            characterId: characterId,
            folderId: folderId,
          ));
          savedBookId = characterBook.id!;
        }
        await _saveBookImages(characterBook, savedBookId, characterId);
      }
    }

    // 독립형 로어북 저장
    for (var characterBook in _standaloneCharacterBooks) {
      int savedBookId;
      if (characterBook.id == null || characterBook.id! < 0) {
        savedBookId = await _db.createCharacterBook(characterBook.copyWith(
          id: null,
          characterId: characterId,
          folderId: null,
        ));
      } else if (!_isEditMode || characterBook.characterId != characterId) {
        savedBookId = await _db.createCharacterBook(characterBook.copyWith(
          id: null,
          characterId: characterId,
          folderId: null,
        ));
      } else {
        await _db.updateCharacterBook(characterBook.copyWith(
          characterId: characterId,
        ));
        savedBookId = characterBook.id!;
      }
      await _saveBookImages(characterBook, savedBookId, characterId);
    }

    // 페르소나 저장
    for (var persona in _personas) {
      if (persona.id == null || persona.id! < 0) {
        await _db.createPersona(persona.copyWith(
          id: null,
          characterId: characterId,
        ));
      } else if (!_isEditMode || persona.characterId != characterId) {
        await _db.createPersona(persona.copyWith(
          id: null,
          characterId: characterId,
        ));
      } else {
        await _db.updatePersona(persona.copyWith(
          characterId: characterId,
        ));
      }
    }

    // 시작설정 저장
    for (var scenario in _startScenarios) {
      if (scenario.id == null || scenario.id! < 0) {
        await _db.createStartScenario(scenario.copyWith(
          id: null,
          characterId: characterId,
        ));
      } else if (!_isEditMode || scenario.characterId != characterId) {
        await _db.createStartScenario(scenario.copyWith(
          id: null,
          characterId: characterId,
        ));
      } else {
        await _db.updateStartScenario(scenario.copyWith(
          characterId: characterId,
        ));
      }
    }

    // 표지 이미지 저장
    for (var coverImage in _coverImages) {
      if (coverImage.id == null || coverImage.id! < 0) {
        await _db.createCoverImage(coverImage.copyWith(
          id: null,
          characterId: characterId,
          imageType: 'cover',
        ));
      } else if (!_isEditMode || coverImage.characterId != characterId) {
        await _db.createCoverImage(coverImage.copyWith(
          id: null,
          characterId: characterId,
          imageType: 'cover',
        ));
      } else {
        await _db.updateCoverImage(coverImage.copyWith(
          characterId: characterId,
        ));
      }
    }

    // 추가 이미지 저장
    for (var image in _additionalImages) {
      if (image.id == null || image.id! < 0) {
        await _db.createCoverImage(image.copyWith(
          id: null,
          characterId: characterId,
          imageType: 'additional',
        ));
      } else if (!_isEditMode || image.characterId != characterId) {
        await _db.createCoverImage(image.copyWith(
          id: null,
          characterId: characterId,
          imageType: 'additional',
        ));
      } else {
        await _db.updateCoverImage(image.copyWith(
          characterId: characterId,
        ));
      }
    }

    // 배경 이미지 저장
    for (var image in _backgroundImages) {
      if (image.id == null || image.id! < 0) {
        await _db.createCoverImage(image.copyWith(
          id: null,
          characterId: characterId,
          imageType: 'background',
        ));
      } else if (!_isEditMode || image.characterId != characterId) {
        await _db.createCoverImage(image.copyWith(
          id: null,
          characterId: characterId,
          imageType: 'background',
        ));
      } else {
        await _db.updateCoverImage(image.copyWith(
          characterId: characterId,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Stack(
      children: [
        Scaffold(
          appBar: CommonAppBar(
        title: _isEditMode ? l10n.characterEditTitleEdit : l10n.characterEditTitleNew,
        actions: [
          CommonAppBarIconButton(
            icon: Icons.check,
            onPressed: _handleSave,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(UIConstants.tabBarHeight),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            overlayColor: WidgetStateProperty.all(Colors.transparent),
            splashFactory: NoSplash.splashFactory,
            tabs: [
              Tab(text: l10n.characterEditTabProfile),
              Tab(text: l10n.characterEditTabCharacter),
              Tab(text: l10n.characterEditTabLorebook),
              Tab(text: l10n.characterEditTabPersona),
              Tab(text: l10n.characterEditTabStartSetting),
              Tab(text: l10n.characterEditTabCoverImage),
              Tab(text: l10n.characterEditTabBackgroundImage),
              Tab(text: l10n.characterEditTabAdditionalImage),
              const Tab(text: 'SNS'),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProfileTab(),
          _buildDetailSettingsTab(),
          CharacterBookTab(
            folders: _folders,
            standaloneCharacterBooks: _standaloneCharacterBooks,
            characterName: _nameController.text,
            onUpdate: () {
              setState(() {});
              _autoSave();
            },
          ),
          PersonaTab(
            personas: _personas,
            onUpdate: () {
              setState(() {});
              _autoSave();
            },
          ),
          StartScenarioTab(
            startScenarios: _startScenarios,
            onUpdate: () {
              setState(() {});
              _autoSave();
            },
          ),
          CoverImageTab(
            coverImages: _coverImages,
            selectedCoverImageId: _selectedCoverImageId,
            characterName: _nameController.text,
            onSelectedCoverImageChanged: (id) {
              setState(() => _selectedCoverImageId = id);
              _autoSave();
            },
            onUpdate: () {
              setState(() {});
              _autoSave();
            },
          ),
          BackgroundImageTab(
            images: _backgroundImages,
            characterName: _nameController.text,
            onUpdate: () {
              setState(() {});
              _autoSave();
            },
          ),
          AdditionalImageTab(
            images: _additionalImages,
            characterName: _nameController.text,
            onUpdate: () {
              setState(() {});
              _autoSave();
            },
          ),
          _buildOtherTab(),
        ],
      ),
        ),
        // 로딩 인디케이터
        if (_isLoading)
          Container(
            color: Colors.black54,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }

  Future<void> _pickWorldStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _worldStartDate ?? DateTime.now(),
      firstDate: DateTime(1),
      lastDate: DateTime(9999, 12, 31),
    );
    if (picked != null && mounted) {
      setState(() => _worldStartDate = picked);
      _autoSave();
    }
  }

  Widget _buildOtherTab() {
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CommonTitleMedium(
            text: l10n.characterEditWorldDateTitle,
            helpMessage: l10n.characterEditWorldDateHelp,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickWorldStartDate,
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(
                    _worldStartDate != null
                        ? '${_worldStartDate!.year}년 ${_worldStartDate!.month}월 ${_worldStartDate!.day}일'
                        : l10n.characterEditWorldDateHint,
                  ),
                  style: OutlinedButton.styleFrom(
                    alignment: Alignment.centerLeft,
                  ),
                ),
              ),
              if (_worldStartDate != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.clear),
                  tooltip: l10n.characterEditWorldDateClear,
                  onPressed: () {
                    setState(() => _worldStartDate = null);
                    _autoSave();
                  },
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),
          CommonTitleMedium(
            text: 'SNS',
            helpMessage: l10n.characterEditSnsHelp,
          ),
          const SizedBox(height: 16),
          CommonCustomTextField(
            controller: _communityNameController,
            label: l10n.characterEditSnsBoardNameLabel,
            hintText: l10n.characterEditSnsBoardHint,
          ),
          const SizedBox(height: 16),
          CommonCustomTextField(
            controller: _communityMoodController,
            label: l10n.characterEditSnsBoardMoodLabel,
            hintText: l10n.characterEditSnsToneHint,
            maxLines: null,
          ),
          const SizedBox(height: 16),
          CommonCustomTextField(
            controller: _communityLanguageController,
            label: l10n.characterEditSnsBoardLanguageLabel,
            hintText: l10n.characterEditSnsLanguageHint,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    final l10n = AppLocalizations.of(context);
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(UIConstants.spacing20),
        children: [
          CommonCustomTextField(
            controller: _nameController,
            label: l10n.characterEditNameLabel,
            helpText: l10n.characterEditNameHelpText,
            hintText: l10n.characterEditNameHintText,
            maxLines: null,
            showCounter: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return l10n.characterEditNameRequired;
              }
              return null;
            },
          ),
          const SizedBox(height: UIConstants.spacing20),
          CommonCustomTextField(
            controller: _nicknameController,
            label: l10n.characterEditNicknameLabel,
            helpText: l10n.characterEditNicknameHelp,
            hintText: l10n.characterEditNicknameHint,
            maxLines: null,
            showCounter: true,
          ),
          const SizedBox(height: UIConstants.spacing20),
          CommonCustomTextField(
            controller: _creatorNotesController,
            label: l10n.characterEditTaglineLabel,
            helpText: l10n.characterEditTaglineHelp,
            hintText: l10n.characterEditTaglineHint,
            maxLines: null,
            showCounter: true,
          ),
          const SizedBox(height: UIConstants.spacing20),
          CommonCustomTextField(
            controller: _keywordsController,
            label: l10n.characterEditKeywordsLabel,
            helpText: l10n.characterEditKeywordsHelp,
            hintText: l10n.characterEditKeywordsHint,
            maxLines: null,
            showCounter: true,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSettingsTab() {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(UIConstants.spacing20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CommonTitleMedium(text: l10n.characterEditWorldSetting),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        content: Text(l10n.characterEditWorldSettingHelp),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(l10n.commonConfirm),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Icon(
                    Icons.help_outline,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _descriptionController,
                  builder: (context, value, child) {
                    final tokenizer = context.watch<TokenizerProvider>().selectedTokenizer;
                    final tokenCount = TokenCounter.estimateTokenCount(value.text, tokenizer: tokenizer);
                    return Text(
                      '$tokenCount token',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: CommonEditText(
              controller: _descriptionController,
              hintText: l10n.characterEditWorldSettingHint,
              size: CommonEditTextSize.medium,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
            ),
          ),
        ],
      ),
    );
  }

}
