import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/chat/chat_model.dart';
import '../../models/chat/custom_model.dart';
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
            icon: Icons.add,
            onPressed: () => _openEditor(context, null),
          ),
        ],
      ),
      body: Consumer<ChatModelSettingsProvider>(
        builder: (context, provider, child) {
          final models = provider.customModels;

          if (models.isEmpty) {
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
                    '커스텀 모델이 없습니다',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'OpenRouter, 로컬 LLM 등의 모델을 추가하세요',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 24),
                  CommonButton.filled(
                    onPressed: () => _openEditor(context, null),
                    icon: Icons.add,
                    label: '모델 추가',
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: models.length,
            itemBuilder: (context, index) {
              final model = models[index];
              return Card(
                child: ListTile(
                  title: Text(model.displayName),
                  subtitle: Text(
                    '${model.apiFormat.displayName} · ${model.modelId}',
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        onPressed: () => _openEditor(context, model),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: () => _deleteModel(context, provider, model),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _openEditor(BuildContext context, CustomModel? model) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _CustomModelEditorScreen(model: model),
      ),
    );
  }

  Future<void> _deleteModel(
    BuildContext context,
    ChatModelSettingsProvider provider,
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
      await provider.deleteCustomModel(model.id);
    }
  }
}

class _CustomModelEditorScreen extends StatefulWidget {
  final CustomModel? model;

  const _CustomModelEditorScreen({this.model});

  @override
  State<_CustomModelEditorScreen> createState() =>
      _CustomModelEditorScreenState();
}

class _CustomModelEditorScreenState extends State<_CustomModelEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _modelIdController;
  late TextEditingController _baseUrlController;
  late TextEditingController _apiKeyController;
  ApiFormat _apiFormat = ApiFormat.openai;
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
    _baseUrlController = TextEditingController(text: model?.baseUrl ?? '');
    _apiKeyController = TextEditingController(text: model?.apiKey ?? '');
    _apiFormat = model?.apiFormat ?? ApiFormat.openai;
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
    _baseUrlController.dispose();
    _apiKeyController.dispose();
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
      apiFormat: _apiFormat,
      baseUrl: _baseUrlController.text.trim(),
      apiKey: _apiKeyController.text.trim(),
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
                hintText: '예: GPT-4o via OpenRouter',
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
