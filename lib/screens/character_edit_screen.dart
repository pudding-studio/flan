import 'package:flutter/material.dart';
import '../widgets/custom_text_field.dart';
import '../constants/ui_constants.dart';

class CharacterEditScreen extends StatefulWidget {
  final String? characterId;

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

  bool get _isEditMode => widget.characterId != null;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _summaryController.dispose();
    _keywordsController.dispose();
    super.dispose();
  }

  void _handleSaveDraft() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('임시저장되었습니다')),
    );
  }

  void _handleComplete() {
    if (_formKey.currentState?.validate() ?? false) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditMode ? '캐릭터가 수정되었습니다' : '캐릭터가 생성되었습니다'),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(_isEditMode ? '캐릭터 수정' : '캐릭터 만들기'),
        actions: [
          IconButton(
            icon: const Icon(Icons.drafts_outlined),
            onPressed: _handleSaveDraft,
            tooltip: '임시저장',
          ),
          TextButton(
            onPressed: _handleComplete,
            child: const Text(
              '완료',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
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
                  child: Center(child: Text('시작설정')),
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
          _buildAdditionalInfoTab(),
          _buildMarketStatusTab(),
        ],
      ),
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
    return ListView(
      padding: const EdgeInsets.all(UIConstants.spacing16),
      children: const [
        Center(
          child: Text('상세설정 탭 (구현 예정)'),
        ),
      ],
    );
  }

  Widget _buildAdditionalInfoTab() {
    return ListView(
      padding: const EdgeInsets.all(UIConstants.spacing16),
      children: const [
        Center(
          child: Text('부가정보 탭 (구현 예정)'),
        ),
      ],
    );
  }

  Widget _buildMarketStatusTab() {
    return ListView(
      padding: const EdgeInsets.all(UIConstants.spacing16),
      children: const [
        Center(
          child: Text('시장상황 탭 (구현 예정)'),
        ),
      ],
    );
  }
}
