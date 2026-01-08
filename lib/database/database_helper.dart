import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/character/character.dart';
import '../models/character/lorebook_folder.dart';
import '../models/character/persona.dart';
import '../models/character/start_scenario.dart';
import '../models/character/cover_image.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('flan.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const intType = 'INTEGER NOT NULL';
    const textType = 'TEXT NOT NULL';
    const textTypeNullable = 'TEXT';
    const boolType = 'INTEGER NOT NULL DEFAULT 0';

    // 캐릭터 테이블
    await db.execute('''
      CREATE TABLE characters (
        id $idType,
        name $textType,
        summary $textTypeNullable,
        keywords $textTypeNullable,
        world_setting $textTypeNullable,
        selected_cover_image_id $textTypeNullable,
        created_at $textType,
        updated_at $textType,
        is_draft $boolType
      )
    ''');

    // 로어북 폴더 테이블
    await db.execute('''
      CREATE TABLE lorebook_folders (
        id $idType,
        character_id $intType,
        name $textType,
        `order` $intType,
        is_expanded $boolType,
        FOREIGN KEY (character_id) REFERENCES characters (id) ON DELETE CASCADE
      )
    ''');

    // 로어북 테이블
    await db.execute('''
      CREATE TABLE lorebooks (
        id $idType,
        character_id $intType,
        folder_id INTEGER,
        name $textType,
        `order` $intType,
        is_expanded $boolType,
        activation_condition $textType,
        activation_keys $textTypeNullable,
        key_condition $textType,
        deployment_order $intType,
        content $textTypeNullable,
        FOREIGN KEY (character_id) REFERENCES characters (id) ON DELETE CASCADE,
        FOREIGN KEY (folder_id) REFERENCES lorebook_folders (id) ON DELETE CASCADE
      )
    ''');

    // 페르소나 테이블
    await db.execute('''
      CREATE TABLE personas (
        id $idType,
        character_id $intType,
        name $textType,
        `order` $intType,
        is_expanded $boolType,
        content $textTypeNullable,
        FOREIGN KEY (character_id) REFERENCES characters (id) ON DELETE CASCADE
      )
    ''');

    // 시작설정 테이블
    await db.execute('''
      CREATE TABLE start_scenarios (
        id $idType,
        character_id $intType,
        name $textType,
        `order` $intType,
        is_expanded $boolType,
        start_setting $textTypeNullable,
        start_message $textTypeNullable,
        FOREIGN KEY (character_id) REFERENCES characters (id) ON DELETE CASCADE
      )
    ''');

    // 표지 이미지 테이블
    await db.execute('''
      CREATE TABLE cover_images (
        id $idType,
        character_id $intType,
        name $textType,
        `order` $intType,
        is_expanded $boolType,
        image_path $textTypeNullable,
        FOREIGN KEY (character_id) REFERENCES characters (id) ON DELETE CASCADE
      )
    ''');

    // 인덱스 생성 (성능 향상)
    await db.execute('''
      CREATE INDEX idx_character_id_lorebook_folders
      ON lorebook_folders (character_id)
    ''');
    await db.execute('''
      CREATE INDEX idx_character_id_lorebooks
      ON lorebooks (character_id)
    ''');
    await db.execute('''
      CREATE INDEX idx_folder_id_lorebooks
      ON lorebooks (folder_id)
    ''');
    await db.execute('''
      CREATE INDEX idx_character_id_personas
      ON personas (character_id)
    ''');
    await db.execute('''
      CREATE INDEX idx_character_id_start_scenarios
      ON start_scenarios (character_id)
    ''');
    await db.execute('''
      CREATE INDEX idx_character_id_cover_images
      ON cover_images (character_id)
    ''');
  }

  // ==================== 캐릭터 CRUD ====================

  Future<int> createCharacter(Character character) async {
    final db = await database;
    final map = character.toMap();
    map.remove('id'); // id는 자동 생성되므로 제거
    return await db.insert('characters', map);
  }

  Future<Character?> readCharacter(int id) async {
    final db = await database;
    final maps = await db.query(
      'characters',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Character.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Character>> readAllCharacters() async {
    final db = await database;
    const orderBy = 'created_at DESC';
    final result = await db.query('characters', orderBy: orderBy);
    return result.map((map) => Character.fromMap(map)).toList();
  }

  Future<List<Character>> readDraftCharacters() async {
    final db = await database;
    final result = await db.query(
      'characters',
      where: 'is_draft = ?',
      whereArgs: [1],
      orderBy: 'updated_at DESC',
    );
    return result.map((map) => Character.fromMap(map)).toList();
  }

  Future<int> updateCharacter(Character character) async {
    final db = await database;
    return await db.update(
      'characters',
      character.toMap(),
      where: 'id = ?',
      whereArgs: [character.id],
    );
  }

  Future<int> deleteCharacter(int id) async {
    final db = await database;
    return await db.delete(
      'characters',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== 로어북 폴더 CRUD ====================

  Future<int> createLorebookFolder(LorebookFolder folder) async {
    final db = await database;
    final map = folder.toMap();
    map.remove('id'); // id는 자동 생성되므로 제거
    return await db.insert('lorebook_folders', map);
  }

  Future<List<LorebookFolder>> readLorebookFolders(int characterId) async {
    final db = await database;
    final result = await db.query(
      'lorebook_folders',
      where: 'character_id = ?',
      whereArgs: [characterId],
      orderBy: '`order` ASC',
    );
    return result.map((map) => LorebookFolder.fromMap(map)).toList();
  }

  Future<int> updateLorebookFolder(LorebookFolder folder) async {
    final db = await database;
    return await db.update(
      'lorebook_folders',
      folder.toMap(),
      where: 'id = ?',
      whereArgs: [folder.id],
    );
  }

  Future<int> deleteLorebookFolder(int id) async {
    final db = await database;
    return await db.delete(
      'lorebook_folders',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== 로어북 CRUD ====================

  Future<int> createLorebook(Lorebook lorebook) async {
    final db = await database;
    final map = lorebook.toMap();
    map.remove('id'); // id는 자동 생성되므로 제거
    return await db.insert('lorebooks', map);
  }

  Future<List<Lorebook>> readLorebooks(int characterId) async {
    final db = await database;
    final result = await db.query(
      'lorebooks',
      where: 'character_id = ?',
      whereArgs: [characterId],
      orderBy: '`order` ASC',
    );
    return result.map((map) => Lorebook.fromMap(map)).toList();
  }

  Future<List<Lorebook>> readLorebooksByFolder(int folderId) async {
    final db = await database;
    final result = await db.query(
      'lorebooks',
      where: 'folder_id = ?',
      whereArgs: [folderId],
      orderBy: '`order` ASC',
    );
    return result.map((map) => Lorebook.fromMap(map)).toList();
  }

  Future<List<Lorebook>> readStandaloneLorebooks(int characterId) async {
    final db = await database;
    final result = await db.query(
      'lorebooks',
      where: 'character_id = ? AND folder_id IS NULL',
      whereArgs: [characterId],
      orderBy: '`order` ASC',
    );
    return result.map((map) => Lorebook.fromMap(map)).toList();
  }

  Future<int> updateLorebook(Lorebook lorebook) async {
    final db = await database;
    return await db.update(
      'lorebooks',
      lorebook.toMap(),
      where: 'id = ?',
      whereArgs: [lorebook.id],
    );
  }

  Future<int> deleteLorebook(int id) async {
    final db = await database;
    return await db.delete(
      'lorebooks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== 페르소나 CRUD ====================

  Future<int> createPersona(Persona persona) async {
    final db = await database;
    final map = persona.toMap();
    map.remove('id'); // id는 자동 생성되므로 제거
    return await db.insert('personas', map);
  }

  Future<List<Persona>> readPersonas(int characterId) async {
    final db = await database;
    final result = await db.query(
      'personas',
      where: 'character_id = ?',
      whereArgs: [characterId],
      orderBy: '`order` ASC',
    );
    return result.map((map) => Persona.fromMap(map)).toList();
  }

  Future<int> updatePersona(Persona persona) async {
    final db = await database;
    return await db.update(
      'personas',
      persona.toMap(),
      where: 'id = ?',
      whereArgs: [persona.id],
    );
  }

  Future<int> deletePersona(int id) async {
    final db = await database;
    return await db.delete(
      'personas',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== 시작설정 CRUD ====================

  Future<int> createStartScenario(StartScenario scenario) async {
    final db = await database;
    final map = scenario.toMap();
    map.remove('id'); // id는 자동 생성되므로 제거
    return await db.insert('start_scenarios', map);
  }

  Future<List<StartScenario>> readStartScenarios(int characterId) async {
    final db = await database;
    final result = await db.query(
      'start_scenarios',
      where: 'character_id = ?',
      whereArgs: [characterId],
      orderBy: '`order` ASC',
    );
    return result.map((map) => StartScenario.fromMap(map)).toList();
  }

  Future<int> updateStartScenario(StartScenario scenario) async {
    final db = await database;
    return await db.update(
      'start_scenarios',
      scenario.toMap(),
      where: 'id = ?',
      whereArgs: [scenario.id],
    );
  }

  Future<int> deleteStartScenario(int id) async {
    final db = await database;
    return await db.delete(
      'start_scenarios',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== 표지 이미지 CRUD ====================

  Future<int> createCoverImage(CoverImage coverImage) async {
    final db = await database;
    final map = coverImage.toMap();
    map.remove('id'); // id는 자동 생성되므로 제거
    return await db.insert('cover_images', map);
  }

  Future<List<CoverImage>> readCoverImages(int characterId) async {
    final db = await database;
    final result = await db.query(
      'cover_images',
      where: 'character_id = ?',
      whereArgs: [characterId],
      orderBy: '`order` ASC',
    );
    return result.map((map) => CoverImage.fromMap(map)).toList();
  }

  Future<int> updateCoverImage(CoverImage coverImage) async {
    final db = await database;
    return await db.update(
      'cover_images',
      coverImage.toMap(),
      where: 'id = ?',
      whereArgs: [coverImage.id],
    );
  }

  Future<int> deleteCoverImage(int id) async {
    final db = await database;
    return await db.delete(
      'cover_images',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== 유틸리티 ====================

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
