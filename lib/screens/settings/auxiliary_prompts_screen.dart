import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/prompt/auxiliary_prompt.dart';
import '../../services/auxiliary_prompt_service.dart';
import '../../utils/common_dialog.dart';
import '../../widgets/common/common_appbar.dart';
import 'auto_summary_screen.dart';
import 'auxiliary_prompt_edit_screen.dart';
import 'auxiliary_multi_prompt_edit_screen.dart';

class AuxiliaryPromptsScreen extends StatelessWidget {
  const AuxiliaryPromptsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: CommonAppBar(
        title: l10n.settingsAuxiliaryPrompts,
        actions: [
          IconButton(
            tooltip: l10n.auxResetAllTitle,
            icon: const Icon(Icons.restart_alt),
            onPressed: () => _resetAll(context),
          ),
        ],
      ),
      body: ListView(
        children: [
          _sectionHeader(context, l10n.auxSectionCharacter),
          _navTile(
            context: context,
            icon: Icons.smart_toy_outlined,
            title: l10n.auxPromptFlanAgentTitle,
            subtitle: l10n.auxPromptFlanAgentSubtitle,
            onTap: () => _openSingle(
              context,
              key: AuxiliaryPromptKey.flanAgentSystem,
              title: l10n.auxPromptFlanAgentTitle,
            ),
          ),
          const Divider(height: 1),

          _sectionHeader(context, l10n.auxSectionPromptManagement),
          _navTile(
            context: context,
            icon: Icons.translate,
            title: l10n.auxPromptChatTranslationTitle,
            subtitle: l10n.auxPromptChatTranslationSubtitle,
            onTap: () => _openSingle(
              context,
              key: AuxiliaryPromptKey.chatTranslation,
              title: l10n.auxPromptChatTranslationTitle,
            ),
          ),
          const Divider(height: 1),

          _sectionHeader(context, l10n.auxSectionAutoSummary),
          _navTile(
            context: context,
            icon: Icons.auto_awesome,
            title: l10n.auxPromptDefaultSummaryTitle,
            subtitle: l10n.auxPromptDefaultSummarySubtitle,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AutoSummaryScreen(chatRoomId: 0),
              ),
            ),
          ),
          _navTile(
            context: context,
            icon: Icons.hub_outlined,
            title: l10n.auxPromptAgentSummaryTitle,
            subtitle: l10n.auxPromptAgentSummarySubtitle,
            onTap: () => _openSingle(
              context,
              key: AuxiliaryPromptKey.agentSummary,
              title: l10n.auxPromptAgentSummaryTitle,
            ),
          ),
          const Divider(height: 1),

          _sectionHeader(context, l10n.auxSectionChatContent),
          _navTile(
            context: context,
            icon: Icons.forum_outlined,
            title: l10n.auxPromptSnsTitle,
            subtitle: l10n.auxPromptSnsSubtitle,
            onTap: () => _openMulti(
              context,
              title: l10n.auxPromptSnsTitle,
              tabs: [
                MultiAuxTab(
                  label: l10n.auxTabSnsGenerate,
                  key: AuxiliaryPromptKey.snsGenerate,
                ),
                MultiAuxTab(
                  label: l10n.auxTabSnsPostReplies,
                  key: AuxiliaryPromptKey.snsPostReplies,
                ),
                MultiAuxTab(
                  label: l10n.auxTabSnsCommentReplies,
                  key: AuxiliaryPromptKey.snsCommentReplies,
                ),
              ],
            ),
          ),
          _navTile(
            context: context,
            icon: Icons.menu_book_outlined,
            title: l10n.auxPromptDiaryTitle,
            subtitle: l10n.auxPromptDiarySubtitle,
            onTap: () => _openSingle(
              context,
              key: AuxiliaryPromptKey.diaryGenerate,
              title: l10n.auxPromptDiaryTitle,
            ),
          ),
          _navTile(
            context: context,
            icon: Icons.newspaper,
            title: l10n.auxPromptNewsTitle,
            subtitle: l10n.auxPromptNewsSubtitle,
            onTap: () => _openMulti(
              context,
              title: l10n.auxPromptNewsTitle,
              tabs: [
                MultiAuxTab(
                  label: l10n.auxTabNewsGenerate,
                  key: AuxiliaryPromptKey.newsGenerate,
                ),
                MultiAuxTab(
                  label: l10n.auxTabNewsEventGenerate,
                  key: AuxiliaryPromptKey.newsEventGenerate,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _resetAll(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final confirm = await CommonDialog.showConfirmation(
      context: context,
      title: l10n.auxResetAllTitle,
      content: l10n.auxResetAllContent,
      confirmText: l10n.auxResetAllTitle,
      isDestructive: true,
    );
    if (confirm != true) return;

    try {
      await AuxiliaryPromptService.instance.resetAllToDefaults();
      if (!context.mounted) return;
      CommonDialog.showSnackBar(
        context: context,
        message: l10n.auxResetAllSuccess,
      );
    } catch (e) {
      if (!context.mounted) return;
      CommonDialog.showSnackBar(
        context: context,
        message: l10n.auxSaveFailed(e.toString()),
      );
    }
  }

  void _openSingle(
    BuildContext context, {
    required AuxiliaryPromptKey key,
    required String title,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AuxiliaryPromptEditScreen(
          promptKey: key,
          title: title,
        ),
      ),
    );
  }

  void _openMulti(
    BuildContext context, {
    required String title,
    required List<MultiAuxTab> tabs,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AuxiliaryMultiPromptEditScreen(
          title: title,
          tabs: tabs,
        ),
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _navTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
