// The chat room drawer shows every lorebook category with its own fields,
// not just the plain-text body used by '기타' entries.

import 'dart:convert';
import 'dart:io';

import 'package:flan/database/database_helper.dart';
import 'package:flan/l10n/app_localizations.dart';
import 'package:flan/models/character/character.dart';
import 'package:flan/models/character/character_book_folder.dart';
import 'package:flan/screens/chat/widgets/drawer_lorebook_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  final db = DatabaseHelper.instance;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await databaseFactory.setDatabasesPath(
        Directory.systemTemp.createTempSync('flan_db_test').path);
  });

  Future<GlobalKey<DrawerLorebookPanelState>> pumpPanel(
    WidgetTester tester,
    List<CharacterBook> books,
    int characterId,
  ) async {
    tester.view.physicalSize = const Size(800, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final key = GlobalKey<DrawerLorebookPanelState>();
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ko'),
      home: Scaffold(
        body: DrawerLorebookPanel(
          key: key,
          folders: const [],
          standaloneBooks: books,
          db: db,
          characterId: characterId,
        ),
      ),
    ));
    return key;
  }

  testWidgets('character and event entries show their own fields',
      (tester) async {
    final character = CharacterBook(
      id: 1,
      characterId: 1,
      name: 'Alice',
      order: 0,
      category: CharacterBookCategory.character,
      isExpanded: true,
      content: jsonEncode({'appearance': 'silver hair', 'personality': 'calm'}),
    );
    final event = CharacterBook(
      id: 2,
      characterId: 1,
      name: 'Festival',
      order: 1,
      category: CharacterBookCategory.event,
      isExpanded: true,
      content: jsonEncode({'event_content': 'lantern night'}),
    );
    await pumpPanel(tester, [event, character], 1);

    expect(find.text('silver hair'), findsOneWidget);
    expect(find.text('calm'), findsOneWidget);
    expect(find.text('lantern night'), findsOneWidget);
    expect(find.text(CharacterBookCategory.character.displayName),
        findsWidgets);
    expect(find.text(CharacterBookCategory.event.displayName), findsWidgets);
  });

  testWidgets('saving keeps edits made in category fields', (tester) async {
    late int characterId;
    late int bookId;
    await tester.runAsync(() async {
      characterId = await db.createCharacter(Character(name: 'c'));
      bookId = await db.createCharacterBook(CharacterBook(
        characterId: characterId,
        name: 'Alice',
        order: 0,
        category: CharacterBookCategory.character,
        content: jsonEncode({'appearance': 'old', 'past': 'keep me'}),
      ));
    });
    final book = CharacterBook(
      id: bookId,
      characterId: characterId,
      name: 'Alice',
      order: 0,
      category: CharacterBookCategory.character,
      isExpanded: true,
      content: jsonEncode({'appearance': 'old', 'past': 'keep me'}),
    );
    final key = await pumpPanel(tester, [book], characterId);

    // Typed without leaving the field: save() must still pick it up.
    await tester.enterText(find.widgetWithText(TextField, 'old'), 'new look');
    late List<CharacterBook> saved;
    await tester.runAsync(() async {
      await key.currentState!.save();
      saved = await db.readStandaloneCharacterBooks(characterId);
    });

    final data = saved.single.structuredData;
    expect(data['appearance'], 'new look');
    expect(data['past'], 'keep me');
  });
}
