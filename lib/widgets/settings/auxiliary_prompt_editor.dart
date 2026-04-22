import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/prompt/auxiliary_prompt.dart';
import '../../services/auxiliary_prompt_service.dart';
import '../../services/prompt_translation_service.dart';
import '../../utils/common_dialog.dart';

/// Reusable editor body for a single [AuxiliaryPrompt]. Owns its controllers,
/// English toggle, translate / reset / save actions, and loads/persists through
/// [AuxiliaryPromptService]. Both the single and multi-tab edit screens embed
/// this widget — the multi-tab screen mounts one per sub-prompt tab.
class AuxiliaryPromptEditor extends StatefulWidget {
  final AuxiliaryPromptKey promptKey;

  const AuxiliaryPromptEditor({super.key, required this.promptKey});

  @override
  State<AuxiliaryPromptEditor> createState() => _AuxiliaryPromptEditorState();
}

class _AuxiliaryPromptEditorState extends State<AuxiliaryPromptEditor>
    with SingleTickerProviderStateMixin {
  final AuxiliaryPromptService _service = AuxiliaryPromptService.instance;
  final PromptTranslationService _translator = PromptTranslationService();

  late final TabController _tabController;
  final TextEditingController _nativeController = TextEditingController();
  final TextEditingController _englishController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isTranslating = false;
  bool _useEnglish = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nativeController.dispose();
    _englishController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final prompt = await _service.get(widget.promptKey);
    if (!mounted) return;
    setState(() {
      _nativeController.text = prompt.contentNative;
      _englishController.text = prompt.contentEnglish;
      _useEnglish = prompt.useEnglish;
      _isLoading = false;
    });
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _isSaving = true);
    try {
      await _service.upsert(
        key: widget.promptKey,
        contentNative: _nativeController.text,
        contentEnglish: _englishController.text,
        useEnglish: _useEnglish,
      );
      if (!mounted) return;
      CommonDialog.showSnackBar(
        context: context,
        message: l10n.auxSaveSuccess,
      );
    } catch (e) {
      if (!mounted) return;
      CommonDialog.showSnackBar(
        context: context,
        message: l10n.auxSaveFailed(e.toString()),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _translate() async {
    final l10n = AppLocalizations.of(context);
    final native = _nativeController.text;
    if (native.trim().isEmpty) return;

    setState(() => _isTranslating = true);
    try {
      final english = await _translator.translateToEnglish(native);
      if (!mounted) return;
      setState(() {
        _englishController.text = english;
        _tabController.animateTo(1);
      });
      CommonDialog.showSnackBar(
        context: context,
        message: l10n.auxTranslateSuccess,
      );
    } catch (e) {
      if (!mounted) return;
      CommonDialog.showSnackBar(
        context: context,
        message: l10n.auxTranslateFailed(e.toString()),
      );
    } finally {
      if (mounted) setState(() => _isTranslating = false);
    }
  }

  Future<void> _resetToDefaults() async {
    final l10n = AppLocalizations.of(context);
    final confirm = await CommonDialog.showConfirmation(
      context: context,
      title: l10n.auxResetConfirmTitle,
      content: l10n.auxResetConfirmContent,
      confirmText: l10n.auxResetToDefaults,
      isDestructive: true,
    );
    if (confirm != true) return;

    final restored = await _service.resetToDefaults(widget.promptKey);
    if (!mounted) return;
    setState(() {
      _nativeController.text = restored.contentNative;
      _englishController.text = restored.contentEnglish;
      _useEnglish = restored.useEnglish;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        _buildToolbar(context, l10n),
        TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.auxLanguageNative),
            Tab(text: l10n.auxLanguageEnglish),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildTextArea(_nativeController),
              _buildTextArea(_englishController),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToolbar(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SwitchListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.auxUseEnglish),
            value: _useEnglish,
            onChanged: (v) => setState(() => _useEnglish = v),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              FilledButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined, size: 18),
                label: Text(l10n.commonSave),
              ),
              OutlinedButton.icon(
                onPressed: _isTranslating ? null : _translate,
                icon: _isTranslating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.translate, size: 18),
                label: Text(
                  _isTranslating
                      ? l10n.auxTranslating
                      : l10n.auxTranslateButton,
                ),
              ),
              TextButton.icon(
                onPressed: _resetToDefaults,
                icon: const Icon(Icons.restart_alt, size: 18),
                label: Text(l10n.auxResetToDefaults),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextArea(TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: TextField(
        controller: controller,
        maxLines: null,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
        keyboardType: TextInputType.multiline,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          alignLabelWithHint: true,
        ),
      ),
    );
  }
}
