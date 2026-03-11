import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/database_helper.dart';
import '../models/prompt/chat_prompt.dart';
import '../models/character/character.dart';
import '../models/character/persona.dart';
import '../models/character/start_scenario.dart';
import '../models/character/character_book_folder.dart';

class DefaultSeederService {
  static const String _chatPromptsSeededKey = 'defaults_chat_prompts_seeded_v4';
  static const String _charactersSeededKey = 'defaults_characters_seeded_v1';

  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<void> seedAllDefaults() async {
    await seedDefaultChatPrompts();
    await seedDefaultCharacters();
  }

  Future<void> seedDefaultChatPrompts() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_chatPromptsSeededKey) == true) return;

    // Check if user already has a non-default prompt selected
    final selectedPrompt = await _db.readSelectedChatPrompt();
    final hasUserSelection = selectedPrompt != null && !selectedPrompt.isDefault;

    // Delete old defaults on version upgrade, then re-seed
    if (await _db.hasDefaultChatPrompts()) {
      await _db.deleteDefaultChatPrompts();
    }

    final assetPaths = await _listAssets('assets/defaults/chat_prompts');

    for (final assetPath in assetPaths) {
      final jsonString = await rootBundle.loadString(assetPath);
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      final isDefaultSelected =
          !hasUserSelection && assetPath.contains('[Gemini] Flan');
      await _seedSingleChatPrompt(jsonData, isDefaultSelected);
    }

    await prefs.setBool(_chatPromptsSeededKey, true);
  }

  Future<void> _seedSingleChatPrompt(
    Map<String, dynamic> jsonData,
    bool autoSelect,
  ) async {
    final prompt = ChatPrompt.fromJson(jsonData).copyWith(
      isDefault: true,
      isSelected: autoSelect,
    );
    final promptId = await _db.createChatPrompt(prompt);

    if (jsonData.containsKey('folders')) {
      final folders = prompt.foldersFromJson(jsonData);
      for (final folder in folders) {
        final folderId = await _db.createPromptItemFolder(
          folder.copyWith(id: null, chatPromptId: promptId),
        );
        for (int i = 0; i < folder.items.length; i++) {
          await _db.createPromptItem(
            folder.items[i].copyWithNullableFolderId(
              id: null,
              chatPromptId: promptId,
              folderId: folderId,
              order: i,
            ),
          );
        }
      }

      final standaloneItems = prompt.standaloneItemsFromJson(jsonData);
      for (int i = 0; i < standaloneItems.length; i++) {
        await _db.createPromptItem(
          standaloneItems[i].copyWithNullableFolderId(
            id: null,
            chatPromptId: promptId,
            folderId: null,
            order: i,
          ),
        );
      }
    }

    // Seed conditions
    final conditions = prompt.conditionsFromJson(jsonData);
    final conditionIdMap = <int, int>{};
    for (int i = 0; i < conditions.length; i++) {
      final oldId = conditions[i].id;
      final newConditionId = await _db.createPromptCondition(
        conditions[i].copyWith(id: null, chatPromptId: promptId, order: i),
      );
      if (oldId != null) conditionIdMap[oldId] = newConditionId;
      for (int j = 0; j < conditions[i].options.length; j++) {
        await _db.createPromptConditionOption(
          conditions[i].options[j].copyWith(
            id: null,
            conditionId: newConditionId,
            order: j,
          ),
        );
      }
    }

    // Seed condition presets
    final conditionPresets = prompt.conditionPresetsFromJson(jsonData);
    for (int i = 0; i < conditionPresets.length; i++) {
      final newPresetId = await _db.createPromptConditionPreset(
        conditionPresets[i].copyWith(id: null, chatPromptId: promptId, order: i),
      );
      for (final value in conditionPresets[i].values) {
        final remappedConditionId = value.conditionId != null
            ? conditionIdMap[value.conditionId!]
            : null;
        await _db.createPromptConditionPresetValue(
          value.copyWith(
            id: null,
            presetId: newPresetId,
            conditionId: remappedConditionId,
          ),
        );
      }
    }
  }

  Future<void> seedDefaultCharacters() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_charactersSeededKey) == true) return;

    final assetPaths = await _listAssets('assets/defaults/characters');

    for (final assetPath in assetPaths) {
      final jsonString = await rootBundle.loadString(assetPath);
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      await _seedSingleCharacter(jsonData);
    }

    await prefs.setBool(_charactersSeededKey, true);
  }

  Future<void> _seedSingleCharacter(Map<String, dynamic> jsonData) async {
    final character = Character.fromJson(jsonData);
    final characterId = await _db.createCharacter(character);

    final personas = (jsonData['personas'] as List?)
        ?.map((p) => Persona.fromJson(p as Map<String, dynamic>))
        .toList();
    if (personas != null) {
      for (final persona in personas) {
        await _db.createPersona(persona.copyWith(characterId: characterId));
      }
    }

    final startScenarios = (jsonData['startScenarios'] as List?)
        ?.map((s) => StartScenario.fromJson(s as Map<String, dynamic>))
        .toList();
    if (startScenarios != null) {
      for (final scenario in startScenarios) {
        await _db.createStartScenario(
          scenario.copyWith(characterId: characterId),
        );
      }
    }

    final characterBookFolders = (jsonData['characterBookFolders'] as List?)
        ?.map((f) => CharacterBookFolder.fromJson(f as Map<String, dynamic>))
        .toList();
    if (characterBookFolders != null) {
      for (final folder in characterBookFolders) {
        final folderId = await _db.createCharacterBookFolder(
          folder.copyWith(characterId: characterId),
        );
        for (final book in folder.characterBooks) {
          await _db.createCharacterBook(
            book.copyWith(characterId: characterId, folderId: folderId),
          );
        }
      }
    }

    final standaloneBooks = (jsonData['standaloneCharacterBooks'] as List?)
        ?.map((l) => CharacterBook.fromJson(l as Map<String, dynamic>))
        .toList();
    if (standaloneBooks != null) {
      for (final book in standaloneBooks) {
        await _db.createCharacterBook(
          book.copyWith(characterId: characterId),
        );
      }
    }
  }

  Future<List<String>> _listAssets(String directory) async {
    final manifestContent = await rootBundle.loadString('AssetManifest.json');
    final Map<String, dynamic> manifest = jsonDecode(manifestContent);
    return manifest.keys
        .where((key) => key.startsWith(directory) && key.endsWith('.json'))
        .toList();
  }
}
