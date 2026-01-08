import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../widgets/custom_text_field.dart';
import '../../constants/ui_constants.dart';
import '../../models/character/character.dart';
import '../../models/character/lorebook_folder.dart';
import '../../models/character/persona.dart';
import '../../models/character/start_scenario.dart';
import '../../models/character/cover_image.dart';
import '../../database/database_helper.dart';

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
  // 로어북 아코디언 패딩 상수
  static const double _lorebookItemHorizontalPadding = 10.0;
  static const double _lorebookItemVerticalPadding = 10.0;
  static const double _segmentedButtonBorderRadius = 8.0;

  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _summaryController = TextEditingController();
  final _keywordsController = TextEditingController();
  final _worldSettingController = TextEditingController();

  // 임시 character ID (아직 DB에 저장되지 않은 경우)
  int _tempCharacterId = -1;

  // 임시 ID 생성기 (음수 사용)
  int _nextTempId = -1;
  int _getNextTempId() => _nextTempId--;

  // 로어북 관련 상태
  final List<LorebookFolder> _folders = [];
  final List<Lorebook> _standaloneLorebooks = [];

  // 페르소나 관련 상태
  final List<Persona> _personas = [];

  // 시작설정 관련 상태
  final List<StartScenario> _startScenarios = [];

  // 표지 관련 상태
  final List<CoverImage> _coverImages = [];
  final ImagePicker _imagePicker = ImagePicker();
  int? _selectedCoverImageId;

  // 편집 중인 항목 추적
  int? _editingFolderId;
  int? _editingLorebookId;
  int? _editingPersonaId;
  int? _editingStartScenarioId;
  int? _editingCoverImageId;
  final Map<int, TextEditingController> _editControllers = {};

  // 데이터베이스
  final DatabaseHelper _db = DatabaseHelper.instance;
  bool _isLoading = false;

  bool get _isEditMode => widget.characterId != null;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    if (_isEditMode) {
      _loadCharacterData();
    }
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
    for (var controller in _editControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _handleSaveDraft() async {
    await _saveCharacter(isDraft: true);
  }

  Future<void> _handleComplete() async {
    if (_formKey.currentState?.validate() ?? false) {
      await _saveCharacter(isDraft: false);
    }
  }

  Future<void> _saveCharacter({required bool isDraft}) async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('캐릭터 이름을 입력해주세요')),
      );
      return;
    }

    setState(() => _isLoading = true);

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
          isDraft: isDraft,
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
          isDraft: isDraft,
        );
        characterId = await _db.createCharacter(character);
      }

      // 하위 데이터 저장
      await _saveSubData(characterId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isDraft
                  ? '임시저장되었습니다'
                  : (_isEditMode ? '캐릭터가 수정되었습니다' : '캐릭터가 생성되었습니다'),
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
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSubData(int characterId) async {
    // 기존 하위 데이터 삭제 (단순화를 위해 - 실제로는 업데이트 로직 필요)
    if (_isEditMode) {
      // TODO: 개별 업데이트/삭제 로직으로 개선 필요
    }

    // 로어북 폴더 및 로어북 저장
    for (var folder in _folders) {
      final folderId = folder.id != null && folder.id! < 0
          ? await _db.createLorebookFolder(folder.copyWith(
              id: null, // null로 설정하면 DB가 새 ID 생성
              characterId: characterId,
            ))
          : folder.id;

      if (folderId != null) {
        for (var lorebook in folder.lorebooks) {
          if (lorebook.id == null || lorebook.id! < 0) {
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
    }

    // 독립형 로어북 저장
    for (var lorebook in _standaloneLorebooks) {
      if (lorebook.id == null || lorebook.id! < 0) {
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
            IconButton(
              icon: const Icon(Icons.drafts_outlined),
              onPressed: _handleSaveDraft,
              tooltip: '임시저장',
              padding: EdgeInsets.only(left: 0),
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 4),
            TextButton(
              onPressed: _handleComplete,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                '완료',
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
          _buildLorebookTab(),
          _buildPersonaTab(),
          _buildStartScenarioTab(),
          _buildCoverTab(),
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

  Widget _buildLorebookTab() {
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
                  '로어북',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        content: const Text('캐릭터의 세계관과 관련된 정보를 로어북에 추가할 수 있습니다.'),
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
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _folders.isEmpty && _standaloneLorebooks.isEmpty
                ? const Center(
                    child: Text('로어북 항목이 없습니다'),
                  )
                : DragTarget<Map<String, dynamic>>(
                    onWillAcceptWithDetails: (details) {
                      final data = details.data;
                      return data['type'] == 'lorebook' && data['fromFolder'] != null;
                    },
                    onAcceptWithDetails: (details) {
                      final data = details.data;
                      final lorebook = data['lorebook'] as Lorebook;
                      final fromFolder = data['fromFolder'] as LorebookFolder?;
                      if (fromFolder != null) {
                        _moveLorebookOutOfFolder(lorebook, fromFolder);
                      }
                    },
                    builder: (context, candidateData, rejectedData) {
                      return Container(
                        decoration: candidateData.isNotEmpty
                            ? BoxDecoration(
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              )
                            : null,
                        child: ListView.builder(
                          itemCount: _folders.length + _standaloneLorebooks.length,
                          itemBuilder: (context, index) {
                            if (index < _folders.length) {
                              return _buildFolderItem(_folders[index]);
                            } else {
                              return _buildLorebookItem(
                                _standaloneLorebooks[index - _folders.length],
                                null,
                              );
                            }
                          },
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _addFolder,
                  icon: const Icon(Icons.folder_outlined),
                  label: const Text('폴더 추가'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _addLorebook(null),
                  icon: const Icon(Icons.add),
                  label: const Text('로어북 추가'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _moveLorebookToFolder(Lorebook lorebook, LorebookFolder? fromFolder, LorebookFolder toFolder) {
    setState(() {
      if (fromFolder != null) {
        fromFolder.lorebooks.remove(lorebook);
      } else {
        _standaloneLorebooks.remove(lorebook);
      }
      toFolder.lorebooks.add(lorebook);
      lorebook.order = toFolder.lorebooks.length - 1;
    });
  }

  void _moveLorebookOutOfFolder(Lorebook lorebook, LorebookFolder fromFolder) {
    setState(() {
      fromFolder.lorebooks.remove(lorebook);
      _standaloneLorebooks.add(lorebook);
      lorebook.order = _standaloneLorebooks.length - 1;
    });
  }

  void _addFolder() {
    setState(() {
      final newFolder = LorebookFolder(
        id: _getNextTempId(),
        characterId: widget.characterId ?? _tempCharacterId,
        name: '새 폴더',
        order: _folders.length,
      );
      _folders.add(newFolder);
    });
  }

  void _addLorebook(LorebookFolder? folder) {
    setState(() {
      final newLorebook = Lorebook(
        id: _getNextTempId(),
        characterId: widget.characterId ?? _tempCharacterId,
        folderId: folder?.id,
        name: '새 로어북',
        order: folder != null ? folder.lorebooks.length : _standaloneLorebooks.length,
        isExpanded: true,
      );

      if (folder != null) {
        folder.lorebooks.add(newLorebook);
      } else {
        _standaloneLorebooks.add(newLorebook);
      }
    });
  }

  void _deleteFolder(LorebookFolder folder) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('폴더 삭제'),
        content: Text('${folder.name} 폴더를 삭제하시겠습니까?\n폴더 내 모든 로어북도 함께 삭제됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _folders.remove(folder);
              });
              Navigator.pop(context);
            },
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  void _deleteLorebook(Lorebook lorebook, LorebookFolder? folder) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로어북 삭제'),
        content: Text('${lorebook.name}을(를) 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                if (folder != null) {
                  folder.lorebooks.remove(lorebook);
                } else {
                  _standaloneLorebooks.remove(lorebook);
                }
              });
              Navigator.pop(context);
            },
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  Widget _buildFolderItem(LorebookFolder folder) {
    return DragTarget<Map<String, dynamic>>(
      onWillAcceptWithDetails: (details) {
        final data = details.data;
        return data['type'] == 'lorebook' && data['fromFolder'] != folder;
      },
      onAcceptWithDetails: (details) {
        final data = details.data;
        final lorebook = data['lorebook'] as Lorebook;
        final fromFolder = data['fromFolder'] as LorebookFolder?;
        _moveLorebookToFolder(lorebook, fromFolder, folder);
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          key: ValueKey(folder.id),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: candidateData.isNotEmpty
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
              width: candidateData.isNotEmpty ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              InkWell(
                onTap: () {
                  setState(() {
                    folder.isExpanded = !folder.isExpanded;
                  });
                },
                overlayColor: WidgetStateProperty.all(Colors.transparent),
                borderRadius: BorderRadius.circular(10),    
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: _lorebookItemHorizontalPadding,
                    vertical: _lorebookItemVerticalPadding,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.folder_outlined,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _editingFolderId == folder.id
                            ? TextField(
                                controller: _editControllers[folder.id!],
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                autofocus: true,
                                onSubmitted: (value) => _saveFolderName(folder, value),
                              )
                            : Text(
                                folder.name,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                      ),
                      GestureDetector(
                        onTap: () => _toggleFolderEdit(folder),
                        child: Icon(
                          _editingFolderId == folder.id ? Icons.check : Icons.edit_outlined,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => _deleteFolder(folder),
                        child: const Icon(Icons.delete_outline, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        folder.isExpanded ? Icons.expand_less : Icons.expand_more,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              if (folder.isExpanded) ...[
                const Divider(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(
                    children: folder.lorebooks.map((lorebook) => _buildLorebookItem(lorebook, folder)).toList(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _addLorebook(folder),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('로어북 추가', style: TextStyle(fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        overlayColor: Colors.transparent,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _toggleFolderEdit(LorebookFolder folder) {
    setState(() {
      if (_editingFolderId == folder.id) {
        // 편집 완료
        final controller = _editControllers[folder.id!];
        if (controller != null && controller.text.isNotEmpty) {
          folder.name = controller.text;
        }
        _editingFolderId = null;
        _editControllers.remove(folder.id!)?.dispose();
      } else {
        // 편집 시작
        _editingFolderId = folder.id;
        _editControllers[folder.id!] = TextEditingController(text: folder.name);
      }
    });
  }

  void _saveFolderName(LorebookFolder folder, String value) {
    setState(() {
      if (value.isNotEmpty) {
        folder.name = value;
      }
      _editingFolderId = null;
      _editControllers.remove(folder.id!)?.dispose();
    });
  }

  void _toggleLorebookEdit(Lorebook lorebook) {
    setState(() {
      if (_editingLorebookId == lorebook.id) {
        // 편집 완료
        final controller = _editControllers[lorebook.id!];
        if (controller != null && controller.text.isNotEmpty) {
          lorebook.name = controller.text;
        }
        _editingLorebookId = null;
        _editControllers.remove(lorebook.id!)?.dispose();
      } else {
        // 편집 시작
        _editingLorebookId = lorebook.id;
        _editControllers[lorebook.id!] = TextEditingController(text: lorebook.name);
      }
    });
  }

  void _saveLorebookName(Lorebook lorebook, String value) {
    setState(() {
      if (value.isNotEmpty) {
        lorebook.name = value;
      }
      _editingLorebookId = null;
      _editControllers.remove(lorebook.id!)?.dispose();
    });
  }

  Widget _buildLorebookItem(Lorebook lorebook, LorebookFolder? folder) {
    return LongPressDraggable<Map<String, dynamic>>(
      data: {
        'type': 'lorebook',
        'lorebook': lorebook,
        'fromFolder': folder,
      },
      feedback: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 300,
          padding: const EdgeInsets.symmetric(
            horizontal: _lorebookItemHorizontalPadding,
            vertical: _lorebookItemVerticalPadding,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                Icons.description_outlined,
                size: 18,
                color: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  lorebook.name,
                  style: Theme.of(context).textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _buildLorebookCard(lorebook, folder),
      ),
      child: _buildLorebookCard(lorebook, folder),
    );
  }

  Widget _buildLorebookCard(Lorebook lorebook, LorebookFolder? folder) {
    return Container(
      key: ValueKey(lorebook.id),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                lorebook.isExpanded = !lorebook.isExpanded;
              });
            },
            overlayColor: WidgetStateProperty.all(Colors.transparent),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: _lorebookItemHorizontalPadding,
                vertical: _lorebookItemVerticalPadding,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: 18,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _editingLorebookId == lorebook.id
                        ? TextField(
                            controller: _editControllers[lorebook.id!],
                            style: Theme.of(context).textTheme.bodyMedium,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            autofocus: true,
                            onSubmitted: (value) => _saveLorebookName(lorebook, value),
                          )
                        : Text(
                            lorebook.name,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                  ),
                  GestureDetector(
                    onTap: () => _toggleLorebookEdit(lorebook),
                    child: Icon(
                      _editingLorebookId == lorebook.id ? Icons.check : Icons.edit_outlined,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => _deleteLorebook(lorebook, folder),
                    child: const Icon(Icons.delete_outline, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    lorebook.isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (lorebook.isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildActivationConditionField(lorebook),
                  if (lorebook.activationCondition == LorebookActivationCondition.keyBased) ...[
                    _buildActivationKeysField(lorebook),
                    _buildKeyConditionField(lorebook),
                  ],
                  _buildDeploymentOrderField(lorebook),
                  _buildContentField(lorebook),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActivationConditionField(Lorebook lorebook) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '활성화 조건',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 2),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<LorebookActivationCondition>(
            showSelectedIcon: false,
            segments: LorebookActivationCondition.values
                .map((condition) => ButtonSegment(
                      value: condition,
                      label: Text(condition.displayName, style: const TextStyle(fontSize: 13)),
                    ))
                .toList(),
            selected: {lorebook.activationCondition},
            onSelectionChanged: (Set<LorebookActivationCondition> selected) {
              setState(() {
                lorebook.activationCondition = selected.first;
              });
            },
            style: ButtonStyle(
              overlayColor: WidgetStateProperty.all(Colors.transparent),
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_segmentedButtonBorderRadius),
                ),
              ),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: const VisualDensity(horizontal: 0, vertical: -2),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildActivationKeysField(Lorebook lorebook) {
    final controller = TextEditingController(text: lorebook.activationKeys.join(', '));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '활성화 키',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 2),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: '쉼표로 구분하여 입력 (예: 마법, 전투)',
            hintStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            isDense: true,
          ),
          style: Theme.of(context).textTheme.bodySmall,
          onChanged: (value) {
            lorebook.activationKeys = value
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList();
          },
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildKeyConditionField(Lorebook lorebook) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '키 사용 조건',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 2),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<LorebookKeyCondition>(
            showSelectedIcon: false,
            segments: LorebookKeyCondition.values
                .map((condition) => ButtonSegment(
                      value: condition,
                      label: Text(condition.displayName, style: const TextStyle(fontSize: 13)),
                    ))
                .toList(),
            selected: {lorebook.keyCondition},
            onSelectionChanged: (Set<LorebookKeyCondition> selected) {
              setState(() {
                lorebook.keyCondition = selected.first;
              });
            },
            style: ButtonStyle(
              overlayColor: WidgetStateProperty.all(Colors.transparent),
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_segmentedButtonBorderRadius),
                ),
              ),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: const VisualDensity(horizontal: 0, vertical: -2),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildDeploymentOrderField(Lorebook lorebook) {
    final controller = TextEditingController(text: lorebook.deploymentOrder.toString());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '배치 순서',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 2),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: '0',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            isDense: true,
          ),
          style: Theme.of(context).textTheme.bodySmall,
          onChanged: (value) {
            final intValue = int.tryParse(value);
            if (intValue != null) {
              lorebook.deploymentOrder = intValue;
            }
          },
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildContentField(Lorebook lorebook) {
    final controller = TextEditingController(text: lorebook.content);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '내용',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 2),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: '로어북 내용을 입력해주세요',
            hintStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            isDense: true,
          ),
          style: Theme.of(context).textTheme.bodySmall,
          maxLines: null,
          minLines: 5,
          onChanged: (value) {
            lorebook.content = value;
          },
        ),
      ],
    );
  }

  Widget _buildPersonaTab() {
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
                  '페르소나',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        content: const Text('캐릭터의 페르소나 정보를 추가할 수 있습니다.'),
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
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _personas.isEmpty
                ? const Center(
                    child: Text('페르소나 항목이 없습니다'),
                  )
                : ListView.builder(
                    itemCount: _personas.length,
                    itemBuilder: (context, index) {
                      return _buildPersonaItem(_personas[index]);
                    },
                  ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _addPersona,
              icon: const Icon(Icons.add),
              label: const Text('페르소나 추가'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addPersona() {
    setState(() {
      final newPersona = Persona(
        id: _getNextTempId(),
        characterId: widget.characterId ?? _tempCharacterId,
        name: '새 페르소나',
        order: _personas.length,
        isExpanded: true,
      );
      _personas.add(newPersona);
    });
  }

  void _deletePersona(Persona persona) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('페르소나 삭제'),
        content: Text('${persona.name}을(를) 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _personas.remove(persona);
              });
              Navigator.pop(context);
            },
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  void _togglePersonaEdit(Persona persona) {
    setState(() {
      if (_editingPersonaId == persona.id) {
        // 편집 완료
        final controller = _editControllers[persona.id!];
        if (controller != null && controller.text.isNotEmpty) {
          persona.name = controller.text;
        }
        _editingPersonaId = null;
        _editControllers.remove(persona.id!)?.dispose();
      } else {
        // 편집 시작
        _editingPersonaId = persona.id;
        _editControllers[persona.id!] = TextEditingController(text: persona.name);
      }
    });
  }

  void _savePersonaName(Persona persona, String value) {
    setState(() {
      if (value.isNotEmpty) {
        persona.name = value;
      }
      _editingPersonaId = null;
      _editControllers.remove(persona.id!)?.dispose();
    });
  }

  Widget _buildPersonaItem(Persona persona) {
    return Container(
      key: ValueKey(persona.id),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                persona.isExpanded = !persona.isExpanded;
              });
            },
            overlayColor: WidgetStateProperty.all(Colors.transparent),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: _lorebookItemHorizontalPadding,
                vertical: _lorebookItemVerticalPadding,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 18,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _editingPersonaId == persona.id
                        ? TextField(
                            controller: _editControllers[persona.id!],
                            style: Theme.of(context).textTheme.bodyMedium,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            autofocus: true,
                            onSubmitted: (value) => _savePersonaName(persona, value),
                          )
                        : Text(
                            persona.name,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                  ),
                  GestureDetector(
                    onTap: () => _togglePersonaEdit(persona),
                    child: Icon(
                      _editingPersonaId == persona.id ? Icons.check : Icons.edit_outlined,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => _deletePersona(persona),
                    child: const Icon(Icons.delete_outline, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    persona.isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (persona.isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(6),
              child: _buildPersonaContentField(persona),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPersonaContentField(Persona persona) {
    final controller = TextEditingController(text: persona.content);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '내용',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 2),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: '페르소나 내용을 입력해주세요',
            hintStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            isDense: true,
          ),
          style: Theme.of(context).textTheme.bodySmall,
          maxLines: null,
          minLines: 5,
          onChanged: (value) {
            persona.content = value;
          },
        ),
      ],
    );
  }

  Widget _buildStartScenarioTab() {
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
                  '시작설정',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        content: const Text('대화의 시작 설정 정보를 추가할 수 있습니다.'),
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
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _startScenarios.isEmpty
                ? const Center(
                    child: Text('시작설정 항목이 없습니다'),
                  )
                : ListView.builder(
                    itemCount: _startScenarios.length,
                    itemBuilder: (context, index) {
                      return _buildStartScenarioItem(_startScenarios[index]);
                    },
                  ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _addStartScenario,
              icon: const Icon(Icons.add),
              label: const Text('시작설정 추가'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addStartScenario() {
    setState(() {
      final newScenario = StartScenario(
        id: _getNextTempId(),
        characterId: widget.characterId ?? _tempCharacterId,
        name: '새 시작설정',
        order: _startScenarios.length,
        isExpanded: true,
      );
      _startScenarios.add(newScenario);
    });
  }

  void _deleteStartScenario(StartScenario scenario) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('시작설정 삭제'),
        content: Text('${scenario.name}을(를) 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _startScenarios.remove(scenario);
              });
              Navigator.pop(context);
            },
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  void _toggleStartScenarioEdit(StartScenario scenario) {
    setState(() {
      if (_editingStartScenarioId == scenario.id) {
        // 편집 완료
        final controller = _editControllers[scenario.id!];
        if (controller != null && controller.text.isNotEmpty) {
          scenario.name = controller.text;
        }
        _editingStartScenarioId = null;
        _editControllers.remove(scenario.id!)?.dispose();
      } else {
        // 편집 시작
        _editingStartScenarioId = scenario.id;
        _editControllers[scenario.id!] = TextEditingController(text: scenario.name);
      }
    });
  }

  void _saveStartScenarioName(StartScenario scenario, String value) {
    setState(() {
      if (value.isNotEmpty) {
        scenario.name = value;
      }
      _editingStartScenarioId = null;
      _editControllers.remove(scenario.id!)?.dispose();
    });
  }

  Widget _buildStartScenarioItem(StartScenario scenario) {
    return Container(
      key: ValueKey(scenario.id),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                scenario.isExpanded = !scenario.isExpanded;
              });
            },
            overlayColor: WidgetStateProperty.all(Colors.transparent),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: _lorebookItemHorizontalPadding,
                vertical: _lorebookItemVerticalPadding,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.play_circle_outline,
                    size: 18,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _editingStartScenarioId == scenario.id
                        ? TextField(
                            controller: _editControllers[scenario.id!],
                            style: Theme.of(context).textTheme.bodyMedium,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            autofocus: true,
                            onSubmitted: (value) => _saveStartScenarioName(scenario, value),
                          )
                        : Text(
                            scenario.name,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                  ),
                  GestureDetector(
                    onTap: () => _toggleStartScenarioEdit(scenario),
                    child: Icon(
                      _editingStartScenarioId == scenario.id ? Icons.check : Icons.edit_outlined,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => _deleteStartScenario(scenario),
                    child: const Icon(Icons.delete_outline, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    scenario.isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (scenario.isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStartSettingField(scenario),
                  _buildStartMessageField(scenario),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStartSettingField(StartScenario scenario) {
    final controller = TextEditingController(text: scenario.startSetting);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '시작 설정',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    content: const Text('해당 내용은 요약 이전에 삽입되고 삭제되지 않습니다.'),
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
                size: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: '시작 설정 내용을 입력해주세요',
            hintStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            isDense: true,
          ),
          style: Theme.of(context).textTheme.bodySmall,
          maxLines: null,
          minLines: 5,
          onChanged: (value) {
            scenario.startSetting = value;
          },
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildStartMessageField(StartScenario scenario) {
    final controller = TextEditingController(text: scenario.startMessage);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '시작 메시지',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 2),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: '시작 메시지를 입력해주세요',
            hintStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            isDense: true,
          ),
          style: Theme.of(context).textTheme.bodySmall,
          maxLines: null,
          minLines: 5,
          onChanged: (value) {
            scenario.startMessage = value;
          },
        ),
      ],
    );
  }

  Widget _buildCoverTab() {
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
                  '표지',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        content: const Text('캐릭터의 표지 이미지를 추가할 수 있습니다.'),
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
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _coverImages.isEmpty
                ? const Center(
                    child: Text('표지 이미지가 없습니다'),
                  )
                : ListView.builder(
                    itemCount: _coverImages.length,
                    itemBuilder: (context, index) {
                      return _buildCoverImageItem(_coverImages[index]);
                    },
                  ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _addCoverImage,
              icon: const Icon(Icons.add),
              label: const Text('표지 이미지 추가'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addCoverImage() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
    );

    if (image != null) {
      setState(() {
        final newCoverImage = CoverImage(
          id: _getNextTempId(),
          characterId: widget.characterId ?? _tempCharacterId,
          name: '표지 ${_coverImages.length + 1}',
          order: _coverImages.length,
          imagePath: image.path,
          isExpanded: true,
        );
        _coverImages.add(newCoverImage);

        // 첫 번째 표지를 자동으로 선택
        if (_coverImages.length == 1) {
          _selectedCoverImageId = newCoverImage.id;
        }
      });
    }
  }

  void _deleteCoverImage(CoverImage coverImage) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('표지 이미지 삭제'),
        content: Text('${coverImage.name}을(를) 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _coverImages.remove(coverImage);

                // 선택된 표지를 삭제한 경우
                if (_selectedCoverImageId == coverImage.id) {
                  // 첫 번째 표지를 선택하거나, 없으면 null
                  _selectedCoverImageId = _coverImages.isNotEmpty ? _coverImages.first.id : null;
                }
              });
              Navigator.pop(context);
            },
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  void _toggleCoverImageEdit(CoverImage coverImage) {
    setState(() {
      if (_editingCoverImageId == coverImage.id) {
        // 편집 완료
        final controller = _editControllers[coverImage.id!];
        if (controller != null && controller.text.isNotEmpty) {
          coverImage.name = controller.text;
        }
        _editingCoverImageId = null;
        _editControllers.remove(coverImage.id!)?.dispose();
      } else {
        // 편집 시작
        _editingCoverImageId = coverImage.id;
        _editControllers[coverImage.id!] = TextEditingController(text: coverImage.name);
      }
    });
  }

  void _saveCoverImageName(CoverImage coverImage, String value) {
    setState(() {
      if (value.isNotEmpty) {
        coverImage.name = value;
      }
      _editingCoverImageId = null;
      _editControllers.remove(coverImage.id!)?.dispose();
    });
  }

  Widget _buildCoverImageItem(CoverImage coverImage) {
    return Container(
      key: ValueKey(coverImage.id),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                coverImage.isExpanded = !coverImage.isExpanded;
              });
            },
            overlayColor: WidgetStateProperty.all(Colors.transparent),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: _lorebookItemHorizontalPadding,
                vertical: _lorebookItemVerticalPadding,
              ),
              child: Row(
                children: [
                  Radio<int>(
                    value: coverImage.id!,
                    groupValue: _selectedCoverImageId,
                    onChanged: (int? value) {
                      setState(() {
                        _selectedCoverImageId = value;
                      });
                    },
                    visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _editingCoverImageId == coverImage.id
                        ? TextField(
                            controller: _editControllers[coverImage.id!],
                            style: Theme.of(context).textTheme.bodyMedium,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            autofocus: true,
                            onSubmitted: (value) => _saveCoverImageName(coverImage, value),
                          )
                        : Text(
                            coverImage.name,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                  ),
                  GestureDetector(
                    onTap: () => _toggleCoverImageEdit(coverImage),
                    child: Icon(
                      _editingCoverImageId == coverImage.id ? Icons.check : Icons.edit_outlined,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => _deleteCoverImage(coverImage),
                    child: const Icon(Icons.delete_outline, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    coverImage.isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (coverImage.isExpanded && coverImage.imagePath != null) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(coverImage.imagePath!),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: const Center(
                        child: Icon(Icons.error_outline),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
