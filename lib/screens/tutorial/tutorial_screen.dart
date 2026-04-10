import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_localizations.dart';
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
  final prefs = await SharedPreferences.getInstance();

  // Check if any API key is registered
  for (final type in ApiKeyType.values) {
    final multiKeys = prefs.getString(type.multiStorageKey);
    if (multiKeys != null) {
      final List<dynamic> decoded = jsonDecode(multiKeys);
      if (decoded.isNotEmpty) return true;
    }
  }

  // Check if custom models exist (user has their own endpoint)
  final customModels = prefs.getString('custom_models');
  if (customModels != null) {
    final List<dynamic> decoded = jsonDecode(customModels);
    if (decoded.isNotEmpty) return true;
  }

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

  const _ProviderModels({
    required this.provider,
    required this.mainCandidates,
    required this.subCandidates,
    required this.defaultMain,
    required this.defaultSub,
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
  ),
};

({String main, String sub}) _providerDescriptions(
  ApiKeyType type,
  AppLocalizations l10n,
) {
  switch (type) {
    case ApiKeyType.googleAiStudio:
    case ApiKeyType.vertexAi:
      return (main: l10n.tutorialMainDescGemini, sub: l10n.tutorialSubDescGemini);
    case ApiKeyType.openai:
      return (main: l10n.tutorialMainDescOpenai, sub: l10n.tutorialSubDescOpenai);
    case ApiKeyType.anthropic:
      return (
        main: l10n.tutorialMainDescAnthropic,
        sub: l10n.tutorialSubDescAnthropic
      );
  }
}

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
      CommonDialog.showSnackBar(
        context: context,
        message: AppLocalizations.of(context).tutorialApiKeyEmpty,
      );
      return;
    }
    await _persistKey(key);
  }

  Future<void> _pickVertexAiJsonFile() async {
    final l10n = AppLocalizations.of(context);
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
            title: l10n.tutorialVertexValidationFailed,
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
          message: l10n.tutorialJsonReadFailed(e.toString()),
        );
      }
    } finally {
      if (mounted) setState(() => _isApiKeySaving = false);
    }
  }

  Future<void> _persistKey(String key) async {
    final l10n = AppLocalizations.of(context);
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
            ? l10n.tutorialVertexSaved
            : l10n.tutorialApiKeySaved(type.displayName);
        CommonDialog.showSnackBar(context: context, message: label);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isApiKeySaving = false);
        CommonDialog.showSnackBar(
          context: context,
          message: l10n.tutorialApiKeySaveFailed(e.toString()),
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
    final l10n = AppLocalizations.of(context);

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
                  _buildWelcomePage(theme, colorScheme, l10n),
                  _buildApiKeyPage(theme, colorScheme, l10n),
                  _buildModelSelectionPage(theme, colorScheme, l10n),
                  _buildCompletePage(theme, colorScheme, l10n),
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
                      child: Text(l10n.tutorialPrevious),
                    ),
                  const Spacer(),
                  if (_currentPage < _totalPages - 1)
                    FilledButton(
                      onPressed: _canProceed() ? _nextPage : null,
                      child: Text(l10n.tutorialNext),
                    ),
                  if (_currentPage == _totalPages - 1)
                    FilledButton(
                      onPressed: _saveModelsAndFinish,
                      child: Text(l10n.tutorialStart),
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
      default:
        return true;
    }
  }

  // Page 0: Welcome
  Widget _buildWelcomePage(
      ThemeData theme, ColorScheme colorScheme, AppLocalizations l10n) {
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
            l10n.tutorialWelcomeTitle,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.tutorialWelcomeBody,
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
  Widget _buildApiKeyPage(
      ThemeData theme, ColorScheme colorScheme, AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            theme: theme,
            colorScheme: colorScheme,
            step: 1,
            title: l10n.tutorialApiKeyTitle,
            description: l10n.tutorialApiKeyDesc,
            l10n: l10n,
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
                      label: Text(l10n.tutorialReRegister),
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
                      label: Text(l10n.tutorialVertexImport),
                    ),
            ),
          ] else ...[
            // Text key input
            TextField(
              controller: _apiKeyController,
              obscureText: true,
              enabled: !_apiKeySaved,
              decoration: InputDecoration(
                hintText: l10n.tutorialApiKeyHint,
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
                      label: Text(l10n.tutorialReInput),
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
                      label: Text(l10n.commonSave),
                    ),
            ),
          ],

          const SizedBox(height: 24),
          _buildApiKeyHelpCard(theme, colorScheme, l10n),
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

  Widget _buildApiKeyHelpCard(
      ThemeData theme, ColorScheme colorScheme, AppLocalizations l10n) {
    final String helpTitle;
    final List<_HelpStep> steps;

    switch (_selectedApiKeyType) {
      case ApiKeyType.googleAiStudio:
        helpTitle = l10n.tutorialHelpGoogleAi;
        steps = [
          _HelpStep('Google AI Studio 접속', 'https://aistudio.google.com'),
          const _HelpStep('결제 계정 생성 (유료 모델 사용 시 필요)'),
          const _HelpStep('Get API Key 클릭'),
          const _HelpStep('Create API Key 선택'),
          const _HelpStep('생성된 키를 복사하여 위에 붙여넣기'),
        ];
      case ApiKeyType.vertexAi:
        helpTitle = l10n.tutorialHelpVertex;
        steps = [
          _HelpStep('Google Cloud Console 접속', 'https://console.cloud.google.com'),
          _HelpStep('결제 계정 생성 및 프로젝트에 연결', 'https://console.cloud.google.com/billing'),
          const _HelpStep('IAM → 서비스 계정 → 계정 생성'),
          const _HelpStep('Vertex AI User 역할 부여'),
          const _HelpStep('키 만들기 → JSON → 다운로드'),
        ];
      case ApiKeyType.openai:
        helpTitle = l10n.tutorialHelpOpenai;
        steps = [
          _HelpStep('OpenAI Platform 접속', 'https://platform.openai.com'),
          const _HelpStep('API Keys 메뉴 선택'),
          const _HelpStep('Create new secret key 클릭'),
          const _HelpStep('생성된 키를 복사하여 위에 붙여넣기'),
        ];
      case ApiKeyType.anthropic:
        helpTitle = l10n.tutorialHelpAnthropic;
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
  Widget _buildModelSelectionPage(
      ThemeData theme, ColorScheme colorScheme, AppLocalizations l10n) {
    final pm = _currentProviderModels;
    final descriptions = _providerDescriptions(_selectedApiKeyType, l10n);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            theme: theme,
            colorScheme: colorScheme,
            step: 2,
            title: l10n.tutorialModelTitle,
            description: l10n.tutorialModelDesc,
            l10n: l10n,
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
                    onSelected: (_) {
                      if (!isSelected) _onApiKeyTypeChanged(type);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // Main model
          Row(
            children: [
              Icon(Icons.star, size: 20, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(l10n.tutorialMainModel, style: theme.textTheme.titleSmall),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            descriptions.main,
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
                l10n: l10n,
              ))),

          const SizedBox(height: 28),

          // Sub model
          Row(
            children: [
              Icon(Icons.flash_on, size: 20, color: colorScheme.secondary),
              const SizedBox(width: 8),
              Text(l10n.tutorialSubModel, style: theme.textTheme.titleSmall),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            descriptions.sub,
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
                l10n: l10n,
              ))),
        ],
      ),
    );
  }

  // Page 3: Complete
  Widget _buildCompletePage(
      ThemeData theme, ColorScheme colorScheme, AppLocalizations l10n) {
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
            l10n.tutorialCompleteTitle,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.tutorialCompleteSubtitle,
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
                            l10n.tutorialAgentBoxTitle,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l10n.tutorialAgentBoxSubtitle,
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
                  l10n.tutorialAgentBoxBody,
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
    required AppLocalizations l10n,
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
            l10n.tutorialStep(step),
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
    required AppLocalizations l10n,
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
                                l10n.tutorialModelRecommended,
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
