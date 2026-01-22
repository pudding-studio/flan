import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../constants/ui_constants.dart';
import '../../database/database_helper.dart';
import '../../models/character/character.dart';
import '../../models/character/cover_image.dart';
import '../../models/character/lorebook_folder.dart';
import '../../models/character/persona.dart';
import '../../models/character/start_scenario.dart';
import '../../utils/common_dialog.dart';
import '../../widgets/custom_text_field.dart';
import 'tabs/cover_image_tab.dart';
import 'tabs/lorebook_tab.dart';
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
  final _creatorNotesController = TextEditingController();
  final _keywordsController = TextEditingController();
  final _descriptionController = TextEditingController();

  // 로어북 관련 상태
  final List<LorebookFolder> _folders = [];
  final List<Lorebook> _standaloneLorebooks = [];

  // 페르소나 관련 상태
  final List<Persona> _personas = [];

  // 시작설정 관련 상태
  final List<StartScenario> _startScenarios = [];

  // 표지 관련 상태
  final List<CoverImage> _coverImages = [];
  int? _selectedCoverImageId;

  // 데이터베이스
  final DatabaseHelper _db = DatabaseHelper.instance;
  bool _isLoading = false;
  bool _isSaving = false; // 저장 중에는 자동 저장 비활성화

  // 원본 데이터 저장 (변경 감지용)
  String _originalName = '';
  String _originalCreatorNotes = '';
  String _originalKeywords = '';
  String _originalDescription = '';
  int? _originalSelectedCoverImageId;
  List<LorebookFolder> _originalFolders = [];
  List<Lorebook> _originalStandaloneLorebooks = [];
  List<Persona> _originalPersonas = [];
  List<StartScenario> _originalStartScenarios = [];
  List<CoverImage> _originalCoverImages = [];

  bool get _isEditMode => widget.characterId != null;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);

    // 자동 저장 데이터 확인 및 복원
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _checkAndRestoreAutoSave();
    });

    if (_isEditMode) {
      _loadCharacterData();
    }

    // 텍스트 컨트롤러에 리스너 추가하여 자동 저장
    _nameController.addListener(_autoSave);
    _creatorNotesController.addListener(_autoSave);
    _keywordsController.addListener(_autoSave);
    _descriptionController.addListener(_autoSave);
  }

  Future<void> _loadCharacterData() async {
    if (widget.characterId == null) return;

    setState(() => _isLoading = true);

    try {
      // 캐릭터 기본 정보 로드
      final character = await _db.readCharacter(widget.characterId!);
      if (character != null) {
        _nameController.text = character.name;
        _creatorNotesController.text = character.creatorNotes ?? '';
        _keywordsController.text = character.tags.join(', ');
        _descriptionController.text = character.description ?? '';
        _selectedCoverImageId = character.selectedCoverImageId;

        // 원본 데이터 저장
        _originalName = character.name;
        _originalCreatorNotes = character.creatorNotes ?? '';
        _originalKeywords = character.tags.join(', ');
        _originalDescription = character.description ?? '';
        _originalSelectedCoverImageId = character.selectedCoverImageId;
      }

      // 로어북 폴더 및 로어북 로드
      final folders = await _db.readLorebookFolders(widget.characterId!);
      for (var folder in folders) {
        final lorebooks = await _db.readLorebooksByFolder(folder.id!);
        folder.lorebooks.addAll(lorebooks);
      }
      _folders.addAll(folders);
      _originalFolders = _folders.map((f) => _copyFolder(f)).toList();

      // 독립형 로어북 로드
      final standaloneLorebooks = await _db.readStandaloneLorebooks(widget.characterId!);
      _standaloneLorebooks.addAll(standaloneLorebooks);
      _originalStandaloneLorebooks = standaloneLorebooks.map((lb) => _copyLorebook(lb)).toList();

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

      setState(() {});
    } catch (e) {
      if (mounted) {
        CommonDialog.showSnackBar(
          context: context,
          message: '데이터 로드 실패: $e',
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 데이터 복사 헬퍼 메서드들
  LorebookFolder _copyFolder(LorebookFolder folder) {
    final copied = LorebookFolder(
      id: folder.id,
      characterId: folder.characterId,
      name: folder.name,
      order: folder.order,
      isExpanded: folder.isExpanded,
    );
    copied.lorebooks.addAll(folder.lorebooks.map((lb) => _copyLorebook(lb)));
    return copied;
  }

  Lorebook _copyLorebook(Lorebook lorebook) {
    return Lorebook(
      id: lorebook.id,
      characterId: lorebook.characterId,
      folderId: lorebook.folderId,
      name: lorebook.name,
      order: lorebook.order,
      isExpanded: lorebook.isExpanded,
      activationCondition: lorebook.activationCondition,
      keys: List<String>.from(lorebook.keys),
      keyCondition: lorebook.keyCondition,
      deploymentOrder: lorebook.deploymentOrder,
      content: lorebook.content,
    );
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
    );
  }

  // 데이터 변경 감지
  bool _hasChanges() {
    // 기본 정보 변경 확인
    if (_nameController.text != _originalName ||
        _creatorNotesController.text != _originalCreatorNotes ||
        _keywordsController.text != _originalKeywords ||
        _descriptionController.text != _originalDescription ||
        _selectedCoverImageId != _originalSelectedCoverImageId) {
      return true;
    }

    // 로어북 폴더 변경 확인
    if (_folders.length != _originalFolders.length) return true;
    for (int i = 0; i < _folders.length; i++) {
      if (_folders[i].name != _originalFolders[i].name ||
          _folders[i].isExpanded != _originalFolders[i].isExpanded ||
          _folders[i].lorebooks.length != _originalFolders[i].lorebooks.length) {
        return true;
      }
      for (int j = 0; j < _folders[i].lorebooks.length; j++) {
        final current = _folders[i].lorebooks[j];
        final original = _originalFolders[i].lorebooks[j];
        if (current.name != original.name ||
            current.content != original.content ||
            current.activationCondition != original.activationCondition ||
            current.keys.join(',') != original.keys.join(',')) {
          return true;
        }
      }
    }

    // 독립형 로어북 변경 확인
    if (_standaloneLorebooks.length != _originalStandaloneLorebooks.length) return true;
    for (int i = 0; i < _standaloneLorebooks.length; i++) {
      final current = _standaloneLorebooks[i];
      final original = _originalStandaloneLorebooks[i];
      if (current.name != original.name ||
          current.content != original.content ||
          current.activationCondition != original.activationCondition ||
          current.keys.join(',') != original.keys.join(',')) {
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

    // 표지 이미지 변경 확인 (name과 imageData 비교)
    if (_coverImages.length != _originalCoverImages.length) return true;
    for (int i = 0; i < _coverImages.length; i++) {
      if (_coverImages[i].name != _originalCoverImages[i].name ||
          _coverImages[i].imageData != _originalCoverImages[i].imageData) {
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
        _standaloneLorebooks.isNotEmpty ||
        _personas.isNotEmpty ||
        _startScenarios.isNotEmpty ||
        _coverImages.isNotEmpty) {
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
    _creatorNotesController.dispose();
    _keywordsController.dispose();
    _descriptionController.dispose();
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
        'creatorNotes': _creatorNotesController.text,
        'keywords': _keywordsController.text,
        'description': _descriptionController.text,
        'selectedCoverImageId': _selectedCoverImageId,
        'folders': _folders.map((f) {
          final folderMap = f.toMap();
          folderMap['lorebooks'] = f.lorebooks.map((lb) => lb.toMap()).toList();
          return folderMap;
        }).toList(),
        'standaloneLorebooks': _standaloneLorebooks.map((lb) => lb.toMap()).toList(),
        'personas': _personas.map((p) => p.toMap()).toList(),
        'startScenarios': _startScenarios.map((s) => s.toMap()).toList(),
        'coverImages': _coverImages.map((c) => c.toMap()).toList(),
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

      final shouldRestore = await CommonDialog.showConfirmation(
        context: context,
        title: '작성 중인 데이터 발견',
        content: '저장되지 않은 작성 중인 데이터가 있습니다.\n'
            '마지막 작성 시간: ${_formatTimestamp(timestamp)}\n\n'
            '불러오시겠습니까?',
        confirmText: '불러오기',
        cancelText: '취소',
      );

      if (shouldRestore == true && mounted) {
        setState(() {
          _nameController.text = data['name'] as String? ?? '';
          _creatorNotesController.text = data['creatorNotes'] as String? ?? '';
          _keywordsController.text = data['keywords'] as String? ?? '';
          _descriptionController.text = data['description'] as String? ?? '';
          _selectedCoverImageId = data['selectedCoverImageId'] as int?;

          // 로어북 폴더 복원
          _folders.clear();
          if (data['folders'] != null) {
            for (var folderMap in data['folders'] as List) {
              final folder = LorebookFolder.fromMap(folderMap as Map<String, dynamic>);
              if (folderMap['lorebooks'] != null) {
                for (var lbMap in folderMap['lorebooks'] as List) {
                  folder.lorebooks.add(Lorebook.fromMap(lbMap as Map<String, dynamic>));
                }
              }
              _folders.add(folder);
            }
          }

          // 독립형 로어북 복원
          _standaloneLorebooks.clear();
          if (data['standaloneLorebooks'] != null) {
            for (var lbMap in data['standaloneLorebooks'] as List) {
              _standaloneLorebooks.add(Lorebook.fromMap(lbMap as Map<String, dynamic>));
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
        });

        // 복원한 데이터를 원본으로 설정 (편집 모드인 경우)
        if (_isEditMode) {
          _originalName = _nameController.text;
          _originalCreatorNotes = _creatorNotesController.text;
          _originalKeywords = _keywordsController.text;
          _originalDescription = _descriptionController.text;
          _originalSelectedCoverImageId = _selectedCoverImageId;
          _originalFolders = _folders.map((f) => _copyFolder(f)).toList();
          _originalStandaloneLorebooks = _standaloneLorebooks.map((lb) => _copyLorebook(lb)).toList();
          _originalPersonas = _personas.map((p) => _copyPersona(p)).toList();
          _originalStartScenarios = _startScenarios.map((s) => _copyStartScenario(s)).toList();
          _originalCoverImages = _coverImages.map((c) => _copyCoverImage(c)).toList();
        }
      } else if (shouldRestore == false) {
        // 사용자가 취소를 선택하면 자동 저장 데이터 삭제
        await prefs.remove(_getAutoSaveKey());
      }
    } catch (e) {
      debugPrint('자동 저장 데이터 복원 실패: $e');
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) {
      return '방금 전';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}분 전';
    } else if (diff.inDays < 1) {
      return '${diff.inHours}시간 전';
    } else {
      return '${diff.inDays}일 전';
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
    // 이름만 필수로 체크
    if (_nameController.text.isEmpty) {
      CommonDialog.showSnackBar(
        context: context,
        message: '캐릭터 이름을 입력해주세요',
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
          creatorNotes: _creatorNotesController.text.isEmpty ? null : _creatorNotesController.text,
          tags: tags,
          description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
          selectedCoverImageId: _selectedCoverImageId,
          updatedAt: DateTime.now(),
          isDraft: false,
        );
        await _db.updateCharacter(character);
      } else {
        // 새 캐릭터 생성
        final tags = _keywordsController.text.isEmpty
            ? <String>[]
            : _keywordsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

        final character = Character(
          name: _nameController.text,
          creatorNotes: _creatorNotesController.text.isEmpty ? null : _creatorNotesController.text,
          tags: tags,
          description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
          selectedCoverImageId: _selectedCoverImageId,
          isDraft: false,
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

        CommonDialog.showSnackBar(
          context: context,
          message: _isEditMode ? '캐릭터가 수정되었습니다' : '캐릭터가 생성되었습니다',
        );
        Navigator.pop(context, true); // true를 반환하여 목록 새로고침 유도
      }
    } catch (e) {
      if (mounted) {
        CommonDialog.showSnackBar(
          context: context,
          message: '저장 실패: $e',
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
      final existingFolders = await _db.readLorebookFolders(characterId);
      final currentFolderIds = _folders
          .where((f) => f.id != null && f.id! > 0)
          .map((f) => f.id!)
          .toSet();
      for (var existingFolder in existingFolders) {
        if (!currentFolderIds.contains(existingFolder.id)) {
          await _db.deleteLorebookFolder(existingFolder.id!);
          debugPrint('폴더 삭제: ${existingFolder.id}');
        }
      }

      // 독립형 로어북 삭제 처리
      final existingStandaloneLorebooks = await _db.readStandaloneLorebooks(characterId);
      final currentStandaloneLbIds = _standaloneLorebooks
          .where((lb) => lb.id != null && lb.id! > 0)
          .map((lb) => lb.id!)
          .toSet();
      for (var existingLb in existingStandaloneLorebooks) {
        if (!currentStandaloneLbIds.contains(existingLb.id)) {
          await _db.deleteLorebook(existingLb.id!);
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
        folderId = await _db.createLorebookFolder(folder.copyWith(
          id: null,
          characterId: characterId,
        ));
        debugPrint('생성된 folderId: $folderId');
      } else if (!_isEditMode || folder.characterId != characterId) {
        debugPrint('분기: 새 캐릭터로 복사 (!_isEditMode || folder.characterId != characterId)');
        // 새 캐릭터로 복사하는 경우 새로 생성
        folderId = await _db.createLorebookFolder(folder.copyWith(
          id: null,
          characterId: characterId,
        ));
        debugPrint('생성된 folderId: $folderId');
      } else {
        debugPrint('분기: 기존 폴더 업데이트');
        // 기존 폴더 업데이트 (같은 캐릭터, 기존 ID)
        await _db.updateLorebookFolder(folder.copyWith(
          characterId: characterId,
        ));
        folderId = folder.id!;
        debugPrint('업데이트된 folderId: $folderId');
      }

      // 폴더 내 로어북 삭제 처리 (Edit 모드이고 기존 폴더인 경우)
      if (_isEditMode && folder.id != null && folder.id! > 0) {
        final existingLorebooks = await _db.readLorebooksByFolder(folderId);
        final currentLbIds = folder.lorebooks
            .where((lb) => lb.id != null && lb.id! > 0)
            .map((lb) => lb.id!)
            .toSet();
        for (var existingLb in existingLorebooks) {
          if (!currentLbIds.contains(existingLb.id)) {
            await _db.deleteLorebook(existingLb.id!);
            debugPrint('폴더 내 로어북 삭제: ${existingLb.id}');
          }
        }
      }

      // 폴더 내 로어북 저장
      for (var lorebook in folder.lorebooks) {
        if (lorebook.id == null || lorebook.id! < 0) {
          await _db.createLorebook(lorebook.copyWith(
            id: null,
            characterId: characterId,
            folderId: folderId,
          ));
        } else if (!_isEditMode || lorebook.characterId != characterId) {
          // 새 캐릭터로 복사하는 경우 새로 생성
          await _db.createLorebook(lorebook.copyWith(
            id: null,
            characterId: characterId,
            folderId: folderId,
          ));
        } else {
          await _db.updateLorebook(lorebook.copyWith(
            characterId: characterId,
            folderId: folderId,
          ));
        }
      }
    }

    // 독립형 로어북 저장
    for (var lorebook in _standaloneLorebooks) {
      if (lorebook.id == null || lorebook.id! < 0) {
        await _db.createLorebook(lorebook.copyWith(
          id: null,
          characterId: characterId,
          folderId: null,
        ));
      } else if (!_isEditMode || lorebook.characterId != characterId) {
        await _db.createLorebook(lorebook.copyWith(
          id: null,
          characterId: characterId,
          folderId: null,
        ));
      } else {
        await _db.updateLorebook(lorebook.copyWith(
          characterId: characterId,
        ));
      }
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
        ));
      } else if (!_isEditMode || coverImage.characterId != characterId) {
        await _db.createCoverImage(coverImage.copyWith(
          id: null,
          characterId: characterId,
        ));
      } else {
        await _db.updateCoverImage(coverImage.copyWith(
          characterId: characterId,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.only(left: 16),
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(),
            ),

            const SizedBox(width: 4),
            Expanded(
              child: Text(
                _isEditMode ? '캐릭터 수정' : '캐릭터 만들기',
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(
              onPressed: _handleSave,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                '저장',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(UIConstants.tabBarHeight),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            overlayColor: WidgetStateProperty.all(Colors.transparent),
            splashFactory: NoSplash.splashFactory,
            tabs: const [
              Tab(
                child: SizedBox(
                  width: UIConstants.tabWidth,
                  child: Center(child: Text('프로필')),
                ),
              ),
              Tab(
                child: SizedBox(
                  width: UIConstants.tabWidth,
                  child: Center(child: Text('캐릭터설정')),
                ),
              ),
              Tab(
                child: SizedBox(
                  width: UIConstants.tabWidth,
                  child: Center(child: Text('로어북')),
                ),
              ),
              Tab(
                child: SizedBox(
                  width: UIConstants.tabWidth,
                  child: Center(child: Text('페르소나')),
                ),
              ),
              Tab(
                child: SizedBox(
                  width: UIConstants.tabWidth,
                  child: Center(child: Text('시작설정')),
                ),
              ),
              Tab(
                child: SizedBox(
                  width: UIConstants.tabWidth,
                  child: Center(child: Text('표지')),
                ),
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProfileTab(),
          _buildDetailSettingsTab(),
          LorebookTab(
            folders: _folders,
            standaloneLorebooks: _standaloneLorebooks,
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
            onSelectedCoverImageChanged: (id) {
              setState(() => _selectedCoverImageId = id);
              _autoSave();
            },
            onUpdate: () {
              setState(() {});
              _autoSave();
            },
          ),
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

  Widget _buildProfileTab() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(UIConstants.spacing20),
        children: [
          CustomTextField(
            controller: _nameController,
            label: '이름',
            helpText: '캐릭터의 고유한 이름을 입력해주세요.',
            hintText: '캐릭터의 이름을 입력해주세요.',
            maxLines: null,
            showCounter: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '캐릭터 이름을 입력해주세요';
              }
              return null;
            },
          ),
          const SizedBox(height: UIConstants.spacing20),
          CustomTextField(
            controller: _creatorNotesController,
            label: '한 줄 소개',
            helpText: '캐릭터를 간단히 설명하는 한 문장을 작성해주세요.',
            hintText: '어떤 캐릭터인지 설명할 수 있는 간단한 소개를 입력해주세요.',
            maxLines: null,
            showCounter: true,
          ),
          const SizedBox(height: UIConstants.spacing20),
          CustomTextField(
            controller: _keywordsController,
            label: '키워드',
            helpText: '캐릭터를 나타내는 키워드를 쉼표(,)로 구분하여 입력해주세요.',
            hintText: '키워드 입력 예시: 판타지, 남자',
            maxLines: null,
            showCounter: true,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSettingsTab() {
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
                Text(
                  '세계관 설정',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        content: const Text('캐릭터가 속한 세계관이나 배경 설정을 자유롭게 작성해주세요.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('확인'),
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
                    return Text(
                      '${value.text.length}',
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
            child: TextFormField(
              controller: _descriptionController,
              style: Theme.of(context).textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: '세계관 설정을 입력해주세요.',
                hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                counterText: '',
                isDense: true,
              ),
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
            ),
          ),
        ],
      ),
    );
  }

}
