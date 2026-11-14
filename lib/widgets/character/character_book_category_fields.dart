import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/character/character_book_folder.dart';
import '../common/common_edit_text.dart';
import '../common/common_field_section.dart';
import '../common/common_segmented_button.dart';
import 'character_book_images_section.dart';

IconData characterBookCategoryIcon(CharacterBookCategory category) {
  switch (category) {
    case CharacterBookCategory.character:
      return Icons.person_outline;
    case CharacterBookCategory.location:
      return Icons.place_outlined;
    case CharacterBookCategory.event:
      return Icons.event_note_outlined;
    case CharacterBookCategory.other:
      return Icons.description_outlined;
  }
}

/// Editor for the category-specific structured fields of a lorebook entry
/// (appearance/personality for characters, event content for events, ...).
/// Shared by the character editor and the chat room drawer so both always
/// expose the same data the prompt builder sends.
class CharacterBookCategoryFields extends StatelessWidget {
  final CharacterBook book;

  /// Returns the controller for [fieldKey], creating it with [initialValue]
  /// on first use. The owner keeps and disposes the controllers.
  final TextEditingController Function(String fieldKey, String initialValue)
      controllerFor;

  /// Called after every edit. [rebuildUI] is true when the visible field set
  /// may have changed (e.g. a gender selection revealing a text field).
  final void Function({required bool rebuildUI}) onChanged;

  final String characterName;
  final bool imagesReadOnly;

  const CharacterBookCategoryFields({
    super.key,
    required this.book,
    required this.controllerFor,
    required this.onChanged,
    this.characterName = '',
    this.imagesReadOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: switch (book.category) {
        CharacterBookCategory.character => _characterFields(l10n),
        CharacterBookCategory.event => _eventFields(l10n),
        CharacterBookCategory.location ||
        CharacterBookCategory.other =>
          [_settingField(l10n)],
      },
    );
  }

  List<Widget> _characterFields(AppLocalizations l10n) {
    final showImages = !imagesReadOnly || book.images.isNotEmpty;
    return [
      _textField('appearance', l10n.characterBookFieldAppearance, minLines: 2),
      _genderField(l10n),
      _textField('age', l10n.characterBookFieldAge, multiline: false),
      _textField('personality', l10n.characterBookFieldPersonality, minLines: 2),
      _textField('past', l10n.characterBookFieldPast, minLines: 2),
      _textField('abilities', l10n.characterBookFieldAbilities, minLines: 2),
      _textField(
        'dialogue_style',
        l10n.characterBookFieldDialogueStyle,
        minLines: 2,
        bottomSpacing: showImages ? 12 : 0,
      ),
      if (showImages)
        CommonFieldSection(
          label: l10n.characterBookFieldImages,
          bottomSpacing: 0,
          child: CharacterBookImagesSection(
            key: ValueKey('bookImages_${book.id}'),
            images: book.images,
            characterName: characterName,
            readOnly: imagesReadOnly,
            onUpdate: () => onChanged(rebuildUI: false),
          ),
        ),
    ];
  }

  List<Widget> _eventFields(AppLocalizations l10n) {
    return [
      _textField('datetime', l10n.characterBookFieldDatetime, multiline: false),
      _textField('event_content', l10n.characterBookFieldEventContent,
          minLines: 3),
      _textField('result', l10n.characterBookFieldResult,
          minLines: 2, bottomSpacing: 0),
    ];
  }

  Widget _settingField(AppLocalizations l10n) {
    return _textField('setting', l10n.characterBookFieldSetting,
        minLines: 5, bottomSpacing: 0);
  }

  /// All edits flow through [CharacterBook.setStructuredString] so the
  /// underlying JSON stays consistent even for legacy plain-text entries.
  Widget _textField(
    String fieldKey,
    String label, {
    bool multiline = true,
    int minLines = 1,
    double bottomSpacing = 12.0,
  }) {
    final controller =
        controllerFor(fieldKey, book.getStructuredString(fieldKey));
    return CommonFieldSection(
      label: label,
      bottomSpacing: bottomSpacing,
      child: CommonEditText(
        controller: controller,
        size: CommonEditTextSize.small,
        maxLines: multiline ? null : 1,
        minLines: multiline ? minLines : null,
        onFocusLost: (value) {
          book.setStructuredString(fieldKey, value);
          onChanged(rebuildUI: false);
        },
      ),
    );
  }

  Widget _genderField(AppLocalizations l10n) {
    final selectedGender = book.gender;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CommonFieldSection(
          label: l10n.characterBookFieldGender,
          bottomSpacing: selectedGender == CharacterBookGender.other ? 8 : 12,
          child: CommonSegmentedButton<CharacterBookGender>(
            values: CharacterBookGender.values,
            selected: selectedGender ?? CharacterBookGender.male,
            onSelectionChanged: (selected) {
              book.gender = selected;
              onChanged(rebuildUI: true);
            },
            labelBuilder: (g) => g.displayName,
          ),
        ),
        if (selectedGender == CharacterBookGender.other)
          _textField('gender_other', l10n.characterBookFieldGenderOther,
              multiline: false),
      ],
    );
  }
}
