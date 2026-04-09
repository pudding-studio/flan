import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/chat/chat_model.dart';
import '../../models/chat/unified_model.dart';
import '../../providers/chat_model_provider.dart';
import '../../services/vertex_auth_service.dart';
import '../../utils/common_dialog.dart';
import '../settings/api_key_screen.dart';

class _HelpStep {
  final String label;
  final String? url;
  const _HelpStep(this.label, [this.url]);
}

const String _tutorialCompletedKey = 'tutorial_completed';
const String showAgentHighlightKey = 'show_agent_highlight';

Future<bool> isTutorialCompleted() async {
  if (kDebugMode) return false;
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_tutorialCompletedKey) ?? false;
}

Future<void> setTutorialCompleted() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_tutorialCompletedKey, true);
  await prefs.setBool(showAgentHighlightKey, true);
}

/// Provider → recommended models mapping
class _ProviderModels {
  final ChatModelProvider provider;
  final List<ChatModel> mainCandidates;
  final List<ChatModel> subCandidates;
  final ChatModel defaultMain;
  final ChatModel defaultSub;
  final String mainDescription;
  final String subDescription;

  const _ProviderModels({
    required this.provider,
    required this.mainCandidates,
    required this.subCandidates,
    required this.defaultMain,
    required this.defaultSub,
    required this.mainDescription,
    required this.subDescription,
  });
}

final Map<ApiKeyType, _ProviderModels> _providerModelMap = {
  ApiKeyType.googleAiStudio: _ProviderModels(
    provider: ChatModelProvider.googleAIStudio,
    mainCandidates: [
      ChatModel.geminiPro31Preview,
      ChatModel.geminiPro25,
    ],
    subCandidates: [
      ChatModel.geminiFlash3Preview,
      ChatModel.geminiFlashLite31Preview,
      ChatModel.geminiFlash25,
      ChatModel.geminiFlashLite25,
    ],
    defaultMain: ChatModel.geminiPro31Preview,
    defaultSub: ChatModel.geminiFlash3Preview,
    mainDescription: '채팅에 사용되는 모델입니다. Gemini 3.1 Pro 추천',
    subDescription: '요약, SNS, 뉴스 기능 등에 사용됩니다. Gemini 3 Flash 추천',
  ),
  ApiKeyType.vertexAi: _ProviderModels(
    provider: ChatModelProvider.vertexAi,
    mainCandidates: [
      ChatModel.vertexGeminiPro31Preview,
      ChatModel.vertexGeminiPro31,
      ChatModel.vertexGeminiPro25,
    ],
    subCandidates: [
      ChatModel.vertexGeminiFlash3Preview,
      ChatModel.vertexGeminiFlashLite31Preview,
      ChatModel.vertexGeminiFlash25,
      ChatModel.vertexGeminiFlashLite25,
    ],
    defaultMain: ChatModel.vertexGeminiPro31Preview,
    defaultSub: ChatModel.vertexGeminiFlash3Preview,
    mainDescription: '채팅에 사용되는 모델입니다. Gemini 3.1 Pro 추천',
    subDescription: '요약, SNS, 뉴스 기능 등에 사용됩니다. Gemini 3 Flash 추천',
  ),
  ApiKeyType.openai: _ProviderModels(
    provider: ChatModelProvider.openai,
    mainCandidates: [
      ChatModel.gpt54,
      ChatModel.gpt41,
      ChatModel.o3,
    ],
    subCandidates: [
      ChatModel.gpt54Mini,
      ChatModel.gpt54Nano,
      ChatModel.gpt41Mini,
      ChatModel.gpt41Nano,
    ],
    defaultMain: ChatModel.gpt54,
    defaultSub: ChatModel.gpt54Mini,
    mainDescription: '채팅에 사용되는 모델입니다. GPT-5.4 추천',
    subDescription: '요약, SNS, 뉴스 기능 등에 사용됩니다. GPT-5.4 Mini 추천',
  ),
  ApiKeyType.anthropic: _ProviderModels(
    provider: ChatModelProvider.anthropic,
    mainCandidates: [
      ChatModel.claudeSonnet46,
      ChatModel.claudeOpus46,
      ChatModel.claudeSonnet45,
      ChatModel.claudeOpus45,
    ],
    subCandidates: [
      ChatModel.claudeHaiku45,
      ChatModel.claudeSonnet46,
      ChatModel.claudeSonnet45,
      ChatModel.claudeHaiku35,
    ],
    defaultMain: ChatModel.claudeSonnet46,
    defaultSub: ChatModel.claudeHaiku45,
    mainDescription: '채팅에 사용되는 모델입니다. Claude Sonnet 4.6 추천',
    subDescription: '요약, SNS, 뉴스 기능 등에 사용됩니다. Claude Haiku 4.5 추천',
  ),
};

class TutorialScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const TutorialScreen({super.key, required this.onComplete});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  static const int _totalPages = 4;

  // API key state
  ApiKeyType _selectedApiKeyType = ApiKeyType.googleAiStudio;
  final _apiKeyController = TextEditingController();
  bool _isApiKeySaving = false;
  bool _apiKeySaved = false;

  bool get _isVertexAi => _selectedApiKeyType == ApiKeyType.vertexAi;

  // Model selection state
  late ChatModel _selectedMainModel;
  late ChatModel _selectedSubModel;

  @override
  void initState() {
    super.initState();
    _applyProviderDefaults();
  }

  void _applyProviderDefaults() {
    final pm = _providerModelMap[_selectedApiKeyType]!;
    _selectedMainModel = pm.defaultMain;
    _selectedSubModel = pm.defaultSub;
  }

  _ProviderModels get _currentProviderModels =>
      _providerModelMap[_selectedApiKeyType]!;

  @override
  void dispose() {
    _pageController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onApiKeyTypeChanged(ApiKeyType type) {
    if (type == _selectedApiKeyType) return;
    setState(() {
      _selectedApiKeyType = type;
      _apiKeySaved = false;
      _apiKeyController.clear();
      _applyProviderDefaults();
    });
  }

  Future<void> _saveApiKey() async {
    final key = _apiKeyController.text.trim();
    if (key.isEmpty) {
      CommonDialog.showSnackBar(context: context, message: 'API 키를 입력해주세요');
      return;
    }
    await _persistKey(key);
  }

  Future<void> _pickVertexAiJsonFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result == null || result.files.single.path == null) return;

    setState(() => _isApiKeySaving = true);
    try {
      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();

      final validationError =
          await VertexAuthService.validateServiceAccountJson(jsonString);
      if (validationError != null) {
        if (mounted) {
          await CommonDialog.showInfo(
            context: context,
            title: '서비스 계정 검증 실패',
            content: validationError,
          );
        }
        return;
      }

      await _persistKey(jsonString);
    } catch (e) {
      if (mounted) {
        CommonDialog.showSnackBar(
          context: context,
          message: 'JSON 파일 읽기 실패: $e',
        );
      }
    } finally {
      if (mounted) setState(() => _isApiKeySaving = false);
    }
  }

  Future<void> _persistKey(String key) async {
    setState(() => _isApiKeySaving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final type = _selectedApiKeyType;
      final multiKeys = jsonEncode([key]);
      await prefs.setString(type.multiStorageKey, multiKeys);
      await prefs.setInt(type.activeIndexKey, 0);
      await prefs.setString(type.storageKey, key);

      // Legacy key for Google AI Studio
      if (type == ApiKeyType.googleAiStudio) {
        await prefs.setString('api_key', key);
      }

      if (mounted) {
        setState(() {
          _apiKeySaved = true;
          _isApiKeySaving = false;
        });
        final label = _isVertexAi
            ? 'Vertex AI 서비스 계정이 등록되었습니다'
            : '${type.displayName} API 키가 저장되었습니다';
        CommonDialog.showSnackBar(context: context, message: label);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isApiKeySaving = false);
        CommonDialog.showSnackBar(
          context: context,
          message: 'API 키 저장 실패: $e',
        );
      }
    }
  }

  Future<void> _saveModelsAndFinish() async {
    final pm = _currentProviderModels;
    final provider = context.read<ChatModelSettingsProvider>();
    await provider.setProvider(pm.provider);
    await provider.setModel(UnifiedModel.fromChatModel(_selectedMainModel));
    await provider.setSubProvider(pm.provider);
    await provider.setSubModel(UnifiedModel.fromChatModel(_selectedSubModel));

    await setTutorialCompleted();
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                children: List.generate(_totalPages, (index) {
                  return Expanded(
                    child: Container(
                      height: 3,
                      margin: EdgeInsets.only(
                        right: index < _totalPages - 1 ? 4 : 0,
                      ),
                      decoration: BoxDecoration(
                        color: index <= _currentPage
                            ? colorScheme.primary
                            : colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) {
                  setState(() => _currentPage = page);
                },
                children: [
                  _buildWelcomePage(theme, colorScheme),
                  _buildApiKeyPage(theme, colorScheme),
                  _buildModelSelectionPage(theme, colorScheme),
                  _buildCompletePage(theme, colorScheme),
                ],
              ),
            ),

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    TextButton(
                      onPressed: _previousPage,
                      child: const Text('이전'),
                    ),
                  const Spacer(),
                  if (_currentPage < _totalPages - 1)
                    FilledButton(
                      onPressed: _canProceed() ? _nextPage : null,
                      child: const Text('다음'),
                    ),
                  if (_currentPage == _totalPages - 1)
                    FilledButton(
                      onPressed: _saveModelsAndFinish,
                      child: const Text('시작하기'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _canProceed() {
    switch (_currentPage) {
      case 1:
        return _apiKeySaved;
      default:
        return true;
    }
  }

  // Page 0: Welcome
  Widget _buildWelcomePage(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_awesome,
            size: 80,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 32),
          Text(
            'Flan에 오신 것을 환영합니다',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'AI 캐릭터와 대화하고, 나만의 세계를 만들어보세요.\n간단한 초기 설정을 진행하겠습니다.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Page 1: API Key
  Widget _buildApiKeyPage(ThemeData theme, ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            theme: theme,
            colorScheme: colorScheme,
            step: 1,
            title: 'API 키 등록',
            description: 'AI 모델을 사용하기 위해 API 키가 필요합니다.\n사용할 서비스를 선택하고 키를 등록해주세요.',
          ),
          const SizedBox(height: 20),

          // Provider selector
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ApiKeyType.values.map((type) {
                final isSelected = _selectedApiKeyType == type;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(type.displayName),
                    selected: isSelected,
                    onSelected: _apiKeySaved
                        ? null
                        : (_) => _onApiKeyTypeChanged(type),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          if (_isVertexAi) ...[
            // Vertex AI: JSON file upload
            SizedBox(
              width: double.infinity,
              child: _apiKeySaved
                  ? OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _apiKeySaved = false;
                        });
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('다시 등록'),
                    )
                  : FilledButton.icon(
                      onPressed: _isApiKeySaving ? null : _pickVertexAiJsonFile,
                      icon: _isApiKeySaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.upload_file),
                      label: const Text('서비스 계정 JSON 파일 가져오기'),
                    ),
            ),
          ] else ...[
            // Text key input
            TextField(
              controller: _apiKeyController,
              obscureText: true,
              enabled: !_apiKeySaved,
              decoration: InputDecoration(
                hintText: 'API 키를 입력해주세요',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: _apiKeySaved
                    ? Icon(Icons.check_circle, color: colorScheme.primary)
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: _apiKeySaved
                  ? OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _apiKeySaved = false;
                          _apiKeyController.clear();
                        });
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('다시 입력'),
                    )
                  : FilledButton.icon(
                      onPressed: _isApiKeySaving ? null : _saveApiKey,
                      icon: _isApiKeySaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save),
                      label: const Text('저장'),
                    ),
            ),
          ],

          const SizedBox(height: 24),
          _buildApiKeyHelpCard(theme, colorScheme),
        ],
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildApiKeyHelpCard(ThemeData theme, ColorScheme colorScheme) {
    final String helpTitle;
    final List<_HelpStep> steps;

    switch (_selectedApiKeyType) {
      case ApiKeyType.googleAiStudio:
        helpTitle = 'Google AI Studio API 키 발급';
        steps = [
          _HelpStep('Google AI Studio 접속', 'https://aistudio.google.com'),
          const _HelpStep('결제 계정 생성 (유료 모델 사용 시 필요)'),
          const _HelpStep('Get API Key 클릭'),
          const _HelpStep('Create API Key 선택'),
          const _HelpStep('생성된 키를 복사하여 위에 붙여넣기'),
        ];
      case ApiKeyType.vertexAi:
        helpTitle = 'Vertex AI 서비스 계정 설정';
        steps = [
          _HelpStep('Google Cloud Console 접속', 'https://console.cloud.google.com'),
          _HelpStep('결제 계정 생성 및 프로젝트에 연결', 'https://console.cloud.google.com/billing'),
          const _HelpStep('IAM → 서비스 계정 → 계정 생성'),
          const _HelpStep('Vertex AI User 역할 부여'),
          const _HelpStep('키 만들기 → JSON → 다운로드'),
        ];
      case ApiKeyType.openai:
        helpTitle = 'OpenAI API 키 발급';
        steps = [
          _HelpStep('OpenAI Platform 접속', 'https://platform.openai.com'),
          const _HelpStep('API Keys 메뉴 선택'),
          const _HelpStep('Create new secret key 클릭'),
          const _HelpStep('생성된 키를 복사하여 위에 붙여넣기'),
        ];
      case ApiKeyType.anthropic:
        helpTitle = 'Anthropic API 키 발급';
        steps = [
          _HelpStep('Anthropic Console 접속', 'https://console.anthropic.com'),
          const _HelpStep('API Keys 메뉴 선택'),
          const _HelpStep('Create Key 클릭'),
          const _HelpStep('생성된 키를 복사하여 위에 붙여넣기'),
        ];
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline,
                  size: 18, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(
                child: Text(helpTitle, style: theme.textTheme.titleSmall),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...steps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            final hasLink = step.url != null;

            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: InkWell(
                onTap: hasLink ? () => _openUrl(step.url!) : null,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 20,
                        child: Text(
                          '${index + 1}.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          step.label,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: hasLink
                                ? colorScheme.primary
                                : colorScheme.onSurfaceVariant,
                            decoration: hasLink
                                ? TextDecoration.underline
                                : null,
                            decorationColor:
                                hasLink ? colorScheme.primary : null,
                          ),
                        ),
                      ),
                      if (hasLink)
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Icon(
                            Icons.open_in_new,
                            size: 12,
                            color: colorScheme.primary,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // Page 2: Model selection (main + sub)
  Widget _buildModelSelectionPage(ThemeData theme, ColorScheme colorScheme) {
    final pm = _currentProviderModels;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            theme: theme,
            colorScheme: colorScheme,
            step: 2,
            title: '모델 설정',
            description: '채팅과 보조 기능에 사용할 AI 모델을 선택해주세요.',
          ),
          const SizedBox(height: 28),

          // Main model
          Row(
            children: [
              Icon(Icons.star, size: 20, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text('주 모델', style: theme.textTheme.titleSmall),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            pm.mainDescription,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          ...(pm.mainCandidates.map((model) => _buildModelOption(
                theme: theme,
                colorScheme: colorScheme,
                model: model,
                isSelected: _selectedMainModel == model,
                recommended: model == pm.defaultMain,
                onTap: () => setState(() => _selectedMainModel = model),
              ))),

          const SizedBox(height: 28),

          // Sub model
          Row(
            children: [
              Icon(Icons.flash_on, size: 20, color: colorScheme.secondary),
              const SizedBox(width: 8),
              Text('보조 모델', style: theme.textTheme.titleSmall),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            pm.subDescription,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          ...(pm.subCandidates.map((model) => _buildModelOption(
                theme: theme,
                colorScheme: colorScheme,
                model: model,
                isSelected: _selectedSubModel == model,
                recommended: model == pm.defaultSub,
                onTap: () => setState(() => _selectedSubModel = model),
              ))),
        ],
      ),
    );
  }

  // Page 3: Complete
  Widget _buildCompletePage(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 80,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 32),
          Text(
            '설정이 완료되었습니다!',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            '이제 캐릭터를 만들어볼까요?',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.auto_awesome,
                        color: colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Flan Agent',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '캐릭터 탭 상단의 빛나는 아이콘을 눌러보세요',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Agent에게 원하는 캐릭터를 만들어달라고 말해보세요!\n'
                  '"판타지 세계의 엘프 마법사를 만들어줘" 같이 자유롭게 요청하면 됩니다.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepHeader({
    required ThemeData theme,
    required ColorScheme colorScheme,
    required int step,
    required String title,
    required String description,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: colorScheme.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'STEP $step',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildModelOption({
    required ThemeData theme,
    required ColorScheme colorScheme,
    required ChatModel model,
    required bool isSelected,
    required bool recommended,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isSelected
            ? colorScheme.primaryContainer.withValues(alpha: 0.5)
            : colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color:
                      isSelected ? colorScheme.primary : colorScheme.outline,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              model.displayName,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (recommended) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: colorScheme.tertiary
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '추천',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.tertiary,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _modelPriceLabel(model),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _modelPriceLabel(ChatModel model) {
    final p = model.pricing;
    return '입력 \$${p.inputPrice}/1M · 출력 \$${p.outputPrice}/1M';
  }
}
