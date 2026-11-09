// Lorebook entries in the prompt: which apply this turn, and their details.

import 'package:flan/models/character/character_book_folder.dart';
import 'package:flan/utils/character_book_lore.dart';
import 'package:flan/utils/prompt_builder.dart';
import 'package:flutter_test/flutter_test.dart';

CharacterBook _book(
  String name,
  CharacterBookActivationCondition enabled, {
  List<String> keys = const [],
  List<String> secondaryKeys = const [],
  bool secondary = false,
  CharacterBookCategory category = CharacterBookCategory.other,
}) {
  final book = CharacterBook(
    characterId: 1,
    name: name,
    order: 0,
    enabled: enabled,
    keys: keys,
    secondaryKeys: secondaryKeys,
    secondaryKeyUsage: secondary
        ? CharacterBookSecondaryKeyUsage.enabled
        : CharacterBookSecondaryKeyUsage.disabled,
    category: category,
    oneLineDescription: '$name line',
  );
  book.setting = '$name setting';
  return book;
}

void main() {
  group('selection', () {
    final books = [
      _book('always', CharacterBookActivationCondition.enabled),
      _book('off', CharacterBookActivationCondition.disabled, keys: ['dragon']),
      _book('dragon', CharacterBookActivationCondition.keyBased,
          keys: ['Dragon', '용']),
      _book('castle', CharacterBookActivationCondition.keyBased,
          keys: ['castle'], secondaryKeys: ['night'], secondary: true),
    ];
    List<String> names(List<String> texts) =>
        selectActiveCharacterBooks(books, texts).map((b) => b.name).toList();

    test('enabled entries always apply, disabled never', () {
      expect(names(['nothing here']), ['always']);
    });

    test('key-based entries apply when a key is mentioned', () {
      expect(names(['A DRAGON appears']), ['always', 'dragon']);
      expect(names(['용이 나타났다']), ['always', 'dragon']);
    });

    test('secondary keys must also match when switched on', () {
      expect(names(['the castle']), ['always']);
      expect(names(['the castle', 'at night']), ['always', 'castle']);
    });
  });

  group('prompt text', () {
    final books = [
      _book('Town', CharacterBookActivationCondition.enabled,
          category: CharacterBookCategory.location),
      _book('Relic', CharacterBookActivationCondition.enabled),
    ];

    test('lists names and adds details where asked', () {
      final text = PromptBuilder.buildCharacterBookText(
        books,
        withDetails: (b) => b.name == 'Relic',
      );
      expect(text, contains('Town|Town line'));
      expect(text, contains('Relic|Relic line'));
      expect(text, contains('[Relic]\nFeatures: Relic setting'));
      expect(text, isNot(contains('Town setting')));
    });

    test('without the option only the index is sent', () {
      final text = PromptBuilder.buildCharacterBookText(books);
      expect(text, isNot(contains('setting')));
    });
  });
}
