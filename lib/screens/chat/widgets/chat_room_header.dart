import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/character/character.dart';
import '../../../models/character/persona.dart';
import '../../../models/character/start_scenario.dart';
import '../../../widgets/common/common_settings.dart';

/// Top-of-list header rendered above the first message in the chat room.
///
/// Composed of:
///   - A "this is generated content" warning card.
///   - The optional start scenario "setting" info card.
///   - The optional start scenario seed message bubble.
///
/// `{{char}}` and `{{user}}` keywords inside the start scenario texts are
/// replaced with the character name and the selected persona's name.
class ChatRoomHeader extends StatelessWidget {
  final Character character;
  final Persona? selectedPersona;
  final StartScenario? startScenario;

  const ChatRoomHeader({
    super.key,
    required this.character,
    required this.selectedPersona,
    required this.startScenario,
  });

  String _replaceKeywords(String text) {
    final keywords = {
      'char': character.name,
      'user': selectedPersona?.name ?? '',
    };
    var result = text;
    for (final entry in keywords.entries) {
      result = result.replaceAll('{{${entry.key}}}', entry.value);
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasStartSetting =
        startScenario?.startSetting != null && startScenario!.startSetting!.isNotEmpty;
    final hasStartMessage =
        startScenario?.startMessage != null && startScenario!.startMessage!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CommonSettingsInfoCard(
            icon: Icons.warning_amber_rounded,
            iconColor: Theme.of(context).colorScheme.error,
            title: l10n.chatRoomWarningTitle,
            description: l10n.chatRoomWarningDesc,
          ),
          if (hasStartSetting) ...[
            const SizedBox(height: 12),
            CommonSettingsInfoCard(
              icon: Icons.settings_outlined,
              title: l10n.chatRoomStartSetting,
              description: _replaceKeywords(startScenario!.startSetting!),
            ),
          ],
          if (hasStartMessage) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _replaceKeywords(startScenario!.startMessage!),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
