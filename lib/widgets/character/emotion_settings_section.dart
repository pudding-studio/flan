import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/character/emotion_mode.dart';
import '../common/common_dropdown_button.dart';
import '../common/common_edit_text.dart';

/// How a character's emotion image is picked, plus the instruction text
/// the picking step uses (RisuAI `viewScreen` / `inlayViewScreen`).
class EmotionSettingsSection extends StatefulWidget {
  final EmotionMode mode;
  final String? instructions;
  final ValueChanged<EmotionMode> onModeChanged;

  /// Called with null when the text is cleared, so the default applies.
  final ValueChanged<String?> onInstructionsChanged;

  const EmotionSettingsSection({
    super.key,
    required this.mode,
    required this.instructions,
    required this.onModeChanged,
    required this.onInstructionsChanged,
  });

  @override
  State<EmotionSettingsSection> createState() => _EmotionSettingsSectionState();
}

class _EmotionSettingsSectionState extends State<EmotionSettingsSection> {
  late final TextEditingController _instructionsController =
      TextEditingController(text: widget.instructions ?? '');

  @override
  void didUpdateWidget(EmotionSettingsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    final text = widget.instructions ?? '';
    if (oldWidget.instructions != widget.instructions &&
        _instructionsController.text != text) {
      _instructionsController.text = text;
    }
  }

  @override
  void dispose() {
    _instructionsController.dispose();
    super.dispose();
  }

  String _modeLabel(AppLocalizations l10n, EmotionMode mode) => switch (mode) {
        EmotionMode.none => l10n.emotionModeNone,
        EmotionMode.classifier => l10n.emotionModeClassifier,
        EmotionMode.inline => l10n.emotionModeInline,
      };

  String _modeHelp(AppLocalizations l10n, EmotionMode mode) => switch (mode) {
        EmotionMode.none => l10n.emotionModeNoneHelp,
        EmotionMode.classifier => l10n.emotionModeClassifierHelp,
        EmotionMode.inline => l10n.emotionModeInlineHelp,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final helpStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        );
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CommonDropdownButton<EmotionMode>(
            value: widget.mode,
            items: EmotionMode.values,
            size: CommonDropdownButtonSize.xsmall,
            onChanged: (mode) {
              if (mode != null) widget.onModeChanged(mode);
            },
            labelBuilder: (mode) => _modeLabel(l10n, mode),
          ),
          const SizedBox(height: 4),
          Text(_modeHelp(l10n, widget.mode), style: helpStyle),
          if (widget.mode != EmotionMode.none) ...[
            const SizedBox(height: 8),
            CommonEditText(
              controller: _instructionsController,
              size: CommonEditTextSize.small,
              hintText: widget.mode.defaultInstructions,
              minLines: 2,
              maxLines: 4,
              onFocusLost: (value) {
                final trimmed = value.trim();
                widget.onInstructionsChanged(trimmed.isEmpty ? null : trimmed);
              },
            ),
            const SizedBox(height: 2),
            Text(l10n.emotionInstructionsHelp, style: helpStyle),
          ],
        ],
      ),
    );
  }
}
