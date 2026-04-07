import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../../models/chat/chat_model.dart';
import '../../models/chat/custom_model.dart';
import '../../models/chat/custom_provider.dart';
import '../../providers/chat_model_provider.dart';
import '../../utils/common_dialog.dart';
import '../../widgets/common/common_appbar.dart';
import '../../widgets/common/common_button.dart';
import '../../widgets/common/common_custom_text_field.dart';
import '../../widgets/common/common_filter_chip.dart';
import '../../widgets/common/common_title_medium.dart';

class CustomModelScreen extends StatelessWidget {
  const CustomModelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: '커스텀 모델',
        actions: [
          CommonAppBarIconButton(
            icon: Icons.file_download_outlined,
            onPressed: () => _importFromJson(context),
          ),
          CommonAppBarIconButton(
            icon: Icons.file_upload_outlined,
            onPressed: () => _exportToJson(context),
          ),
          CommonAppBarIconButton(
            icon: Icons.add,
            onPressed: () => _openProviderEditor(context, null),
          ),
        ],
      ),
      body: Consumer<ChatModelSettingsProvider>(
        builder: (context, provider, child) {
          final providers = provider.customProviders;

          if (providers.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.extension_outlined,
                    size: 48,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '커스텀 제조사가 없습니다',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'OpenRouter, 로컬 LLM 등의 제조사를 추가하세요',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 24),
                  CommonButton.filled(
                    onPressed: () => _openProviderEditor(context, null),
                    icon: Icons.add,
                    label: '제조사 추가',
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: providers.length,
            itemBuilder: (context, index) {
              final cp = providers[index];
              final models = provider.getModelsByProvider(cp.id);
              return _ProviderCard(
                provider: cp,
                models: models,
                onEditProvider: () => _openProviderEditor(context, cp),
                onDeleteProvider: () =>
                    _deleteProvider(context, provider, cp, models.length),
                onAddModel: () => _openModelEditor(context, cp.id, null),
                onEditModel: (m) => _openModelEditor(context, cp.id, m),
                onDeleteModel: (m) => _deleteModel(context, provider, m),
              );
            },
          );
        },
      ),
    );
  }

  void _openProviderEditor(BuildContext context, CustomProvider? provider) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _CustomProviderEditorScreen(provider: provider),
      ),
    );
  }

  void _openModelEditor(
      BuildContext context, String providerId, CustomModel? model) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            _CustomModelEditorScreen(providerId: providerId, model: model),
      ),
    );
  }

  Future<void> _deleteProvider(
    BuildContext context,
    ChatModelSettingsProvider settingsProvider,
    CustomProvider provider,
    int modelCount,
  ) async {
    final message = modelCount > 0
        ? "'${provider.name}' 제조사와 하위 모델 $modelCount개를 삭제하시겠습니까?"
        : "'${provider.name}' 제조사를 삭제하시겠습니까?";
    final confirmed = await CommonDialog.showConfirmation(
      context: context,
      title: '제조사 삭제',
      content: message,
      confirmText: '삭제',
      isDestructive: true,
    );
    if (confirmed == true) {
      await settingsProvider.deleteCustomProvider(provider.id);
    }
  }

  Future<void> _deleteModel(
    BuildContext context,
    ChatModelSettingsProvider settingsProvider,
    CustomModel model,
  ) async {
    final confirmed = await CommonDialog.showConfirmation(
      context: context,
      title: '모델 삭제',
      content: "'${model.displayName}' 모델을 삭제하시겠습니까?",
      confirmText: '삭제',
      isDestructive: true,
    );
    if (confirmed == true) {
      await settingsProvider.deleteCustomModel(model.id);
    }
  }

  Future<void> _exportToJson(BuildContext context) async {
    final provider = context.read<ChatModelSettingsProvider>();
    final providers = provider.customProviders;
    final models = provider.customModels;

    if (providers.isEmpty) {
      CommonDialog.showSnackBar(
        context: context,
        message: '내보낼 커스텀 모델이 없습니다',
      );
      return;
    }

    try {
      final exportData = providers.map((cp) {
        final childModels = models
            .where((m) => m.providerId == cp.id)
            .map((m) => {
                  'displayName': m.displayName,
                  'modelId': m.modelId,
                  'pricing': m.pricing.toJson(),
                })
            .toList();
        return {
          'name': cp.name,
          'baseUrl': cp.baseUrl,
          'apiKey': cp.apiKey,
          'apiFormat': cp.apiFormat.name,
          'retryCount': cp.retryCount,
          'models': childModels,
        };
      }).toList();

      final jsonString =
          const JsonEncoder.withIndent('  ').convert(exportData);
      const fileName = 'custom_models.json';

      if (Platform.isAndroid) {
        const platform = MethodChannel('com.flanapp.flan/file_saver');
        final result = await platform.invokeMethod('saveToDownloads', {
          'fileName': fileName,
          'content': jsonString,
        });

        if (context.mounted) {
          CommonDialog.showSnackBar(
            context: context,
            message: result == true
                ? 'Download/$fileName에 저장되었습니다'
                : '저장에 실패했습니다',
          );
        }
      } else if (Platform.isIOS) {
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/$fileName';
        final file = File(filePath);
        await file.writeAsString(jsonString);

        if (context.mounted) {
          CommonDialog.showSnackBar(
            context: context,
            message: '$filePath에 저장되었습니다',
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        CommonDialog.showSnackBar(
          context: context,
          message: '내보내기 실패: $e',
        );
      }
    }
  }

  Future<void> _importFromJson(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null || result.files.single.path == null) return;

      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();
      final List<dynamic> importData = jsonDecode(jsonString);

      final provider = context.read<ChatModelSettingsProvider>();
      int providerCount = 0;
      int modelCount = 0;

      for (final entry in importData) {
        final map = entry as Map<String, dynamic>;
        final cp = CustomProvider(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          name: map['name'] as String,
          baseUrl: map['baseUrl'] as String? ?? '',
          apiKey: map['apiKey'] as String? ?? '',
          apiFormat: ApiFormat.values.firstWhere(
            (f) => f.name == map['apiFormat'],
            orElse: () => ApiFormat.openai,
          ),
          retryCount: map['retryCount'] as int? ?? 0,
        );
        await provider.addCustomProvider(cp);
        providerCount++;

        final models = map['models'] as List<dynamic>? ?? [];
        for (final mEntry in models) {
          final mMap = mEntry as Map<String, dynamic>;
          final model = CustomModel(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            displayName: mMap['displayName'] as String,
            modelId: mMap['modelId'] as String,
            providerId: cp.id,
            pricing: mMap['pricing'] != null
                ? ModelPricing.fromJson(
                    mMap['pricing'] as Map<String, dynamic>)
                : const ModelPricing.zero(),
          );
          await provider.addCustomModel(model);
          modelCount++;
        }
      }

      if (context.mounted) {
        CommonDialog.showSnackBar(
          context: context,
          message: '제조사 $providerCount개, 모델 $modelCount개를 가져왔습니다',
        );
      }
    } catch (e) {
      if (context.mounted) {
        CommonDialog.showSnackBar(
          context: context,
          message: '가져오기 실패: $e',
        );
      }
    }
  }
}

class _ProviderCard extends StatelessWidget {
  final CustomProvider provider;
  final List<CustomModel> models;
  final VoidCallback onEditProvider;
  final VoidCallback onDeleteProvider;
  final VoidCallback onAddModel;
  final void Function(CustomModel) onEditModel;
  final void Function(CustomModel) onDeleteModel;

  const _ProviderCard({
    required this.provider,
    required this.models,
    required this.onEditProvider,
    required this.onDeleteProvider,
    required this.onAddModel,
    required this.onEditModel,
    required this.onDeleteModel,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Provider header
          ListTile(
            leading: Icon(Icons.dns_outlined, color: colorScheme.primary),
            title: Text(provider.name),
            subtitle: Text(
              '${provider.apiFormat.displayName} · ${models.length}개 모델',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: onEditProvider,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: onDeleteProvider,
                ),
              ],
            ),
          ),
          // Model list
          if (models.isNotEmpty)
            ...models.map((model) => ListTile(
                  contentPadding: const EdgeInsets.only(left: 56, right: 16),
                  dense: true,
                  title: Text(model.displayName),
                  subtitle: Text(
                    model.modelId,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        onPressed: () => onEditModel(model),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18),
                        onPressed: () => onDeleteModel(model),
                      ),
                    ],
                  ),
                )),
          // Add model button
          Padding(
            padding: const EdgeInsets.fromLTRB(56, 0, 16, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onAddModel,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('모델 추가'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Provider Editor ──

class _CustomProviderEditorScreen extends StatefulWidget {
  final CustomProvider? provider;

  const _CustomProviderEditorScreen({this.provider});

  @override
  State<_CustomProviderEditorScreen> createState() =>
      _CustomProviderEditorScreenState();
}

class _CustomProviderEditorScreenState
    extends State<_CustomProviderEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _baseUrlController;
  late TextEditingController _apiKeyController;
  late TextEditingController _retryCountController;
  ApiFormat _apiFormat = ApiFormat.openai;

  bool get _isEditing => widget.provider != null;

  @override
  void initState() {
    super.initState();
    final p = widget.provider;
    _nameController = TextEditingController(text: p?.name ?? '');
    _baseUrlController = TextEditingController(text: p?.baseUrl ?? '');
    _apiKeyController = TextEditingController(text: p?.apiKey ?? '');
    _retryCountController = TextEditingController(
      text: p != null && p.retryCount > 0 ? p.retryCount.toString() : '',
    );
    _apiFormat = p?.apiFormat ?? ApiFormat.openai;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _baseUrlController.dispose();
    _apiKeyController.dispose();
    _retryCountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final settingsProvider = context.read<ChatModelSettingsProvider>();

    final retryCount =
        int.tryParse(_retryCountController.text.trim()) ?? 0;

    final provider = CustomProvider(
      id: widget.provider?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      baseUrl: _baseUrlController.text.trim(),
      apiKey: _apiKeyController.text.trim(),
      apiFormat: _apiFormat,
      retryCount: retryCount,
    );

    if (_isEditing) {
      await settingsProvider.updateCustomProvider(provider);
    } else {
      await settingsProvider.addCustomProvider(provider);
    }

    if (mounted) {
      CommonDialog.showSnackBar(
        context: context,
        message: _isEditing ? '제조사가 수정되었습니다' : '제조사가 추가되었습니다',
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: _isEditing ? '제조사 수정' : '제조사 추가',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CommonCustomTextField(
                controller: _nameController,
                label: '제조사 이름',
                hintText: '예: OpenRouter',
                maxLines: 1,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '제조사 이름을 입력해주세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CommonCustomTextField(
                controller: _baseUrlController,
                label: 'Base URL',
                hintText: '예: https://openrouter.ai/api',
                maxLines: 1,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Base URL을 입력해주세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CommonCustomTextField(
                controller: _apiKeyController,
                label: 'API Key',
                hintText: 'sk-...',
                maxLines: 1,
                obscureText: true,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'API Key를 입력해주세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              const CommonTitleMedium(text: 'API 포맷'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [ApiFormat.openai, ApiFormat.claude].map((format) {
                  return CommonFilterChip(
                    label: format.displayName,
                    selected: _apiFormat == format,
                    onSelected: (selected) {
                      if (selected) setState(() => _apiFormat = format);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              const CommonTitleMedium(text: '실패 시 재전송'),
              const SizedBox(height: 4),
              Text(
                'API 호출 실패 시 자동으로 재시도할 횟수 (0 = 재시도 안 함)',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 120,
                child: CommonCustomTextField(
                  controller: _retryCountController,
                  label: '재전송 횟수',
                  hintText: '0',
                  maxLines: 1,
                ),
              ),
              const SizedBox(height: 32),
              CommonButton.filled(
                onPressed: _save,
                icon: Icons.save,
                label: _isEditing ? '수정' : '추가',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Model Editor ──

class _CustomModelEditorScreen extends StatefulWidget {
  final String providerId;
  final CustomModel? model;

  const _CustomModelEditorScreen({
    required this.providerId,
    this.model,
  });

  @override
  State<_CustomModelEditorScreen> createState() =>
      _CustomModelEditorScreenState();
}

class _CustomModelEditorScreenState extends State<_CustomModelEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _modelIdController;
  late TextEditingController _inputPriceController;
  late TextEditingController _outputPriceController;
  late TextEditingController _cachedInputPriceController;

  bool get _isEditing => widget.model != null;

  @override
  void initState() {
    super.initState();
    final model = widget.model;
    _nameController = TextEditingController(text: model?.displayName ?? '');
    _modelIdController = TextEditingController(text: model?.modelId ?? '');
    _inputPriceController = TextEditingController(
      text: model != null && model.pricing.inputPrice > 0
          ? model.pricing.inputPrice.toString()
          : '',
    );
    _outputPriceController = TextEditingController(
      text: model != null && model.pricing.outputPrice > 0
          ? model.pricing.outputPrice.toString()
          : '',
    );
    _cachedInputPriceController = TextEditingController(
      text: model != null && model.pricing.cachedInputPrice > 0
          ? model.pricing.cachedInputPrice.toString()
          : '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _modelIdController.dispose();
    _inputPriceController.dispose();
    _outputPriceController.dispose();
    _cachedInputPriceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<ChatModelSettingsProvider>();

    final inputPrice =
        double.tryParse(_inputPriceController.text.trim()) ?? 0;
    final outputPrice =
        double.tryParse(_outputPriceController.text.trim()) ?? 0;
    final cachedInputPrice =
        double.tryParse(_cachedInputPriceController.text.trim()) ?? 0;
    final model = CustomModel(
      id: widget.model?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      displayName: _nameController.text.trim(),
      modelId: _modelIdController.text.trim(),
      providerId: widget.providerId,
      pricing: ModelPricing(
        inputPrice: inputPrice,
        outputPrice: outputPrice,
        cachedInputPrice: cachedInputPrice,
      ),
    );

    if (_isEditing) {
      await provider.updateCustomModel(model);
    } else {
      await provider.addCustomModel(model);
    }

    if (mounted) {
      CommonDialog.showSnackBar(
        context: context,
        message: _isEditing ? '모델이 수정되었습니다' : '모델이 추가되었습니다',
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: _isEditing ? '모델 수정' : '모델 추가',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CommonCustomTextField(
                controller: _nameController,
                label: '모델 이름',
                hintText: '예: GPT-4o',
                maxLines: 1,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '모델 이름을 입력해주세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CommonCustomTextField(
                controller: _modelIdController,
                label: '모델 ID',
                helpText: 'API 요청에 사용되는 모델 식별자',
                hintText: '예: openai/gpt-4o',
                maxLines: 1,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '모델 ID를 입력해주세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              const CommonTitleMedium(text: '가격 (선택)'),
              const SizedBox(height: 4),
              Text(
                '1M 토큰당 USD',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: CommonCustomTextField(
                      controller: _inputPriceController,
                      label: 'Input',
                      hintText: '0.00',
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CommonCustomTextField(
                      controller: _outputPriceController,
                      label: 'Output',
                      hintText: '0.00',
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CommonCustomTextField(
                      controller: _cachedInputPriceController,
                      label: 'Cached',
                      hintText: '0.00',
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              CommonButton.filled(
                onPressed: _save,
                icon: Icons.save,
                label: _isEditing ? '수정' : '추가',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
