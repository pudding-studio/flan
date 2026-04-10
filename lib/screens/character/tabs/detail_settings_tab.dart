import 'package:flutter/material.dart';
import '../../../constants/ui_constants.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/common/common_edit_text.dart';
import '../../../widgets/common/common_title_medium.dart';

class DetailSettingsTab extends StatelessWidget {
  final TextEditingController descriptionController;

  const DetailSettingsTab({
    super.key,
    required this.descriptionController,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
                CommonTitleMedium(
                  text: l10n.detailSettingsTitle,
                  helpMessage: l10n.detailSettingsTitleHelp,
                ),
                const Spacer(),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: descriptionController,
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
            child: CommonEditText(
              controller: descriptionController,
              hintText: l10n.detailSettingsHint,
              size: CommonEditTextSize.medium,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
            ),
          ),
        ],
      ),
    );
  }
}
