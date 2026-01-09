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
  final _summaryController = TextEditingController();
  final _keywordsController = TextEditingController();
  final _worldSettingController = TextEditingController();

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
  bool _saveCompleted = false; // 저장 완료 플래그

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
    _summaryController.addListener(_autoSave);
    _keywordsController.addListener(_autoSave);
    _worldSettingController.addListener(_autoSave);
  }

  Future<void> _loadCharacterData() async {
    if (widget.characterId == null) return;

    setState(() => _isLoading = true);

    try {
      // 캐릭터 기본 정보 로드
      final character = await _db.readCharacter(widget.characterId!);
      if (character != null) {
        _nameController.text = character.name;
        _summaryController.text = character.summary ?? '';
        _keywordsController.text = character.keywords ?? '';
        _worldSettingController.text = character.worldSetting ?? '';
        _selectedCoverImageId = character.selectedCoverImageId;
      }

      // 로어북 폴더 및 로어북 로드
      final folders = await _db.readLorebookFolders(widget.characterId!);
      for (var folder in folders) {
        final lorebooks = await _db.readLorebooksByFolder(folder.id!);
        folder.lorebooks.addAll(lorebooks);
      }
      _folders.addAll(folders);

      // 독립형 로어북 로드
      final standaloneLorebooks = await _db.readStandaloneLorebooks(widget.characterId!);
      _standaloneLorebooks.addAll(standaloneLorebooks);

      // 페르소나 로드
      final personas = await _db.readPersonas(widget.characterId!);
      _personas.addAll(personas);

      // 시작설정 로드
      final scenarios = await _db.readStartScenarios(widget.characterId!);
      _startScenarios.addAll(scenarios);

      // 표지 이미지 로드
      final coverImages = await _db.readCoverImages(widget.characterId!);
      _coverImages.addAll(coverImages);

      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('데이터 로드 실패: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _summaryController.dispose();
    _keywordsController.dispose();
    _worldSettingController.dispose();
    super.dispose();
  }

  @override
  void setState(VoidCallback fn) {
    super.setState(fn);
    // 저장 중이거나 저장 완료되었으면 자동 저장하지 않음
    if (!_isSaving && !_saveCompleted) {
      Future.microtask(() => _autoSave());
    }
  }

  String _getAutoSaveKey() {
    // 편집 모드면 characterId 기반, 생성 모드면 'new' 키 사용
    return _isEditMode ? 'autosave_character_${widget.characterId}' : 'autosave_character_new';
  }

  Future<void> _autoSave() async {
    // 저장 중이거나 이름이 비어있으면 자동 저장하지 않음
    if (_isSaving || _nameController.text.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'name': _nameController.text,
        'summary': _summaryController.text,
        'keywords': _keywordsController.text,
        'worldSetting': _worldSettingController.text,
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

      final shouldRestore = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('작성 중인 데이터 발견'),
          content: Text(
            '저장되지 않은 작성 중인 데이터가 있습니다.\n'
            '마지막 작성 시간: ${_formatTimestamp(timestamp)}\n\n'
            '불러오시겠습니까?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('불러오기'),
            ),
          ],
        ),
      );

      if (shouldRestore == true && mounted) {
        setState(() {
          _nameController.text = data['name'] as String? ?? '';
          _summaryController.text = data['summary'] as String? ?? '';
          _keywordsController.text = data['keywords'] as String? ?? '';
          _worldSettingController.text = data['worldSetting'] as String? ?? '';
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('캐릭터 이름을 입력해주세요')),
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
        final character = Character(
          id: characterId,
          name: _nameController.text,
          summary: _summaryController.text.isEmpty ? null : _summaryController.text,
          keywords: _keywordsController.text.isEmpty ? null : _keywordsController.text,
          worldSetting: _worldSettingController.text.isEmpty ? null : _worldSettingController.text,
          selectedCoverImageId: _selectedCoverImageId,
          updatedAt: DateTime.now(),
          isDraft: false,
        );
        await _db.updateCharacter(character);
      } else {
        // 새 캐릭터 생성
        final character = Character(
          name: _nameController.text,
          summary: _summaryController.text.isEmpty ? null : _summaryController.text,
          keywords: _keywordsController.text.isEmpty ? null : _keywordsController.text,
          worldSetting: _worldSettingController.text.isEmpty ? null : _worldSettingController.text,
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
        // 저장 완료 플래그 설정하여 이후 자동 저장 방지
        setState(() {
          _isLoading = false;
          _isSaving = false;
          _saveCompleted = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditMode ? '캐릭터가 수정되었습니다' : '캐릭터가 생성되었습니다',
            ),
          ),
        );
        Navigator.pop(context, true); // true를 반환하여 목록 새로고침 유도
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: $e')),
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
            onUpdate: () => setState(() {}),
          ),
          PersonaTab(
            personas: _personas,
            onUpdate: () => setState(() {}),
          ),
          StartScenarioTab(
            startScenarios: _startScenarios,
            onUpdate: () => setState(() {}),
          ),
          CoverImageTab(
            coverImages: _coverImages,
            selectedCoverImageId: _selectedCoverImageId,
            onSelectedCoverImageChanged: (id) => setState(() => _selectedCoverImageId = id),
            onUpdate: () => setState(() {}),
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
            controller: _summaryController,
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
                  valueListenable: _worldSettingController,
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
              controller: _worldSettingController,
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
