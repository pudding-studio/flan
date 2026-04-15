import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/character/character.dart';
import '../../../models/character/cover_image.dart';
import '../../../models/character/persona.dart';
import '../../../models/character/start_scenario.dart';
import '../../../widgets/character/character_tag_chip.dart';
import '../../../widgets/common/common_button.dart';
import '../../../widgets/common/common_dropdown_button.dart';
import '../../../widgets/common/common_title_medium.dart';

class CharacterInfoTab extends StatefulWidget {
  final Character character;
  final List<CoverImage> coverImages;
  final List<Persona> personas;
  final List<StartScenario> startScenarios;
  final int? selectedPersonaIndex;
  final int? selectedScenarioIndex;
  final ValueChanged<int?> onPersonaIndexChanged;
  final ValueChanged<int?> onScenarioIndexChanged;
  final VoidCallback onNewChat;

  const CharacterInfoTab({
    super.key,
    required this.character,
    required this.coverImages,
    required this.personas,
    required this.startScenarios,
    this.selectedPersonaIndex,
    this.selectedScenarioIndex,
    required this.onPersonaIndexChanged,
    required this.onScenarioIndexChanged,
    required this.onNewChat,
  });

  @override
  State<CharacterInfoTab> createState() => _CharacterInfoTabState();
}

class _CharacterInfoTabState extends State<CharacterInfoTab> {
  String _replaceStartTextKeywords(String text) {
    final keywords = {
      'char': widget.character.name,
      'user': '',
    };
    var result = text;
    for (final entry in keywords.entries) {
      result = result.replaceAll('{{${entry.key}}}', entry.value);
    }
    return result;
  }

  Widget _buildCoverImage() {
    CoverImage? selectedCover;

    if (widget.character.selectedCoverImageId != null && widget.coverImages.isNotEmpty) {
      selectedCover = widget.coverImages.firstWhere(
        (img) => img.id == widget.character.selectedCoverImageId,
        orElse: () => widget.coverImages.first,
      );
    } else if (widget.coverImages.isNotEmpty) {
      selectedCover = widget.coverImages.first;
    }

    final fallback = AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          Icons.person_outline,
          size: 80,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );

    if (selectedCover == null) return fallback;

    return FutureBuilder<Uint8List?>(
      future: selectedCover.resolveImageData(),
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        if (bytes == null) return fallback;
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: 1,
            child: Image.memory(
              bytes,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.broken_image_outlined,
                    size: 80,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildPersonaDropdown() {
    return CommonDropdownButton<int>(
      value: widget.selectedPersonaIndex,
      items: List.generate(widget.personas.length, (index) => index),
      onChanged: widget.onPersonaIndexChanged,
      labelBuilder: (index) => widget.personas[index].name,
    );
  }

  Widget _buildSelectedPersonaContent() {
    if (widget.selectedPersonaIndex == null) {
      return const SizedBox();
    }

    final persona = widget.personas[widget.selectedPersonaIndex!];

    if (persona.content == null || persona.content!.isEmpty) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          persona.content!,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  Widget _buildStartScenarioDropdown() {
    return CommonDropdownButton<int>(
      value: widget.selectedScenarioIndex,
      items: List.generate(widget.startScenarios.length, (index) => index),
      onChanged: widget.onScenarioIndexChanged,
      labelBuilder: (index) => widget.startScenarios[index].name,
    );
  }

  Widget _buildSelectedScenarioContent() {
    if (widget.selectedScenarioIndex == null) {
      return const SizedBox();
    }

    final scenario = widget.startScenarios[widget.selectedScenarioIndex!];

    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        if (scenario.startSetting != null && scenario.startSetting!.isNotEmpty) ...[
          CommonTitleMedium(text: l10n.characterViewStartContext),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _replaceStartTextKeywords(scenario.startSetting!),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (scenario.startMessage != null && scenario.startMessage!.isNotEmpty) ...[
          CommonTitleMedium(text: l10n.characterViewStartMessage),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _replaceStartTextKeywords(scenario.startMessage!),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final keywords = widget.character.tags;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildCoverImage(),
              const SizedBox(height: 24),

              if (widget.character.creatorNotes != null && widget.character.creatorNotes!.isNotEmpty) ...[
                CommonTitleMedium(text: l10n.characterViewTagline),
                const SizedBox(height: 8),
                Text(
                  widget.character.creatorNotes!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 24),
              ],

              if (keywords.isNotEmpty) ...[
                CommonTitleMedium(text: l10n.characterViewKeywords),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: keywords.map((keyword) => CharacterTagChip(label: keyword)).toList(),
                ),
                const SizedBox(height: 24),
              ],

              if (widget.personas.isNotEmpty) ...[
                CommonTitleMedium(text: l10n.characterViewPersona),
                const SizedBox(height: 8),
                _buildPersonaDropdown(),
                _buildSelectedPersonaContent(),
                const SizedBox(height: 24),
              ],

              if (widget.startScenarios.isNotEmpty) ...[
                CommonTitleMedium(text: l10n.characterViewStartSetting),
                const SizedBox(height: 8),
                _buildStartScenarioDropdown(),
                _buildSelectedScenarioContent(),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: CommonButton.filled(
              onPressed: widget.onNewChat,
              icon: Icons.chat_bubble_outline,
              label: l10n.characterViewNewChat,
            ),
          ),
        ),
      ],
    );
  }
}
