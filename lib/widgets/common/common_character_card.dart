import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/metadata_parser.dart';

class CommonCharacterCard extends StatelessWidget {
  final CharacterTag tag;
  final double? fontSize;

  const CommonCharacterCard({super.key, required this.tag, this.fontSize});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accentColor = tag.isMain ? colorScheme.primary : colorScheme.tertiary;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accentColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tag.name,
            style: TextStyle(
              fontSize: fontSize ?? 16,
              fontWeight: FontWeight.bold,
              color: accentColor,
            ),
          ),
          if (tag.outfit != null) ...[
            const SizedBox(height: 2),
            Text.rich(
              TextSpan(children: [
                TextSpan(
                  text: AppLocalizations.of(context).characterCardOutfitLabel,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface),
                ),
                TextSpan(
                  text: tag.outfit,
                  style: TextStyle(fontSize: 12, color: colorScheme.onSurface),
                ),
              ]),
            ),
          ],
          if (tag.memo != null) ...[
            const SizedBox(height: 2),
            Text.rich(
              TextSpan(children: [
                TextSpan(
                  text: AppLocalizations.of(context).characterCardMemoLabel,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface),
                ),
                TextSpan(
                  text: tag.memo,
                  style: TextStyle(fontSize: 12, color: colorScheme.onSurface),
                ),
              ]),
            ),
          ],
        ],
      ),
    );
  }
}
