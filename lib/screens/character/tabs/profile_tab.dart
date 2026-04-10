import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/common/common_custom_text_field.dart';
import '../../../constants/ui_constants.dart';

class ProfileTab extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController nicknameController;
  final TextEditingController creatorNotesController;
  final TextEditingController keywordsController;

  const ProfileTab({
    super.key,
    required this.formKey,
    required this.nameController,
    required this.nicknameController,
    required this.creatorNotesController,
    required this.keywordsController,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.all(UIConstants.spacing20),
        children: [
          CommonCustomTextField(
            controller: nameController,
            label: l10n.profileTabLabelName,
            helpText: l10n.profileTabNameHelp,
            hintText: l10n.profileTabNameHint,
            maxLines: null,
            showCounter: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return l10n.profileTabNameValidation;
              }
              return null;
            },
          ),
          const SizedBox(height: UIConstants.spacing20),
          CommonCustomTextField(
            controller: nicknameController,
            label: l10n.profileTabLabelNickname,
            helpText: l10n.profileTabNicknameHelp,
            hintText: l10n.profileTabNicknameHint,
            maxLines: null,
            showCounter: true,
          ),
          const SizedBox(height: UIConstants.spacing20),
          CommonCustomTextField(
            controller: creatorNotesController,
            label: l10n.profileTabLabelCreatorNotes,
            helpText: l10n.profileTabCreatorNotesHelp,
            hintText: l10n.profileTabCreatorNotesHint,
            maxLines: null,
            showCounter: true,
          ),
          const SizedBox(height: UIConstants.spacing20),
          CommonCustomTextField(
            controller: keywordsController,
            label: l10n.profileTabLabelKeywords,
            helpText: l10n.profileTabKeywordsHelp,
            hintText: l10n.profileTabKeywordsHint,
            maxLines: null,
            showCounter: true,
          ),
        ],
      ),
    );
  }
}
