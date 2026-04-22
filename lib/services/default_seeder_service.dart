import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/database_helper.dart';
import '../models/prompt/chat_prompt.dart';
import '../models/character/character.dart';
import '../models/character/persona.dart';
import '../models/character/start_scenario.dart';
import '../models/character/character_book_folder.dart';

class DefaultSeederService {
  static const String _seededAppVersionKey = 'defaults_seeded_app_version';

  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<void> seedAllDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
    final seededVersion = prefs.getString(_seededAppVersionKey);

    // Always ensure at least one default chat prompt exists — even if the
    // seeded version matches, a prior failed/partial seed can leave the DB
    // empty, and the app must never run without a default prompt.
    final hasDefaults = await _db.hasDefaultChatPrompts();
    if (seededVersion == currentVersion && hasDefaults) return;

    await seedDefaultChatPrompts();

    // Only persist the seeded-version marker once defaults actually exist.
    // If seeding silently produced zero rows (e.g. missing asset manifest),
    // leave the marker unset so the next launch retries.
    if (await _db.hasDefaultChatPrompts()) {
      await prefs.setString(_seededAppVersionKey, currentVersion);
    }
  }

  Future<void> seedDefaultChatPrompts() async {
    // Check if user already has a non-default prompt selected
    final selectedPrompt = await _db.readSelectedChatPrompt();
    final hasUserSelection = selectedPrompt != null && !selectedPrompt.isDefault;

    // Delete and re-seed defaults
    if (await _db.hasDefaultChatPrompts()) {
      await _db.deleteDefaultChatPrompts();
    }

    // Seed only the locale-matched default prompt (one preset, not four).
    final assetPaths = await _resolveLocalizedChatPromptAssets();

    for (final assetPath in assetPaths) {
      final jsonString = await rootBundle.loadString(assetPath);
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      final isDefaultSelected =
          !hasUserSelection && assetPath.contains('gemini_flan');
      await _seedSingleChatPrompt(jsonData, isDefaultSelected);
    }
  }

  /// Picks the chat-prompt asset that matches the device locale. Each base
  /// preset has _ko / _ja / _en variants and a no-suffix fallback; we prefer
  /// the locale-specific file so the seeded default isn't duplicated and
  /// the UI labels / prompt bodies render in the right language.
  Future<List<String>> _resolveLocalizedChatPromptAssets() async {
    final all = await _listAssets('assets/defaults/chat_prompts');
    if (all.isEmpty) return const [];

    final localeCode = ui.PlatformDispatcher.instance.locale.languageCode;
    final preferredSuffix = switch (localeCode) {
      'ko' => '_ko',
      'ja' => '_ja',
      _ => '_en',
    };

    // Group variants by base (e.g. "gemini_flan").
    final byBase = <String, Map<String, String>>{};
    for (final path in all) {
      final filename = path.split('/').last.replaceAll('.json', '');
      final suffixMatch = RegExp(r'(_ko|_ja|_en)$').firstMatch(filename);
      final base = suffixMatch == null
          ? filename
          : filename.substring(0, suffixMatch.start);
      final suffix = suffixMatch?.group(0) ?? '';
      byBase.putIfAbsent(base, () => {})[suffix] = path;
    }

    final resolved = <String>[];
    for (final variants in byBase.values) {
      final pick = variants[preferredSuffix] ??
          variants['_en'] ??
          variants[''] ??
          variants.values.first;
      resolved.add(pick);
    }
    return resolved;
  }

  Future<void> _seedSingleChatPrompt(
    Map<String, dynamic> jsonData,
    bool autoSelect,
  ) async {
    final prompt = ChatPrompt.fromJson(jsonData).copyWith(
      isDefault: true,
      isSelected: autoSelect,
    );
    await _db.insertChatPromptFromJson(prompt, jsonData);
  }

  Future<void> seedDefaultCharacters() async {
    final existing = await _db.readAllCharacters();
    if (existing.isNotEmpty) return;

    final assetPaths = await _listAssets('assets/defaults/characters');

    for (final assetPath in assetPaths) {
      final jsonString = await rootBundle.loadString(assetPath);
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      await _seedSingleCharacter(jsonData);
    }
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
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    return manifest
        .listAssets()
        .where((key) => key.startsWith(directory) && key.endsWith('.json'))
        .toList();
  }
}
