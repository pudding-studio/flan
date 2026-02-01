import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/character/character.dart';
import '../models/character/character_book_folder.dart';
import '../models/character/persona.dart';
import '../models/character/start_scenario.dart';
import '../models/character/cover_image.dart';
import '../models/prompt/chat_prompt.dart';
import '../models/prompt/prompt_item.dart';
import '../models/prompt/prompt_item_folder.dart';
import '../models/chat/chat_room.dart';
import '../models/chat/chat_message.dart';
import '../models/chat/chat_log.dart';

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
      version: 17,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const intType = 'INTEGER NOT NULL';
    const textType = 'TEXT NOT NULL';
    const textTypeNullable = 'TEXT';
    const boolType = 'INTEGER NOT NULL DEFAULT 0';

    await db.execute('''
      CREATE TABLE characters (
        id $idType,
        name $textType,
        creator_notes $textTypeNullable,
        tags $textTypeNullable,
        description $textTypeNullable,
        selected_cover_image_id $textTypeNullable,
        created_at $textType,
        updated_at $textType,
        is_draft $boolType,
        sort_order INTEGER
      )
    ''');

    // 캐릭터 북 폴더 테이블
    await db.execute('''
      CREATE TABLE character_book_folders (
        id $idType,
        character_id $intType,
        name $textType,
        `order` $intType,
        is_expanded $boolType,
        FOREIGN KEY (character_id) REFERENCES characters (id) ON DELETE CASCADE
      )
    ''');

    // 캐릭터 북 테이블
    await db.execute('''
      CREATE TABLE character_books (
        id $idType,
        character_id $intType,
        folder_id INTEGER,
        name $textType,
        `order` $intType,
        is_expanded $boolType,
        enabled $textType,
        keys $textTypeNullable,
        key_condition $textType,
        insertion_order $intType,
        content $textTypeNullable,
        FOREIGN KEY (character_id) REFERENCES characters (id) ON DELETE CASCADE,
        FOREIGN KEY (folder_id) REFERENCES character_book_folders (id) ON DELETE CASCADE
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
        image_data BLOB,
        FOREIGN KEY (character_id) REFERENCES characters (id) ON DELETE CASCADE
      )
    ''');

    // 인덱스 생성 (성능 향상)
    await db.execute('''
      CREATE INDEX idx_character_id_character_book_folders
      ON character_book_folders (character_id)
    ''');
    await db.execute('''
      CREATE INDEX idx_character_id_character_books
      ON character_books (character_id)
    ''');
    await db.execute('''
      CREATE INDEX idx_folder_id_character_books
      ON character_books (folder_id)
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

    // 채팅 프롬프트 테이블
    await db.execute('''
      CREATE TABLE chat_prompts (
        id $idType,
        name $textType,
        description $textTypeNullable,
        supported_model $textType DEFAULT 'ALL',
        parameters $textTypeNullable,
        is_selected $boolType,
        `order` $intType DEFAULT 0,
        created_at $textType,
        updated_at $textType
      )
    ''');

    // 프롬프트 아이템 폴더 테이블
    await db.execute('''
      CREATE TABLE prompt_item_folders (
        id $idType,
        chat_prompt_id $intType,
        name $textType,
        `order` $intType DEFAULT 0,
        is_expanded $boolType DEFAULT 1,
        FOREIGN KEY (chat_prompt_id) REFERENCES chat_prompts (id) ON DELETE CASCADE
      )
    ''');

    // 프롬프트 항목 테이블
    await db.execute('''
      CREATE TABLE prompt_items (
        id $idType,
        chat_prompt_id $intType,
        folder_id INTEGER,
        role $textType DEFAULT 'system',
        content $textTypeNullable,
        name $textTypeNullable,
        `order` $intType DEFAULT 0,
        FOREIGN KEY (chat_prompt_id) REFERENCES chat_prompts (id) ON DELETE CASCADE,
        FOREIGN KEY (folder_id) REFERENCES prompt_item_folders (id) ON DELETE CASCADE
      )
    ''');

    // 프롬프트 아이템 폴더 인덱스
    await db.execute('''
      CREATE INDEX idx_chat_prompt_id_prompt_item_folders
      ON prompt_item_folders (chat_prompt_id)
    ''');

    // 프롬프트 아이템 인덱스
    await db.execute('''
      CREATE INDEX idx_chat_prompt_id_prompt_items
      ON prompt_items (chat_prompt_id)
    ''');

    await db.execute('''
      CREATE INDEX idx_folder_id_prompt_items
      ON prompt_items (folder_id)
    ''');

    // 채팅방 테이블
    await db.execute('''
      CREATE TABLE chat_rooms (
        id $idType,
        character_id $intType,
        name $textType,
        selected_chat_prompt_id INTEGER,
        selected_persona_id INTEGER,
        selected_start_scenario_id INTEGER,
        created_at $textType,
        updated_at $textType,
        FOREIGN KEY (character_id) REFERENCES characters (id) ON DELETE CASCADE,
        FOREIGN KEY (selected_chat_prompt_id) REFERENCES chat_prompts (id) ON DELETE SET NULL,
        FOREIGN KEY (selected_persona_id) REFERENCES personas (id) ON DELETE SET NULL,
        FOREIGN KEY (selected_start_scenario_id) REFERENCES start_scenarios (id) ON DELETE SET NULL
      )
    ''');

    // 채팅 메시지 테이블
    await db.execute('''
      CREATE TABLE chat_messages (
        id $idType,
        chat_room_id $intType,
        role $textType,
        content $textType,
        created_at $textType,
        edited_at $textTypeNullable,
        FOREIGN KEY (chat_room_id) REFERENCES chat_rooms (id) ON DELETE CASCADE
      )
    ''');

    // 인덱스 생성
    await db.execute('''
      CREATE INDEX idx_character_id_chat_rooms
      ON chat_rooms (character_id)
    ''');
    await db.execute('''
      CREATE INDEX idx_chat_room_id_messages
      ON chat_messages (chat_room_id)
    ''');

    // 채팅 로그 테이블
    await db.execute('''
      CREATE TABLE chat_logs (
        id $idType,
        timestamp $textType,
        type $textType,
        request $textType,
        response $textType,
        chat_room_id INTEGER,
        character_id INTEGER,
        FOREIGN KEY (chat_room_id) REFERENCES chat_rooms (id) ON DELETE CASCADE,
        FOREIGN KEY (character_id) REFERENCES characters (id) ON DELETE CASCADE
      )
    ''');

    // 인덱스 생성
    await db.execute('''
      CREATE INDEX idx_timestamp_chat_logs
      ON chat_logs (timestamp DESC)
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const intType = 'INTEGER NOT NULL';
    const textType = 'TEXT NOT NULL';
    const textTypeNullable = 'TEXT';

    const boolType = 'INTEGER NOT NULL DEFAULT 0';

    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE chat_prompts (
          id $idType,
          name $textType,
          content $textType,
          is_selected $boolType,
          created_at $textType,
          updated_at $textType
        )
      ''');
    }

    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE chat_rooms (
          id $idType,
          character_id $intType,
          name $textType,
          selected_chat_prompt_id INTEGER,
          selected_persona_id INTEGER,
          selected_start_scenario_id INTEGER,
          created_at $textType,
          updated_at $textType,
          FOREIGN KEY (character_id) REFERENCES characters (id) ON DELETE CASCADE,
          FOREIGN KEY (selected_chat_prompt_id) REFERENCES chat_prompts (id) ON DELETE SET NULL,
          FOREIGN KEY (selected_persona_id) REFERENCES personas (id) ON DELETE SET NULL,
          FOREIGN KEY (selected_start_scenario_id) REFERENCES start_scenarios (id) ON DELETE SET NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE chat_messages (
          id $idType,
          chat_room_id $intType,
          role $textType,
          content $textType,
          created_at $textType,
          edited_at $textTypeNullable,
          FOREIGN KEY (chat_room_id) REFERENCES chat_rooms (id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE INDEX idx_character_id_chat_rooms
        ON chat_rooms (character_id)
      ''');

      await db.execute('''
        CREATE INDEX idx_chat_room_id_messages
        ON chat_messages (chat_room_id)
      ''');
    }

    if (oldVersion < 4) {
      await db.execute('''
        ALTER TABLE chat_prompts ADD COLUMN is_selected INTEGER NOT NULL DEFAULT 0
      ''');
    }

    if (oldVersion < 5) {
      await db.execute('''
        ALTER TABLE characters ADD COLUMN sort_order INTEGER
      ''');
    }

    if (oldVersion < 6) {
      await db.execute('''
        ALTER TABLE chat_prompts ADD COLUMN role TEXT DEFAULT 'system'
      ''');
      await db.execute('''
        ALTER TABLE chat_prompts ADD COLUMN `order` INTEGER NOT NULL DEFAULT 0
      ''');
    }

    if (oldVersion < 7) {
      // 기존 chat_prompts 데이터를 임시 테이블로 백업
      await db.execute('''
        CREATE TABLE chat_prompts_backup (
          id INTEGER,
          name TEXT,
          content TEXT,
          role TEXT,
          is_selected INTEGER,
          `order` INTEGER,
          created_at TEXT,
          updated_at TEXT
        )
      ''');

      await db.execute('''
        INSERT INTO chat_prompts_backup
        SELECT id, name, content, role, is_selected, `order`, created_at, updated_at
        FROM chat_prompts
      ''');

      // 기존 chat_prompts 테이블 삭제
      await db.execute('DROP TABLE chat_prompts');

      // 새로운 chat_prompts 테이블 생성
      await db.execute('''
        CREATE TABLE chat_prompts (
          id $idType,
          name $textType,
          is_selected $boolType,
          `order` $intType DEFAULT 0,
          created_at $textType,
          updated_at $textType
        )
      ''');

      // prompt_items 테이블 생성
      await db.execute('''
        CREATE TABLE prompt_items (
          id $idType,
          chat_prompt_id $intType,
          role $textType DEFAULT 'system',
          content $textTypeNullable,
          `order` $intType DEFAULT 0,
          FOREIGN KEY (chat_prompt_id) REFERENCES chat_prompts (id) ON DELETE CASCADE
        )
      ''');

      // 백업 데이터를 새 구조로 마이그레이션
      await db.execute('''
        INSERT INTO chat_prompts (id, name, is_selected, `order`, created_at, updated_at)
        SELECT id, name, is_selected, `order`, created_at, updated_at
        FROM chat_prompts_backup
      ''');

      // 각 chat_prompt에 대해 prompt_item 생성
      await db.execute('''
        INSERT INTO prompt_items (chat_prompt_id, role, content, `order`)
        SELECT id, role, content, 0
        FROM chat_prompts_backup
        WHERE content IS NOT NULL AND content != ''
      ''');

      // 백업 테이블 삭제
      await db.execute('DROP TABLE chat_prompts_backup');
    }

    if (oldVersion < 8) {
      // chat_prompts 테이블에 새 컬럼 추가
      await db.execute('''
        ALTER TABLE chat_prompts ADD COLUMN description $textTypeNullable
      ''');

      await db.execute('''
        ALTER TABLE chat_prompts ADD COLUMN supported_model $textType DEFAULT 'ALL'
      ''');

      await db.execute('''
        ALTER TABLE chat_prompts ADD COLUMN parameters $textTypeNullable
      ''');
    }

    if (oldVersion < 9) {
      await db.execute('''
        ALTER TABLE prompt_items ADD COLUMN name $textTypeNullable
      ''');
    }

    if (oldVersion < 10) {
      await db.execute('''
        CREATE TABLE chat_logs (
          id $idType,
          timestamp $textType,
          type $textType,
          request $textType,
          response $textType,
          chat_room_id INTEGER,
          character_id INTEGER,
          FOREIGN KEY (chat_room_id) REFERENCES chat_rooms (id) ON DELETE CASCADE,
          FOREIGN KEY (character_id) REFERENCES characters (id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE INDEX idx_timestamp_chat_logs
        ON chat_logs (timestamp DESC)
      ''');
    }

    if (oldVersion < 11) {
      // image_path 컬럼을 image_data BLOB로 변경
      await db.execute('ALTER TABLE cover_images RENAME TO cover_images_old');

      await db.execute('''
        CREATE TABLE cover_images (
          id $idType,
          character_id $intType,
          name $textType,
          `order` $intType,
          is_expanded $boolType,
          image_data BLOB,
          FOREIGN KEY (character_id) REFERENCES characters (id) ON DELETE CASCADE
        )
      ''');

      // 기존 데이터는 image_path가 있었으므로 삭제 (바이너리로 재저장 필요)
      await db.execute('DROP TABLE cover_images_old');
    }

    if (oldVersion < 12) {
      // summary 컬럼을 creator_notes로 변경
      await db.execute('ALTER TABLE characters RENAME COLUMN summary TO creator_notes');
    }

    if (oldVersion < 13) {
      // world_setting 컬럼을 description으로 변경
      await db.execute('ALTER TABLE characters RENAME COLUMN world_setting TO description');
    }

    if (oldVersion < 14) {
      // keywords 컬럼을 tags로 변경
      await db.execute('ALTER TABLE characters RENAME COLUMN keywords TO tags');
    }

    if (oldVersion < 15) {
      // lorebooks 테이블의 컬럼명 변경 (테이블명은 아직 lorebooks)
      await db.execute('ALTER TABLE lorebooks RENAME COLUMN activation_condition TO enabled');
      await db.execute('ALTER TABLE lorebooks RENAME COLUMN activation_keys TO keys');
    }

    if (oldVersion < 16) {
      // lorebook_folders -> character_book_folders 테이블명 변경
      await db.execute('ALTER TABLE lorebook_folders RENAME TO character_book_folders');

      // lorebooks -> character_books 테이블명 변경 및 컬럼명 변경
      await db.execute('ALTER TABLE lorebooks RENAME TO character_books');
      await db.execute('ALTER TABLE character_books RENAME COLUMN deployment_order TO insertion_order');

      // 인덱스 재생성
      await db.execute('DROP INDEX IF EXISTS idx_character_id_lorebook_folders');
      await db.execute('DROP INDEX IF EXISTS idx_character_id_lorebooks');
      await db.execute('DROP INDEX IF EXISTS idx_folder_id_lorebooks');

      await db.execute('''
        CREATE INDEX idx_character_id_character_book_folders
        ON character_book_folders (character_id)
      ''');
      await db.execute('''
        CREATE INDEX idx_character_id_character_books
        ON character_books (character_id)
      ''');
      await db.execute('''
        CREATE INDEX idx_folder_id_character_books
        ON character_books (folder_id)
      ''');
    }

    if (oldVersion < 17) {
      // 프롬프트 아이템 폴더 테이블 생성
      await db.execute('''
        CREATE TABLE prompt_item_folders (
          id $idType,
          chat_prompt_id $intType,
          name $textType,
          `order` $intType DEFAULT 0,
          is_expanded $boolType DEFAULT 1,
          FOREIGN KEY (chat_prompt_id) REFERENCES chat_prompts (id) ON DELETE CASCADE
        )
      ''');

      // prompt_items 테이블에 folder_id 컬럼 추가
      await db.execute('''
        ALTER TABLE prompt_items ADD COLUMN folder_id INTEGER REFERENCES prompt_item_folders (id) ON DELETE CASCADE
      ''');

      // 인덱스 생성
      await db.execute('''
        CREATE INDEX idx_chat_prompt_id_prompt_item_folders
        ON prompt_item_folders (chat_prompt_id)
      ''');

      await db.execute('''
        CREATE INDEX idx_chat_prompt_id_prompt_items
        ON prompt_items (chat_prompt_id)
      ''');

      await db.execute('''
        CREATE INDEX idx_folder_id_prompt_items
        ON prompt_items (folder_id)
      ''');
    }
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

  // ==================== 캐릭터 북 폴더 CRUD ====================

  Future<int> createCharacterBookFolder(CharacterBookFolder characterBookFolder) async {
    final db = await database;
    final map = characterBookFolder.toMap();
    map.remove('id'); // id는 자동 생성되므로 제거
    return await db.insert('character_book_folders', map);
  }

  Future<List<CharacterBookFolder>> readCharacterBookFolders(int characterId) async {
    final db = await database;
    final result = await db.query(
      'character_book_folders',
      where: 'character_id = ?',
      whereArgs: [characterId],
      orderBy: '`order` ASC',
    );
    return result.map((map) => CharacterBookFolder.fromMap(map)).toList();
  }

  Future<int> updateCharacterBookFolder(CharacterBookFolder characterBookFolder) async {
    final db = await database;
    return await db.update(
      'character_book_folders',
      characterBookFolder.toMap(),
      where: 'id = ?',
      whereArgs: [characterBookFolder.id],
    );
  }

  Future<int> deleteCharacterBookFolder(int id) async {
    final db = await database;
    return await db.delete(
      'character_book_folders',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== 캐릭터 북 CRUD ====================

  Future<int> createCharacterBook(CharacterBook characterBook) async {
    final db = await database;
    final map = characterBook.toMap();
    map.remove('id'); // id는 자동 생성되므로 제거
    return await db.insert('character_books', map);
  }

  Future<List<CharacterBook>> readCharacterBooks(int characterId) async {
    final db = await database;
    final result = await db.query(
      'character_books',
      where: 'character_id = ?',
      whereArgs: [characterId],
      orderBy: '`order` ASC',
    );
    return result.map((map) => CharacterBook.fromMap(map)).toList();
  }

  Future<List<CharacterBook>> readCharacterBooksByFolder(int folderId) async {
    final db = await database;
    final result = await db.query(
      'character_books',
      where: 'folder_id = ?',
      whereArgs: [folderId],
      orderBy: '`order` ASC',
    );
    return result.map((map) => CharacterBook.fromMap(map)).toList();
  }

  Future<List<CharacterBook>> readStandaloneCharacterBooks(int characterId) async {
    final db = await database;
    final result = await db.query(
      'character_books',
      where: 'character_id = ? AND folder_id IS NULL',
      whereArgs: [characterId],
      orderBy: '`order` ASC',
    );
    return result.map((map) => CharacterBook.fromMap(map)).toList();
  }

  Future<int> updateCharacterBook(CharacterBook characterBook) async {
    final db = await database;
    return await db.update(
      'character_books',
      characterBook.toMap(),
      where: 'id = ?',
      whereArgs: [characterBook.id],
    );
  }

  Future<int> deleteCharacterBook(int id) async {
    final db = await database;
    return await db.delete(
      'character_books',
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

  Future<Persona?> readPersona(int id) async {
    final db = await database;
    final maps = await db.query(
      'personas',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Persona.fromMap(maps.first);
    }
    return null;
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

  // ==================== 채팅 프롬프트 CRUD ====================

  Future<int> createChatPrompt(ChatPrompt prompt) async {
    final db = await database;
    final map = prompt.toMap();
    map.remove('id');
    return await db.insert('chat_prompts', map);
  }

  Future<ChatPrompt?> readChatPrompt(int id) async {
    final db = await database;
    final maps = await db.query(
      'chat_prompts',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      final prompt = ChatPrompt.fromMap(maps.first);
      final items = await readPromptItemsByChatPrompt(id);
      return prompt.copyWith(items: items);
    }
    return null;
  }

  Future<List<ChatPrompt>> readAllChatPrompts() async {
    final db = await database;
    const orderBy = 'created_at DESC';
    final result = await db.query('chat_prompts', orderBy: orderBy);
    final prompts = result.map((map) => ChatPrompt.fromMap(map)).toList();

    for (var prompt in prompts) {
      final items = await readPromptItemsByChatPrompt(prompt.id!);
      prompt.items.addAll(items);
    }

    return prompts;
  }

  Future<int> updateChatPrompt(ChatPrompt prompt) async {
    final db = await database;
    return await db.update(
      'chat_prompts',
      prompt.toMap(),
      where: 'id = ?',
      whereArgs: [prompt.id],
    );
  }

  Future<int> deleteChatPrompt(int id) async {
    final db = await database;
    return await db.delete(
      'chat_prompts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> setSelectedChatPrompt(int id) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.update(
        'chat_prompts',
        {'is_selected': 0},
      );
      await txn.update(
        'chat_prompts',
        {'is_selected': 1},
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  // ==================== 프롬프트 아이템 폴더 CRUD ====================

  Future<int> createPromptItemFolder(PromptItemFolder folder) async {
    final db = await database;
    final map = folder.toMap();
    map.remove('id');
    return await db.insert('prompt_item_folders', map);
  }

  Future<List<PromptItemFolder>> readPromptItemFolders(int chatPromptId) async {
    final db = await database;
    final result = await db.query(
      'prompt_item_folders',
      where: 'chat_prompt_id = ?',
      whereArgs: [chatPromptId],
      orderBy: '`order` ASC',
    );
    return result.map((map) => PromptItemFolder.fromMap(map)).toList();
  }

  Future<int> updatePromptItemFolder(PromptItemFolder folder) async {
    final db = await database;
    return await db.update(
      'prompt_item_folders',
      folder.toMap(),
      where: 'id = ?',
      whereArgs: [folder.id],
    );
  }

  Future<int> deletePromptItemFolder(int id) async {
    final db = await database;
    return await db.delete(
      'prompt_item_folders',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== 프롬프트 항목 CRUD ====================

  Future<int> createPromptItem(PromptItem item) async {
    final db = await database;
    final map = item.toMap();
    map.remove('id');
    return await db.insert('prompt_items', map);
  }

  Future<PromptItem?> readPromptItem(int id) async {
    final db = await database;
    final maps = await db.query(
      'prompt_items',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return PromptItem.fromMap(maps.first);
    }
    return null;
  }

  Future<List<PromptItem>> readPromptItemsByChatPrompt(int chatPromptId) async {
    final db = await database;
    const orderBy = '`order` ASC';
    final result = await db.query(
      'prompt_items',
      where: 'chat_prompt_id = ?',
      whereArgs: [chatPromptId],
      orderBy: orderBy,
    );
    return result.map((map) => PromptItem.fromMap(map)).toList();
  }

  Future<List<PromptItem>> readPromptItemsByFolder(int folderId) async {
    final db = await database;
    final result = await db.query(
      'prompt_items',
      where: 'folder_id = ?',
      whereArgs: [folderId],
      orderBy: '`order` ASC',
    );
    return result.map((map) => PromptItem.fromMap(map)).toList();
  }

  Future<List<PromptItem>> readStandalonePromptItems(int chatPromptId) async {
    final db = await database;
    final result = await db.query(
      'prompt_items',
      where: 'chat_prompt_id = ? AND folder_id IS NULL',
      whereArgs: [chatPromptId],
      orderBy: '`order` ASC',
    );
    return result.map((map) => PromptItem.fromMap(map)).toList();
  }

  Future<int> updatePromptItem(PromptItem item) async {
    final db = await database;
    return await db.update(
      'prompt_items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deletePromptItem(int id) async {
    final db = await database;
    return await db.delete(
      'prompt_items',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<ChatPrompt?> readSelectedChatPrompt() async {
    final db = await database;
    final maps = await db.query(
      'chat_prompts',
      where: 'is_selected = ?',
      whereArgs: [1],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return ChatPrompt.fromMap(maps.first);
    }
    return null;
  }

  // ==================== 채팅방 CRUD ====================

  Future<int> createChatRoom(ChatRoom chatRoom) async {
    final db = await database;
    final map = chatRoom.toMap();
    map.remove('id');
    return await db.insert('chat_rooms', map);
  }

  Future<ChatRoom?> readChatRoom(int id) async {
    final db = await database;
    final maps = await db.query(
      'chat_rooms',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return ChatRoom.fromMap(maps.first);
    }
    return null;
  }

  Future<List<ChatRoom>> readChatRoomsByCharacter(int characterId) async {
    final db = await database;
    final result = await db.query(
      'chat_rooms',
      where: 'character_id = ?',
      whereArgs: [characterId],
      orderBy: 'updated_at DESC',
    );
    return result.map((map) => ChatRoom.fromMap(map)).toList();
  }

  Future<int> updateChatRoom(ChatRoom chatRoom) async {
    final db = await database;
    return await db.update(
      'chat_rooms',
      chatRoom.toMap(),
      where: 'id = ?',
      whereArgs: [chatRoom.id],
    );
  }

  Future<int> deleteChatRoom(int id) async {
    final db = await database;
    return await db.delete(
      'chat_rooms',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== 채팅 메시지 CRUD ====================

  Future<int> createChatMessage(ChatMessage message) async {
    final db = await database;
    final map = message.toMap();
    map.remove('id');
    return await db.insert('chat_messages', map);
  }

  Future<ChatMessage?> readChatMessage(int id) async {
    final db = await database;
    final maps = await db.query(
      'chat_messages',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return ChatMessage.fromMap(maps.first);
    }
    return null;
  }

  Future<List<ChatMessage>> readChatMessagesByChatRoom(int chatRoomId) async {
    final db = await database;
    final result = await db.query(
      'chat_messages',
      where: 'chat_room_id = ?',
      whereArgs: [chatRoomId],
      orderBy: 'created_at ASC',
    );
    return result.map((map) => ChatMessage.fromMap(map)).toList();
  }

  Future<int> updateChatMessage(ChatMessage message) async {
    final db = await database;
    return await db.update(
      'chat_messages',
      message.toMap(),
      where: 'id = ?',
      whereArgs: [message.id],
    );
  }

  Future<int> deleteChatMessage(int id) async {
    final db = await database;
    return await db.delete(
      'chat_messages',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== 채팅 로그 CRUD ====================

  Future<int> createChatLog(ChatLog log) async {
    final db = await database;
    final map = log.toMap();
    map.remove('id');
    return await db.insert('chat_logs', map);
  }

  Future<List<ChatLog>> readAllChatLogs() async {
    final db = await database;
    final result = await db.query(
      'chat_logs',
      orderBy: 'timestamp DESC',
    );
    return result.map((map) => ChatLog.fromMap(map)).toList();
  }

  Future<List<ChatLog>> readChatLogsByChatRoom(int chatRoomId) async {
    final db = await database;
    final result = await db.query(
      'chat_logs',
      where: 'chat_room_id = ?',
      whereArgs: [chatRoomId],
      orderBy: 'timestamp DESC',
    );
    return result.map((map) => ChatLog.fromMap(map)).toList();
  }

  Future<List<ChatLog>> readChatLogsByCharacter(int characterId) async {
    final db = await database;
    final result = await db.query(
      'chat_logs',
      where: 'character_id = ?',
      whereArgs: [characterId],
      orderBy: 'timestamp DESC',
    );
    return result.map((map) => ChatLog.fromMap(map)).toList();
  }

  Future<int> deleteChatLog(int id) async {
    final db = await database;
    return await db.delete(
      'chat_logs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteAllChatLogs() async {
    final db = await database;
    return await db.delete('chat_logs');
  }

  // ==================== 유틸리티 ====================

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
