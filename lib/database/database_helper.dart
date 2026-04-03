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
import '../models/prompt/prompt_condition.dart';
import '../models/prompt/prompt_condition_option.dart';
import '../models/prompt/prompt_condition_preset.dart';
import '../models/prompt/prompt_condition_preset_value.dart';
import '../models/prompt/prompt_regex_rule.dart';
import '../models/chat/chat_room.dart';
import '../models/chat/chat_message.dart';
import '../models/chat/chat_log.dart';
import '../models/chat/chat_message_metadata.dart';
import '../models/chat/auto_summary_settings.dart';
import '../models/chat/chat_room_summary.dart';
import '../models/chat/chat_summary.dart';
import '../models/community/community_post.dart';
import '../models/community/community_comment.dart';
import '../utils/metadata_parser.dart';

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
      version: 41,
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
        nickname $textTypeNullable,
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
        secondary_keys $textTypeNullable,
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
        is_default $boolType,
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
        enabled $intType DEFAULT 1,
        chat_setting_mode $textType DEFAULT 'basic',
        include_start_position INTEGER,
        chat_range_type $textType DEFAULT 'recent',
        recent_chat_count INTEGER,
        chat_start_position INTEGER,
        chat_end_position INTEGER,
        enable_mode $textType DEFAULT 'enabled',
        condition_id INTEGER,
        condition_value $textTypeNullable,
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

    // 프롬프트 정규식 규칙 테이블
    await db.execute('''
      CREATE TABLE prompt_regex_rules (
        id $idType,
        chat_prompt_id $intType,
        name $textType,
        target $textType DEFAULT 'disabled',
        pattern $textTypeNullable,
        replacement $textTypeNullable,
        `order` $intType DEFAULT 0,
        FOREIGN KEY (chat_prompt_id) REFERENCES chat_prompts (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_chat_prompt_id_prompt_regex_rules
      ON prompt_regex_rules (chat_prompt_id)
    ''');

    // 프롬프트 조건 테이블
    await db.execute('''
      CREATE TABLE prompt_conditions (
        id $idType,
        chat_prompt_id $intType,
        name $textType DEFAULT '',
        type $textType DEFAULT 'toggle',
        variable_name $textTypeNullable,
        `order` $intType DEFAULT 0,
        FOREIGN KEY (chat_prompt_id) REFERENCES chat_prompts (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_chat_prompt_id_prompt_conditions
      ON prompt_conditions (chat_prompt_id)
    ''');

    // 프롬프트 조건 옵션 테이블
    await db.execute('''
      CREATE TABLE prompt_condition_options (
        id $idType,
        condition_id $intType,
        name $textType DEFAULT '',
        `order` $intType DEFAULT 0,
        FOREIGN KEY (condition_id) REFERENCES prompt_conditions (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_condition_id_prompt_condition_options
      ON prompt_condition_options (condition_id)
    ''');

    // 프롬프트 조건 프리셋 테이블
    await db.execute('''
      CREATE TABLE prompt_condition_presets (
        id $idType,
        chat_prompt_id $intType,
        name $textType DEFAULT '기본',
        is_default $boolType,
        `order` $intType DEFAULT 0,
        FOREIGN KEY (chat_prompt_id) REFERENCES chat_prompts (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_chat_prompt_id_prompt_condition_presets
      ON prompt_condition_presets (chat_prompt_id)
    ''');

    // 프롬프트 조건 프리셋 값 테이블
    await db.execute('''
      CREATE TABLE prompt_condition_preset_values (
        id $idType,
        preset_id $intType,
        condition_id $intType,
        value $textType DEFAULT '',
        custom_value $textTypeNullable,
        FOREIGN KEY (preset_id) REFERENCES prompt_condition_presets (id) ON DELETE CASCADE,
        FOREIGN KEY (condition_id) REFERENCES prompt_conditions (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_preset_id_prompt_condition_preset_values
      ON prompt_condition_preset_values (preset_id)
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
        total_token_count INTEGER NOT NULL DEFAULT 0,
        memo TEXT NOT NULL DEFAULT '',
        summary TEXT NOT NULL DEFAULT '',
        pin_mode TEXT NOT NULL DEFAULT 'auto',
        auto_pin_by_date INTEGER NOT NULL DEFAULT 1,
        auto_pin_by_location INTEGER NOT NULL DEFAULT 1,
        auto_pin_by_ai INTEGER NOT NULL DEFAULT 0,
        auto_pin_by_message_count INTEGER,
        selected_condition_preset_id INTEGER,
        selected_model_id TEXT,
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
        token_count INTEGER NOT NULL DEFAULT 0,
        created_at $textType,
        edited_at $textTypeNullable,
        usage_metadata $textTypeNullable,
        model_id $textTypeNullable,
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
        model_name TEXT,
        FOREIGN KEY (chat_room_id) REFERENCES chat_rooms (id) ON DELETE CASCADE,
        FOREIGN KEY (character_id) REFERENCES characters (id) ON DELETE CASCADE
      )
    ''');

    // 인덱스 생성
    await db.execute('''
      CREATE INDEX idx_timestamp_chat_logs
      ON chat_logs (timestamp DESC)
    ''');

    // 채팅 메시지 메타데이터 테이블
    await db.execute('''
      CREATE TABLE chat_message_metadata (
        id $idType,
        chat_message_id $intType,
        chat_room_id $intType,
        location $textTypeNullable,
        date $textTypeNullable,
        time $textTypeNullable,
        is_pinned $boolType,
        created_at $textType,
        FOREIGN KEY (chat_message_id) REFERENCES chat_messages (id) ON DELETE CASCADE,
        FOREIGN KEY (chat_room_id) REFERENCES chat_rooms (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_chat_message_id_metadata
      ON chat_message_metadata (chat_message_id)
    ''');
    await db.execute('''
      CREATE INDEX idx_chat_room_id_metadata
      ON chat_message_metadata (chat_room_id)
    ''');

    // Auto summary settings table
    await db.execute('''
      CREATE TABLE auto_summary_settings (
        id $idType,
        chat_room_id $intType,
        is_enabled $boolType DEFAULT 1,
        summary_model $textType DEFAULT 'gemini-2.0-flash-exp',
        token_threshold INTEGER NOT NULL DEFAULT 5000,
        summary_prompt $textType,
        parameters $textTypeNullable,
        summary_prompt_items $textTypeNullable,
        created_at $textType,
        updated_at $textType,
        FOREIGN KEY (chat_room_id) REFERENCES chat_rooms (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_chat_room_id_auto_summary_settings
      ON auto_summary_settings (chat_room_id)
    ''');

    // Chat summaries table
    await db.execute('''
      CREATE TABLE chat_summaries (
        id $idType,
        chat_room_id $intType,
        start_pin_message_id $intType,
        end_pin_message_id $intType,
        summary_content $textType,
        token_count INTEGER NOT NULL DEFAULT 0,
        created_at $textType,
        updated_at $textType,
        FOREIGN KEY (chat_room_id) REFERENCES chat_rooms (id) ON DELETE CASCADE,
        FOREIGN KEY (start_pin_message_id) REFERENCES chat_messages (id) ON DELETE CASCADE,
        FOREIGN KEY (end_pin_message_id) REFERENCES chat_messages (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_chat_room_id_chat_summaries
      ON chat_summaries (chat_room_id)
    ''');

    await db.execute('''
      CREATE INDEX idx_start_pin_message_id_chat_summaries
      ON chat_summaries (start_pin_message_id)
    ''');

    await db.execute('''
      CREATE INDEX idx_end_pin_message_id_chat_summaries
      ON chat_summaries (end_pin_message_id)
    ''');

    // Community tables
    await db.execute('''
      CREATE TABLE community_posts (
        id $idType,
        character_id $intType,
        author $textType,
        title $textType,
        time $textType,
        content $textType,
        created_at $textType,
        FOREIGN KEY (character_id) REFERENCES characters (id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE INDEX idx_character_id_community_posts
      ON community_posts (character_id)
    ''');

    await db.execute('''
      CREATE TABLE community_comments (
        id $idType,
        post_id $intType,
        author $textType,
        time $textType,
        content $textType,
        FOREIGN KEY (post_id) REFERENCES community_posts (id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE INDEX idx_post_id_community_comments
      ON community_comments (post_id)
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

    if (oldVersion < 18) {
      // chat_messages 테이블에 token_count 컬럼 추가
      await db.execute('''
        ALTER TABLE chat_messages ADD COLUMN token_count INTEGER NOT NULL DEFAULT 0
      ''');

      // chat_rooms 테이블에 total_token_count 컬럼 추가
      await db.execute('''
        ALTER TABLE chat_rooms ADD COLUMN total_token_count INTEGER NOT NULL DEFAULT 0
      ''');
    }

    if (oldVersion < 19) {
      final columns = await db.rawQuery('PRAGMA table_info(prompt_items)');
      final columnNames = columns.map((c) => c['name'] as String).toSet();

      final textType = 'TEXT NOT NULL';

      if (!columnNames.contains('chat_setting_mode')) {
        await db.execute('''
          ALTER TABLE prompt_items ADD COLUMN chat_setting_mode $textType DEFAULT 'basic'
        ''');
      }
      if (!columnNames.contains('include_start_position')) {
        await db.execute('''
          ALTER TABLE prompt_items ADD COLUMN include_start_position INTEGER
        ''');
      }
      if (!columnNames.contains('chat_range_type')) {
        await db.execute('''
          ALTER TABLE prompt_items ADD COLUMN chat_range_type $textType DEFAULT 'recent'
        ''');
      }
      if (!columnNames.contains('recent_chat_count')) {
        await db.execute('''
          ALTER TABLE prompt_items ADD COLUMN recent_chat_count INTEGER
        ''');
      }
      if (!columnNames.contains('chat_start_position')) {
        await db.execute('''
          ALTER TABLE prompt_items ADD COLUMN chat_start_position INTEGER
        ''');
      }
      if (!columnNames.contains('chat_end_position')) {
        await db.execute('''
          ALTER TABLE prompt_items ADD COLUMN chat_end_position INTEGER
        ''');
      }
    }

    if (oldVersion < 20) {
      // chat_messages 테이블에 usage_metadata 컬럼 추가
      await db.execute('''
        ALTER TABLE chat_messages ADD COLUMN usage_metadata TEXT
      ''');
    }

    if (oldVersion < 21) {
      await db.execute('''
        CREATE TABLE chat_message_metadata (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          chat_message_id INTEGER NOT NULL,
          chat_room_id INTEGER NOT NULL,
          location TEXT,
          date TEXT,
          time TEXT,
          created_at TEXT NOT NULL,
          FOREIGN KEY (chat_message_id) REFERENCES chat_messages (id) ON DELETE CASCADE,
          FOREIGN KEY (chat_room_id) REFERENCES chat_rooms (id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE INDEX idx_chat_message_id_metadata
        ON chat_message_metadata (chat_message_id)
      ''');
      await db.execute('''
        CREATE INDEX idx_chat_room_id_metadata
        ON chat_message_metadata (chat_room_id)
      ''');
    }

    if (oldVersion < 22) {
      await db.execute('''
        ALTER TABLE chat_messages ADD COLUMN model_id TEXT
      ''');
    }

    if (oldVersion < 23) {
      await db.execute('''
        ALTER TABLE chat_message_metadata ADD COLUMN is_pinned INTEGER NOT NULL DEFAULT 0
      ''');
    }

    if (oldVersion < 24) {
      await db.execute('''
        ALTER TABLE chat_rooms ADD COLUMN memo TEXT NOT NULL DEFAULT ''
      ''');
      await db.execute('''
        ALTER TABLE chat_rooms ADD COLUMN summary TEXT NOT NULL DEFAULT ''
      ''');
    }

    if (oldVersion < 25) {
      await db.execute('''
        ALTER TABLE chat_rooms ADD COLUMN pin_mode TEXT NOT NULL DEFAULT 'auto'
      ''');
    }

    if (oldVersion < 26) {
      await db.execute('''
        ALTER TABLE chat_rooms ADD COLUMN auto_pin_by_date INTEGER NOT NULL DEFAULT 1
      ''');
      await db.execute('''
        ALTER TABLE chat_rooms ADD COLUMN auto_pin_by_location INTEGER NOT NULL DEFAULT 1
      ''');
      await db.execute('''
        ALTER TABLE chat_rooms ADD COLUMN auto_pin_by_ai INTEGER NOT NULL DEFAULT 0
      ''');
    }

    if (oldVersion < 27) {
      await db.execute('''
        CREATE TABLE auto_summary_settings (
          id $idType,
          chat_room_id $intType,
          is_enabled $boolType DEFAULT 1,
          summary_model $textType DEFAULT 'gemini-2.0-flash-exp',
          token_threshold INTEGER NOT NULL DEFAULT 5000,
          summary_prompt $textType,
          created_at $textType,
          updated_at $textType,
          FOREIGN KEY (chat_room_id) REFERENCES chat_rooms (id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE INDEX idx_chat_room_id_auto_summary_settings
        ON auto_summary_settings (chat_room_id)
      ''');

      await db.execute('''
        CREATE TABLE chat_summaries (
          id $idType,
          chat_room_id $intType,
          start_pin_message_id $intType,
          end_pin_message_id $intType,
          summary_content $textType,
          token_count INTEGER NOT NULL DEFAULT 0,
          created_at $textType,
          updated_at $textType,
          FOREIGN KEY (chat_room_id) REFERENCES chat_rooms (id) ON DELETE CASCADE,
          FOREIGN KEY (start_pin_message_id) REFERENCES chat_messages (id) ON DELETE CASCADE,
          FOREIGN KEY (end_pin_message_id) REFERENCES chat_messages (id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE INDEX idx_chat_room_id_chat_summaries
        ON chat_summaries (chat_room_id)
      ''');

      await db.execute('''
        CREATE INDEX idx_start_pin_message_id_chat_summaries
        ON chat_summaries (start_pin_message_id)
      ''');

      await db.execute('''
        CREATE INDEX idx_end_pin_message_id_chat_summaries
        ON chat_summaries (end_pin_message_id)
      ''');
    }

    if (oldVersion < 28) {
      await db.execute('''
        ALTER TABLE auto_summary_settings ADD COLUMN parameters TEXT
      ''');
      await db.execute('''
        ALTER TABLE auto_summary_settings ADD COLUMN summary_prompt_items TEXT
      ''');
    }

    if (oldVersion < 29) {
      await db.execute('''
        ALTER TABLE chat_prompts ADD COLUMN is_default INTEGER NOT NULL DEFAULT 0
      ''');
    }

    if (oldVersion < 30) {
      await db.execute('''
        CREATE TABLE prompt_regex_rules (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          chat_prompt_id INTEGER NOT NULL,
          name TEXT NOT NULL,
          target TEXT NOT NULL DEFAULT 'disabled',
          pattern TEXT,
          replacement TEXT,
          `order` INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY (chat_prompt_id) REFERENCES chat_prompts (id) ON DELETE CASCADE
        )
      ''');
      await db.execute('''
        CREATE INDEX idx_chat_prompt_id_prompt_regex_rules
        ON prompt_regex_rules (chat_prompt_id)
      ''');
    }

    if (oldVersion < 31) {
      await db.execute('''
        ALTER TABLE character_books ADD COLUMN secondary_keys TEXT
      ''');
    }

    if (oldVersion < 32) {
      await db.execute('''
        ALTER TABLE characters ADD COLUMN nickname TEXT
      ''');
    }

    if (oldVersion < 33) {
      final columns = await db.rawQuery('PRAGMA table_info(prompt_items)');
      final columnNames = columns.map((c) => c['name'] as String).toSet();

      if (!columnNames.contains('enabled')) {
        await db.execute('''
          ALTER TABLE prompt_items ADD COLUMN enabled INTEGER NOT NULL DEFAULT 1
        ''');
      }
    }

    if (oldVersion < 34) {
      await db.execute('''
        ALTER TABLE chat_rooms ADD COLUMN auto_pin_by_message_count INTEGER
      ''');
    }

    if (oldVersion < 35) {
      await db.execute('''
        CREATE TABLE prompt_conditions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          chat_prompt_id INTEGER NOT NULL,
          name TEXT NOT NULL DEFAULT '',
          type TEXT NOT NULL DEFAULT 'toggle',
          variable_name TEXT,
          `order` INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY (chat_prompt_id) REFERENCES chat_prompts (id) ON DELETE CASCADE
        )
      ''');
      await db.execute('''
        CREATE INDEX idx_chat_prompt_id_prompt_conditions
        ON prompt_conditions (chat_prompt_id)
      ''');
      await db.execute('''
        CREATE TABLE prompt_condition_options (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          condition_id INTEGER NOT NULL,
          name TEXT NOT NULL DEFAULT '',
          `order` INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY (condition_id) REFERENCES prompt_conditions (id) ON DELETE CASCADE
        )
      ''');
      await db.execute('''
        CREATE INDEX idx_condition_id_prompt_condition_options
        ON prompt_condition_options (condition_id)
      ''');
    }

    if (oldVersion < 36) {
      final columns = await db.rawQuery('PRAGMA table_info(prompt_items)');
      final columnNames = columns.map((c) => c['name'] as String).toSet();

      if (!columnNames.contains('enable_mode')) {
        await db.execute('''
          ALTER TABLE prompt_items ADD COLUMN enable_mode TEXT NOT NULL DEFAULT 'enabled'
        ''');
        // Migrate existing enabled=0 to enable_mode='disabled'
        await db.execute('''
          UPDATE prompt_items SET enable_mode = 'disabled' WHERE enabled = 0
        ''');
      }
      if (!columnNames.contains('condition_id')) {
        await db.execute('''
          ALTER TABLE prompt_items ADD COLUMN condition_id INTEGER
        ''');
      }
      if (!columnNames.contains('condition_value')) {
        await db.execute('''
          ALTER TABLE prompt_items ADD COLUMN condition_value TEXT
        ''');
      }
    }

    if (oldVersion < 37) {
      await db.execute('''
        CREATE TABLE prompt_condition_presets (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          chat_prompt_id INTEGER NOT NULL,
          name TEXT NOT NULL DEFAULT '기본',
          is_default INTEGER NOT NULL DEFAULT 0,
          `order` INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY (chat_prompt_id) REFERENCES chat_prompts (id) ON DELETE CASCADE
        )
      ''');
      await db.execute('''
        CREATE INDEX idx_chat_prompt_id_prompt_condition_presets
        ON prompt_condition_presets (chat_prompt_id)
      ''');
      await db.execute('''
        CREATE TABLE prompt_condition_preset_values (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          preset_id INTEGER NOT NULL,
          condition_id INTEGER NOT NULL,
          value TEXT NOT NULL DEFAULT '',
          custom_value TEXT,
          FOREIGN KEY (preset_id) REFERENCES prompt_condition_presets (id) ON DELETE CASCADE,
          FOREIGN KEY (condition_id) REFERENCES prompt_conditions (id) ON DELETE CASCADE
        )
      ''');
      await db.execute('''
        CREATE INDEX idx_preset_id_prompt_condition_preset_values
        ON prompt_condition_preset_values (preset_id)
      ''');
    }

    if (oldVersion < 38) {
      await db.execute('''
        ALTER TABLE chat_rooms ADD COLUMN selected_condition_preset_id INTEGER
      ''');
    }

    if (oldVersion < 39) {
      await db.execute('''
        ALTER TABLE chat_rooms ADD COLUMN selected_model_id TEXT
      ''');
    }

    if (oldVersion < 40) {
      await db.execute('''
        ALTER TABLE chat_logs ADD COLUMN model_name TEXT
      ''');
    }

    if (oldVersion < 41) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS community_posts (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          character_id INTEGER NOT NULL,
          author TEXT NOT NULL,
          title TEXT NOT NULL,
          time TEXT NOT NULL,
          content TEXT NOT NULL,
          created_at TEXT NOT NULL,
          FOREIGN KEY (character_id) REFERENCES characters (id) ON DELETE CASCADE
        )
      ''');
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_character_id_community_posts
        ON community_posts (character_id)
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS community_comments (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          post_id INTEGER NOT NULL,
          author TEXT NOT NULL,
          time TEXT NOT NULL,
          content TEXT NOT NULL,
          FOREIGN KEY (post_id) REFERENCES community_posts (id) ON DELETE CASCADE
        )
      ''');
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_post_id_community_comments
        ON community_comments (post_id)
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

  Future<StartScenario?> readStartScenario(int id) async {
    final db = await database;
    final result = await db.query(
      'start_scenarios',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isEmpty) return null;
    return StartScenario.fromMap(result.first);
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
      final items = await readOrderedPromptItems(id);
      return prompt.copyWith(items: items);
    }
    return null;
  }

  Future<List<ChatPrompt>> readAllChatPrompts() async {
    final db = await database;
    const orderBy = 'is_default DESC, `order` ASC, created_at DESC';
    final result = await db.query('chat_prompts', orderBy: orderBy);
    final prompts = result.map((map) => ChatPrompt.fromMap(map)).toList();

    for (var prompt in prompts) {
      final items = await readOrderedPromptItems(prompt.id!);
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
    final rows = await db.query(
      'chat_prompts',
      where: 'id = ? AND is_default = 1',
      whereArgs: [id],
    );
    if (rows.isNotEmpty) return 0;
    return await db.delete(
      'chat_prompts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<bool> hasDefaultChatPrompts() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM chat_prompts WHERE is_default = 1',
    );
    return (result.first['cnt'] as int) > 0;
  }

  Future<void> deleteChatPromptWithRelations(int id) async {
    final db = await database;
    await db.delete('prompt_condition_preset_values',
        where: 'preset_id IN (SELECT id FROM prompt_condition_presets WHERE chat_prompt_id = ?)',
        whereArgs: [id]);
    await db.delete('prompt_condition_presets',
        where: 'chat_prompt_id = ?', whereArgs: [id]);
    await db.delete('prompt_condition_options',
        where: 'condition_id IN (SELECT id FROM prompt_conditions WHERE chat_prompt_id = ?)',
        whereArgs: [id]);
    await db.delete('prompt_conditions',
        where: 'chat_prompt_id = ?', whereArgs: [id]);
    await db.delete('prompt_regex_rules',
        where: 'chat_prompt_id = ?', whereArgs: [id]);
    await db.delete('prompt_items',
        where: 'chat_prompt_id = ?', whereArgs: [id]);
    await db.delete('prompt_item_folders',
        where: 'chat_prompt_id = ?', whereArgs: [id]);
    await db.delete('chat_prompts',
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteDefaultChatPrompts() async {
    final db = await database;
    final defaults = await db.query(
      'chat_prompts',
      columns: ['id'],
      where: 'is_default = 1',
    );
    for (final row in defaults) {
      await deleteChatPromptWithRelations(row['id'] as int);
    }
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

  /// Load prompt items in correct display order:
  /// standalone items and folders interleaved by order,
  /// with folder children expanded in place.
  Future<List<PromptItem>> readOrderedPromptItems(int chatPromptId) async {
    final standaloneItems = await readStandalonePromptItems(chatPromptId);
    final folders = await readPromptItemFolders(chatPromptId);

    // Load children for each folder
    for (final folder in folders) {
      folder.items.addAll(await readPromptItemsByFolder(folder.id!));
    }

    // Merge standalone items and folders by order, expanding folders in place
    final result = <PromptItem>[];
    int si = 0, fi = 0;

    while (si < standaloneItems.length || fi < folders.length) {
      final hasStandalone = si < standaloneItems.length;
      final hasFolder = fi < folders.length;

      if (hasStandalone && (!hasFolder || standaloneItems[si].order <= folders[fi].order)) {
        result.add(standaloneItems[si++]);
      } else {
        result.addAll(folders[fi++].items);
      }
    }

    return result;
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

  // ==================== 프롬프트 정규식 규칙 CRUD ====================

  Future<int> createPromptRegexRule(PromptRegexRule rule) async {
    final db = await database;
    final map = rule.toMap();
    map.remove('id');
    return await db.insert('prompt_regex_rules', map);
  }

  Future<List<PromptRegexRule>> readPromptRegexRules(int chatPromptId) async {
    final db = await database;
    final result = await db.query(
      'prompt_regex_rules',
      where: 'chat_prompt_id = ?',
      whereArgs: [chatPromptId],
      orderBy: '`order` ASC',
    );
    return result.map((map) => PromptRegexRule.fromMap(map)).toList();
  }

  Future<int> deletePromptRegexRule(int id) async {
    final db = await database;
    return await db.delete(
      'prompt_regex_rules',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deletePromptRegexRulesByPrompt(int chatPromptId) async {
    final db = await database;
    await db.delete(
      'prompt_regex_rules',
      where: 'chat_prompt_id = ?',
      whereArgs: [chatPromptId],
    );
  }

  // ==================== 프롬프트 조건 CRUD ====================

  Future<int> createPromptCondition(PromptCondition condition) async {
    final db = await database;
    final map = condition.toMap();
    map.remove('id');
    return await db.insert('prompt_conditions', map);
  }

  Future<List<PromptCondition>> readPromptConditions(int chatPromptId) async {
    final db = await database;
    final result = await db.query(
      'prompt_conditions',
      where: 'chat_prompt_id = ?',
      whereArgs: [chatPromptId],
      orderBy: '`order` ASC',
    );
    return result.map((map) => PromptCondition.fromMap(map)).toList();
  }

  Future<void> deletePromptConditionsByPrompt(int chatPromptId) async {
    final db = await database;
    await db.delete(
      'prompt_conditions',
      where: 'chat_prompt_id = ?',
      whereArgs: [chatPromptId],
    );
  }

  // ==================== 프롬프트 조건 옵션 CRUD ====================

  Future<int> createPromptConditionOption(PromptConditionOption option) async {
    final db = await database;
    final map = option.toMap();
    map.remove('id');
    return await db.insert('prompt_condition_options', map);
  }

  Future<List<PromptConditionOption>> readPromptConditionOptions(int conditionId) async {
    final db = await database;
    final result = await db.query(
      'prompt_condition_options',
      where: 'condition_id = ?',
      whereArgs: [conditionId],
      orderBy: '`order` ASC',
    );
    return result.map((map) => PromptConditionOption.fromMap(map)).toList();
  }

  // ==================== 프롬프트 조건 프리셋 CRUD ====================

  Future<int> createPromptConditionPreset(PromptConditionPreset preset) async {
    final db = await database;
    final map = preset.toMap();
    map.remove('id');
    return await db.insert('prompt_condition_presets', map);
  }

  Future<List<PromptConditionPreset>> readPromptConditionPresets(int chatPromptId) async {
    final db = await database;
    final result = await db.query(
      'prompt_condition_presets',
      where: 'chat_prompt_id = ?',
      whereArgs: [chatPromptId],
      orderBy: '`order` ASC',
    );
    return result.map((map) => PromptConditionPreset.fromMap(map)).toList();
  }

  Future<void> deletePromptConditionPresetsByPrompt(int chatPromptId) async {
    final db = await database;
    await db.delete(
      'prompt_condition_presets',
      where: 'chat_prompt_id = ?',
      whereArgs: [chatPromptId],
    );
  }

  // ==================== 프롬프트 조건 프리셋 값 CRUD ====================

  Future<int> createPromptConditionPresetValue(PromptConditionPresetValue value) async {
    final db = await database;
    final map = value.toMap();
    map.remove('id');
    return await db.insert('prompt_condition_preset_values', map);
  }

  Future<List<PromptConditionPresetValue>> readPromptConditionPresetValues(int presetId) async {
    final db = await database;
    final result = await db.query(
      'prompt_condition_preset_values',
      where: 'preset_id = ?',
      whereArgs: [presetId],
    );
    return result.map((map) => PromptConditionPresetValue.fromMap(map)).toList();
  }

  Future<void> deletePromptConditionPresetValuesByPreset(int presetId) async {
    final db = await database;
    await db.delete(
      'prompt_condition_preset_values',
      where: 'preset_id = ?',
      whereArgs: [presetId],
    );
  }

  // ==================== 채팅방 CRUD ====================

  Future<int> createChatRoom(ChatRoom chatRoom) async {
    final db = await database;
    final map = chatRoom.toMap();
    map.remove('id');
    return await db.insert('chat_rooms', map);
  }

  static const int agentCharacterId = -1;

  Future<int> getOrCreateAgentChatRoom() async {
    final db = await database;
    final maps = await db.query(
      'chat_rooms',
      where: 'character_id = ?',
      whereArgs: [agentCharacterId],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return maps.first['id'] as int;
    }

    final chatRoom = ChatRoom(
      characterId: agentCharacterId,
      name: 'Flan Agent',
      pinMode: 'manual',
    );

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

  Future<ChatMessage?> readLastChatMessage(int chatRoomId) async {
    final db = await database;
    final result = await db.query(
      'chat_messages',
      where: 'chat_room_id = ?',
      whereArgs: [chatRoomId],
      orderBy: 'created_at DESC',
      limit: 1,
    );
    if (result.isEmpty) return null;
    return ChatMessage.fromMap(result.first);
  }

  /// Returns the last message whose content is not empty after removing metadata tags.
  Future<ChatMessage?> readLastDisplayableChatMessage(int chatRoomId) async {
    final db = await database;
    final result = await db.query(
      'chat_messages',
      where: 'chat_room_id = ?',
      whereArgs: [chatRoomId],
      orderBy: 'created_at DESC',
      limit: 20,
    );
    if (result.isEmpty) return null;
    for (final map in result) {
      final message = ChatMessage.fromMap(map);
      final displayContent = MetadataParser.removeMetadataTags(message.content);
      if (displayContent.isNotEmpty) return message;
    }
    return ChatMessage.fromMap(result.first);
  }

  Future<int> countAssistantMessages(int chatRoomId) async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT COUNT(*) FROM chat_messages WHERE chat_room_id = ? AND role = 'assistant'",
      [chatRoomId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<List<ChatRoomSummary>> readChatRoomSummaries({int? characterId}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps;
    if (characterId != null) {
      maps = await db.query(
        'chat_rooms',
        where: 'character_id = ?',
        whereArgs: [characterId],
        orderBy: 'updated_at DESC',
      );
    } else {
      maps = await db.query(
        'chat_rooms',
        orderBy: 'updated_at DESC',
      );
    }
    final chatRooms = maps.map((map) => ChatRoom.fromMap(map)).toList();

    final List<ChatRoomSummary> summaries = [];
    for (final chatRoom in chatRooms) {
      final results = await Future.wait([
        readCharacter(chatRoom.characterId),
        readCoverImages(chatRoom.characterId),
        readLastDisplayableChatMessage(chatRoom.id!),
        countAssistantMessages(chatRoom.id!),
      ]);

      final character = results[0] as Character?;
      if (character == null) continue;

      final coverImages = results[1] as List<CoverImage>;
      summaries.add(ChatRoomSummary(
        chatRoom: chatRoom,
        character: character,
        coverImage: coverImages.isNotEmpty ? coverImages.first : null,
        lastMessage: results[2] as ChatMessage?,
        messageCount: results[3] as int,
        tokenCount: chatRoom.totalTokenCount,
      ));
    }
    return summaries;
  }

  Future<List<ChatMessage>> readRecentAssistantMessages(int chatRoomId, int count) async {
    final db = await database;
    final result = await db.query(
      'chat_messages',
      where: "chat_room_id = ? AND role = 'assistant'",
      whereArgs: [chatRoomId],
      orderBy: 'created_at DESC',
      limit: count,
    );
    return result.reversed.map((map) => ChatMessage.fromMap(map)).toList();
  }

  Future<List<ChatMessage>> readChatMessagesRecent(int chatRoomId, int count) async {
    final db = await database;
    final limit = count * 2;
    final result = await db.query(
      'chat_messages',
      where: 'chat_room_id = ?',
      whereArgs: [chatRoomId],
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return result.reversed.map((map) => ChatMessage.fromMap(map)).toList();
  }

  Future<List<ChatMessage>> readChatMessagesMiddle(int chatRoomId, int start, int end) async {
    final db = await database;
    final offset = (start - 1) * 2;
    final limit = (end - start + 1) * 2;
    final result = await db.rawQuery(
      'SELECT * FROM chat_messages WHERE chat_room_id = ? ORDER BY created_at DESC LIMIT ? OFFSET ?',
      [chatRoomId, limit, offset],
    );
    return result.reversed.map((map) => ChatMessage.fromMap(map)).toList();
  }

  Future<List<ChatMessage>> readChatMessagesOld(int chatRoomId, int recentExcludeCount) async {
    final db = await database;
    final excludeCount = recentExcludeCount * 2;
    final total = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM chat_messages WHERE chat_room_id = ?',
      [chatRoomId],
    )) ?? 0;
    final take = total - excludeCount;
    if (take <= 0) return [];
    final result = await db.query(
      'chat_messages',
      where: 'chat_room_id = ?',
      whereArgs: [chatRoomId],
      orderBy: 'created_at ASC',
      limit: take,
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

  /// 채팅방의 총 토큰 수를 다시 계산하여 업데이트
  Future<void> updateChatRoomTotalTokenCount(int chatRoomId) async {
    final db = await database;

    // 해당 채팅방의 모든 메시지 토큰 합산
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(token_count), 0) as total FROM chat_messages WHERE chat_room_id = ?',
      [chatRoomId],
    );

    final totalTokenCount = result.first['total'] as int? ?? 0;

    await db.update(
      'chat_rooms',
      {'total_token_count': totalTokenCount},
      where: 'id = ?',
      whereArgs: [chatRoomId],
    );
  }

  // ==================== 채팅 로그 CRUD ====================

  Future<int> createChatLog(ChatLog log) async {
    final db = await database;
    final map = log.toMap();
    map.remove('id');
    return await db.insert('chat_logs', map);
  }

  static const _chatLogListColumns = [
    'id', 'timestamp', 'type', 'chat_room_id', 'character_id', 'model_name',
  ];

  Future<List<ChatLog>> readAllChatLogs() async {
    final db = await database;
    final result = await db.query(
      'chat_logs',
      columns: _chatLogListColumns,
      orderBy: 'timestamp DESC',
    );
    return result.map((map) => ChatLog.fromMap(map)).toList();
  }

  Future<ChatLog?> readChatLog(int id) async {
    final db = await database;
    final result = await db.query(
      'chat_logs',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isEmpty) return null;
    return ChatLog.fromMap(result.first);
  }

  Future<List<ChatLog>> readChatLogsByChatRoom(int chatRoomId) async {
    final db = await database;
    final result = await db.query(
      'chat_logs',
      columns: _chatLogListColumns,
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
      columns: _chatLogListColumns,
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

  Future<int> deleteOldChatLogs() async {
    final db = await database;
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    return await db.delete(
      'chat_logs',
      where: 'timestamp < ?',
      whereArgs: [cutoff.toIso8601String()],
    );
  }

  // ==================== 채팅 메시지 메타데이터 CRUD ====================

  Future<int> createChatMessageMetadata(ChatMessageMetadata metadata) async {
    final db = await database;
    final map = metadata.toMap();
    map.remove('id');
    return await db.insert('chat_message_metadata', map);
  }

  Future<ChatMessageMetadata?> readChatMessageMetadataByMessage(int chatMessageId) async {
    final db = await database;
    final maps = await db.query(
      'chat_message_metadata',
      where: 'chat_message_id = ?',
      whereArgs: [chatMessageId],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return ChatMessageMetadata.fromMap(maps.first);
    }
    return null;
  }

  Future<List<ChatMessageMetadata>> readChatMessageMetadataByChatRoom(int chatRoomId) async {
    final db = await database;
    final result = await db.query(
      'chat_message_metadata',
      where: 'chat_room_id = ?',
      whereArgs: [chatRoomId],
      orderBy: 'created_at ASC',
    );
    return result.map((map) => ChatMessageMetadata.fromMap(map)).toList();
  }

  Future<ChatMessageMetadata?> readLatestChatMessageMetadata(int chatRoomId) async {
    final db = await database;
    final maps = await db.query(
      'chat_message_metadata',
      where: 'chat_room_id = ?',
      whereArgs: [chatRoomId],
      orderBy: 'created_at DESC',
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return ChatMessageMetadata.fromMap(maps.first);
    }
    return null;
  }

  Future<List<ChatMessageMetadata>> getChatMessageMetadataList(int chatRoomId) async {
    final db = await database;
    final maps = await db.query(
      'chat_message_metadata',
      where: 'chat_room_id = ?',
      whereArgs: [chatRoomId],
      orderBy: 'created_at ASC',
    );
    return maps.map((map) => ChatMessageMetadata.fromMap(map)).toList();
  }

  Future<int> updateChatMessageMetadata(ChatMessageMetadata metadata) async {
    final db = await database;
    return await db.update(
      'chat_message_metadata',
      metadata.toMap(),
      where: 'id = ?',
      whereArgs: [metadata.id],
    );
  }

  Future<int> countMetadataSinceLastPin(int chatRoomId) async {
    final db = await database;
    final lastPin = await db.query(
      'chat_message_metadata',
      where: 'chat_room_id = ? AND is_pinned = 1',
      whereArgs: [chatRoomId],
      orderBy: 'created_at DESC',
      limit: 1,
    );

    if (lastPin.isEmpty) {
      final result = await db.rawQuery(
        'SELECT COUNT(*) as cnt FROM chat_message_metadata WHERE chat_room_id = ?',
        [chatRoomId],
      );
      return Sqflite.firstIntValue(result) ?? 0;
    }

    final lastPinCreatedAt = lastPin.first['created_at'] as String;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM chat_message_metadata WHERE chat_room_id = ? AND created_at > ?',
      [chatRoomId, lastPinCreatedAt],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> deleteChatMessageMetadata(int id) async {
    final db = await database;
    return await db.delete(
      'chat_message_metadata',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteChatMessageMetadataByMessage(int chatMessageId) async {
    final db = await database;
    return await db.delete(
      'chat_message_metadata',
      where: 'chat_message_id = ?',
      whereArgs: [chatMessageId],
    );
  }

  Future<int> countPinnedMetadataByChatRoom(int chatRoomId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM chat_message_metadata WHERE chat_room_id = ? AND is_pinned = 1',
      [chatRoomId],
    );
    return result.first['cnt'] as int;
  }

  Future<ChatMessageMetadata?> readPinnedMetadataForScene(int chatRoomId, int sceneIndex) async {
    final db = await database;
    final result = await db.query(
      'chat_message_metadata',
      where: 'chat_room_id = ? AND is_pinned = 1',
      whereArgs: [chatRoomId],
      orderBy: 'created_at ASC',
      limit: 1,
      offset: sceneIndex,
    );
    if (result.isNotEmpty) {
      return ChatMessageMetadata.fromMap(result.first);
    }
    return null;
  }

  // ==================== 자동 요약 설정 CRUD ====================

  Future<int> createAutoSummarySettings(AutoSummarySettings settings) async {
    final db = await database;
    final map = settings.toMap();
    map.remove('id');
    return await db.insert('auto_summary_settings', map);
  }

  Future<AutoSummarySettings?> getAutoSummarySettings(int chatRoomId) async {
    final db = await database;
    final result = await db.query(
      'auto_summary_settings',
      where: 'chat_room_id = ?',
      whereArgs: [chatRoomId],
    );
    if (result.isNotEmpty) {
      return AutoSummarySettings.fromMap(result.first);
    }
    return null;
  }

  Future<int> updateAutoSummarySettings(AutoSummarySettings settings) async {
    final db = await database;
    return await db.update(
      'auto_summary_settings',
      settings.toMap(),
      where: 'id = ?',
      whereArgs: [settings.id],
    );
  }

  Future<int> deleteAutoSummarySettings(int id) async {
    final db = await database;
    return await db.delete(
      'auto_summary_settings',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== 채팅 요약 CRUD ====================

  Future<int> createChatSummary(ChatSummary summary) async {
    final db = await database;
    final map = summary.toMap();
    map.remove('id');
    return await db.insert('chat_summaries', map);
  }

  Future<List<ChatSummary>> getChatSummaries(int chatRoomId) async {
    final db = await database;
    final result = await db.query(
      'chat_summaries',
      where: 'chat_room_id = ?',
      whereArgs: [chatRoomId],
      orderBy: 'created_at ASC',
    );
    return result.map((map) => ChatSummary.fromMap(map)).toList();
  }

  Future<ChatSummary?> getChatSummary(int id) async {
    final db = await database;
    final result = await db.query(
      'chat_summaries',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isNotEmpty) {
      return ChatSummary.fromMap(result.first);
    }
    return null;
  }

  Future<int> updateChatSummary(ChatSummary summary) async {
    final db = await database;
    return await db.update(
      'chat_summaries',
      summary.toMap(),
      where: 'id = ?',
      whereArgs: [summary.id],
    );
  }

  Future<int> deleteChatSummary(int id) async {
    final db = await database;
    return await db.delete(
      'chat_summaries',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== 통계 ====================

  Future<List<Map<String, dynamic>>> getMessageStatsByDateAndModel({
    DateTime? from,
    DateTime? to,
  }) async {
    final db = await database;

    String whereClause =
        "role = 'assistant' AND usage_metadata IS NOT NULL AND model_id IS NOT NULL";
    final whereArgs = <dynamic>[];

    if (from != null) {
      whereClause += ' AND created_at >= ?';
      whereArgs.add(from.toIso8601String());
    }
    if (to != null) {
      whereClause += ' AND created_at <= ?';
      whereArgs.add(to.toIso8601String());
    }

    return await db.rawQuery(
      '''
      SELECT
        strftime('%Y-%m-%d', created_at) as date,
        model_id,
        COUNT(*) as message_count,
        SUM(COALESCE(json_extract(usage_metadata, '\$.promptTokenCount'), 0)) as prompt_tokens,
        SUM(COALESCE(json_extract(usage_metadata, '\$.candidatesTokenCount'), 0)) as output_tokens,
        SUM(COALESCE(json_extract(usage_metadata, '\$.cachedContentTokenCount'), 0)) as cached_tokens,
        SUM(COALESCE(json_extract(usage_metadata, '\$.thoughtsTokenCount'), 0)) as thinking_tokens
      FROM chat_messages
      WHERE $whereClause
      GROUP BY date, model_id
      ORDER BY date DESC, model_id
    ''',
      whereArgs.isNotEmpty ? whereArgs : null,
    );
  }

  // ==================== 백업 및 복구 ====================

  Future<String> getDatabaseFilePath() async {
    final dbPath = await getDatabasesPath();
    return join(dbPath, 'flan.db');
  }

  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  Future<void> reopenDatabase() async {
    await closeDatabase();
    _database = await _initDB('flan.db');
  }

  // ==================== 프롬프트 JSON 임포트 ====================

  /// Insert a full chat prompt from JSON data (conditions, items, presets, regex rules).
  /// Used by both default seeder and user import.
  Future<int> insertChatPromptFromJson(
    ChatPrompt prompt,
    Map<String, dynamic> jsonData,
  ) async {
    final promptId = await createChatPrompt(prompt);

    // Conditions first to build ID remap
    final conditions = prompt.conditionsFromJson(jsonData);
    final conditionIdMap = <int, int>{};
    for (int i = 0; i < conditions.length; i++) {
      final oldId = conditions[i].id;
      final newConditionId = await createPromptCondition(
        conditions[i].copyWith(id: null, chatPromptId: promptId, order: i),
      );
      if (oldId != null) conditionIdMap[oldId] = newConditionId;
      for (int j = 0; j < conditions[i].options.length; j++) {
        await createPromptConditionOption(
          conditions[i].options[j].copyWith(
            id: null,
            conditionId: newConditionId,
            order: j,
          ),
        );
      }
    }

    // Folders and items
    if (jsonData.containsKey('folders') || jsonData.containsKey('standaloneItems')) {
      final folders = prompt.foldersFromJson(jsonData);
      for (final folder in folders) {
        final folderId = await createPromptItemFolder(
          folder.copyWith(id: null, chatPromptId: promptId),
        );
        for (int i = 0; i < folder.items.length; i++) {
          final item = folder.items[i];
          final remappedConditionId = item.conditionId != null
              ? conditionIdMap[item.conditionId!]
              : null;
          await createPromptItem(
            item.copyWithNullableFolderId(
              id: null,
              chatPromptId: promptId,
              folderId: folderId,
              order: i,
              enableMode: item.enableMode,
              conditionId: remappedConditionId,
              conditionValue: item.conditionValue,
            ),
          );
        }
      }
      final standaloneItems = prompt.standaloneItemsFromJson(jsonData);
      for (int i = 0; i < standaloneItems.length; i++) {
        final item = standaloneItems[i];
        final remappedConditionId = item.conditionId != null
            ? conditionIdMap[item.conditionId!]
            : null;
        await createPromptItem(
          item.copyWithNullableFolderId(
            id: null,
            chatPromptId: promptId,
            folderId: null,
            order: i,
            enableMode: item.enableMode,
            conditionId: remappedConditionId,
            conditionValue: item.conditionValue,
          ),
        );
      }
    } else {
      for (int i = 0; i < prompt.items.length; i++) {
        final item = prompt.items[i];
        final remappedConditionId = item.conditionId != null
            ? conditionIdMap[item.conditionId!]
            : null;
        await createPromptItem(
          item.copyWithNullableCondition(
            enableMode: item.enableMode,
            conditionId: remappedConditionId,
            conditionValue: item.conditionValue,
          ).copyWith(
            id: null,
            chatPromptId: promptId,
            order: i,
          ),
        );
      }
    }

    // Regex rules
    final regexRules = prompt.regexRulesFromJson(jsonData);
    for (int i = 0; i < regexRules.length; i++) {
      await createPromptRegexRule(
        regexRules[i].copyWith(
          id: null,
          chatPromptId: promptId,
          order: i,
        ),
      );
    }

    // Condition presets
    final conditionPresets = prompt.conditionPresetsFromJson(jsonData);
    for (int i = 0; i < conditionPresets.length; i++) {
      final newPresetId = await createPromptConditionPreset(
        conditionPresets[i].copyWith(id: null, chatPromptId: promptId, order: i),
      );
      for (final value in conditionPresets[i].values) {
        final remappedConditionId = value.conditionId != null
            ? conditionIdMap[value.conditionId!]
            : null;
        await createPromptConditionPresetValue(
          value.copyWith(
            id: null,
            presetId: newPresetId,
            conditionId: remappedConditionId,
          ),
        );
      }
    }

    return promptId;
  }

  // ==================== 커뮤니티 CRUD ====================

  Future<int> createCommunityPost(CommunityPost post) async {
    final db = await database;
    final map = post.toMap();
    map.remove('id');
    return await db.insert('community_posts', map);
  }

  Future<int> createCommunityComment(CommunityComment comment) async {
    final db = await database;
    final map = comment.toMap();
    map.remove('id');
    return await db.insert('community_comments', map);
  }

  Future<List<CommunityPost>> readCommunityPosts(int characterId) async {
    final db = await database;

    final postMaps = await db.query(
      'community_posts',
      where: 'character_id = ?',
      whereArgs: [characterId],
      orderBy: 'time DESC',
    );
    final posts = postMaps.map((m) => CommunityPost.fromMap(m)).toList();

    if (posts.isEmpty) return posts;

    final postIds = posts.map((p) => p.id!).toList();
    final placeholders = List.filled(postIds.length, '?').join(', ');
    final commentMaps = await db.rawQuery(
      'SELECT * FROM community_comments WHERE post_id IN ($placeholders)',
      postIds,
    );
    final comments = commentMaps.map((m) => CommunityComment.fromMap(m)).toList();

    for (final post in posts) {
      post.comments = comments.where((c) => c.postId == post.id).toList();
    }

    return posts;
  }

  Future<void> deleteCommunityPosts(int characterId) async {
    final db = await database;
    await db.delete('community_posts', where: 'character_id = ?', whereArgs: [characterId]);
  }

  // ==================== 유틸리티 ====================

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
