import '../../database/database_helper.dart';
import '../../models/character/character.dart';
import '../../models/character/character_book_folder.dart';
import '../../models/character/persona.dart';
import '../../models/character/start_scenario.dart';
import 'agent_tool.dart';

class ListCharactersTool extends AgentTool {
  final DatabaseHelper _db;

  ListCharactersTool(this._db);

  @override
  String get name => 'list_characters';

  @override
  String get description => 'List all characters with basic info (id, name, nickname, tags).';

  @override
  List<AgentToolParameter> get parameters => [];

  @override
  Future<AgentToolResult> execute(Map<String, dynamic> args) async {
    final characters = await _db.readAllCharacters();
    final list = characters.map((c) => {
      'id': c.id,
      'name': c.name,
      'nickname': c.nickname,
      'tags': c.tags,
      'description': c.description != null && c.description!.length > 100
          ? '${c.description!.substring(0, 100)}...'
          : c.description,
    }).toList();

    return AgentToolResult(
      success: true,
      data: list,
      message: '${characters.length}개의 캐릭터를 찾았습니다.',
    );
  }
}

class GetCharacterTool extends AgentTool {
  final DatabaseHelper _db;

  GetCharacterTool(this._db);

  @override
  String get name => 'get_character';

  @override
  String get description =>
      'Get full details of a character including personas, start scenarios, character books, and SNS settings.';

  @override
  List<AgentToolParameter> get parameters => [
    const AgentToolParameter(
      name: 'id',
      type: 'int',
      description: 'Character ID',
      required: true,
    ),
  ];

  @override
  Future<AgentToolResult> execute(Map<String, dynamic> args) async {
    final id = args['id'] as int;
    final character = await _db.readCharacter(id);
    if (character == null) {
      return const AgentToolResult(
        success: false,
        message: '해당 ID의 캐릭터를 찾을 수 없습니다.',
      );
    }

    final personas = await _db.readPersonas(id);
    final startScenarios = await _db.readStartScenarios(id);
    final characterBooks = await _db.readCharacterBooks(id);

    return AgentToolResult(
      success: true,
      data: {
        'id': character.id,
        'name': character.name,
        'nickname': character.nickname,
        'creatorNotes': character.creatorNotes,
        'tags': character.tags,
        'description': character.description,
        'isDraft': character.isDraft,
        'communityName': character.communityName,
        'communityMood': character.communityMood,
        'communityLanguage': character.communityLanguage,
        'worldStartDate': character.worldStartDate?.toIso8601String(),
        'createdAt': character.createdAt.toIso8601String(),
        'updatedAt': character.updatedAt.toIso8601String(),
        'personas': personas.map((p) => {
          'id': p.id,
          'name': p.name,
          'content': p.content,
          'order': p.order,
        }).toList(),
        'startScenarios': startScenarios.map((s) => {
          'id': s.id,
          'name': s.name,
          'startSetting': s.startSetting,
          'startMessage': s.startMessage,
          'order': s.order,
        }).toList(),
        'characterBooks': characterBooks.map((b) => _characterBookToDetailedMap(b)).toList(),
      },
      message: '캐릭터 "${character.name}" 정보를 가져왔습니다.',
    );
  }
}

/// Serialize a CharacterBook with all category-specific structured fields.
/// Null / empty fields are omitted to keep the agent-facing payload concise.
Map<String, dynamic> _characterBookToDetailedMap(CharacterBook b) {
  final map = <String, dynamic>{
    'id': b.id,
    'name': b.name,
    'category': b.category.name,
    'oneLineDescription': b.oneLineDescription,
    'autoSummaryInsert': b.autoSummaryInsert,
    'enabled': b.enabled.name,
    'keys': b.keys,
    'folderId': b.folderId,
    'order': b.order,
  };
  switch (b.category) {
    case CharacterBookCategory.character:
      _putIfNotEmpty(map, 'subNames', b.subNames);
      _putIfNotEmpty(map, 'appearance', b.appearance);
      if (b.gender != null) map['gender'] = b.gender!.name;
      _putIfNotEmpty(map, 'genderOther', b.genderOther);
      _putIfNotEmpty(map, 'age', b.age);
      _putIfNotEmpty(map, 'personality', b.personality);
      _putIfNotEmpty(map, 'past', b.past);
      _putIfNotEmpty(map, 'abilities', b.abilities);
      _putIfNotEmpty(map, 'dialogueStyle', b.dialogueStyle);
      break;
    case CharacterBookCategory.location:
    case CharacterBookCategory.other:
      _putIfNotEmpty(map, 'setting', b.setting);
      break;
    case CharacterBookCategory.event:
      _putIfNotEmpty(map, 'datetime', b.eventDatetime);
      _putIfNotEmpty(map, 'eventContent', b.eventContent);
      _putIfNotEmpty(map, 'result', b.eventResult);
      break;
  }
  return map;
}

void _putIfNotEmpty(Map<String, dynamic> map, String key, String value) {
  if (value.isNotEmpty) map[key] = value;
}

class CreateCharacterTool extends AgentTool {
  final DatabaseHelper _db;

  CreateCharacterTool(this._db);

  @override
  String get name => 'create_character';

  @override
  String get description => 'Create a new character.';

  @override
  List<AgentToolParameter> get parameters => [
    const AgentToolParameter(
      name: 'name',
      type: 'string',
      description: 'Character name',
      required: true,
    ),
    const AgentToolParameter(
      name: 'nickname',
      type: 'string',
      description: 'Character nickname (optional)',
    ),
    const AgentToolParameter(
      name: 'description',
      type: 'string',
      description: 'Character description (optional)',
    ),
    const AgentToolParameter(
      name: 'tags',
      type: 'List<string>',
      description: 'Character tags (optional)',
    ),
    const AgentToolParameter(
      name: 'creatorNotes',
      type: 'string',
      description: 'Creator notes (optional)',
    ),
    const AgentToolParameter(
      name: 'communityName',
      type: 'string',
      description: 'SNS community name / identity (optional)',
    ),
    const AgentToolParameter(
      name: 'communityMood',
      type: 'string',
      description: 'SNS community mood / tone (optional)',
    ),
    const AgentToolParameter(
      name: 'communityLanguage',
      type: 'string',
      description: 'SNS community language (optional)',
    ),
    const AgentToolParameter(
      name: 'worldStartDate',
      type: 'string',
      description:
          'In-world start date as ISO 8601 (YYYY-MM-DD). Anchors news/SNS/date-metadata generation. Omit if the world has no meaningful calendar date.',
    ),
  ];

  @override
  Future<AgentToolResult> execute(Map<String, dynamic> args) async {
    final name = args['name'] as String;
    final nickname = args['nickname'] as String?;
    final description = args['description'] as String?;
    final creatorNotes = args['creatorNotes'] as String?;
    List<String>? tags;
    if (args['tags'] != null) {
      tags = (args['tags'] as List).cast<String>();
    }

    DateTime? worldStartDate;
    final worldStartDateRaw = args['worldStartDate'] as String?;
    if (worldStartDateRaw != null && worldStartDateRaw.isNotEmpty) {
      worldStartDate = DateTime.tryParse(worldStartDateRaw);
    }

    final character = Character(
      name: name,
      nickname: nickname,
      description: description,
      tags: tags,
      creatorNotes: creatorNotes,
      communityName: args['communityName'] as String?,
      communityMood: args['communityMood'] as String?,
      communityLanguage: args['communityLanguage'] as String?,
      worldStartDate: worldStartDate,
    );

    final id = await _db.createCharacter(character);

    return AgentToolResult(
      success: true,
      data: {'id': id, 'name': name},
      message: '캐릭터 "$name"을(를) 생성했습니다. (ID: $id)',
    );
  }
}

class UpdateCharacterTool extends AgentTool {
  final DatabaseHelper _db;

  UpdateCharacterTool(this._db);

  @override
  String get name => 'update_character';

  @override
  String get description => 'Update an existing character\'s fields.';

  @override
  List<AgentToolParameter> get parameters => [
    const AgentToolParameter(
      name: 'id',
      type: 'int',
      description: 'Character ID to update',
      required: true,
    ),
    const AgentToolParameter(
      name: 'name',
      type: 'string',
      description: 'New name (optional)',
    ),
    const AgentToolParameter(
      name: 'nickname',
      type: 'string',
      description: 'New nickname (optional)',
    ),
    const AgentToolParameter(
      name: 'description',
      type: 'string',
      description: 'New description (optional)',
    ),
    const AgentToolParameter(
      name: 'tags',
      type: 'List<string>',
      description: 'New tags (optional)',
    ),
    const AgentToolParameter(
      name: 'creatorNotes',
      type: 'string',
      description: 'New creator notes (optional)',
    ),
    const AgentToolParameter(
      name: 'communityName',
      type: 'string',
      description: 'New SNS community name / identity (optional)',
    ),
    const AgentToolParameter(
      name: 'communityMood',
      type: 'string',
      description: 'New SNS community mood / tone (optional)',
    ),
    const AgentToolParameter(
      name: 'communityLanguage',
      type: 'string',
      description: 'New SNS community language (optional)',
    ),
    const AgentToolParameter(
      name: 'worldStartDate',
      type: 'string',
      description:
          'New in-world start date as ISO 8601 (YYYY-MM-DD). Pass an empty string to clear.',
    ),
  ];

  @override
  Future<AgentToolResult> execute(Map<String, dynamic> args) async {
    final id = args['id'] as int;
    final character = await _db.readCharacter(id);
    if (character == null) {
      return const AgentToolResult(
        success: false,
        message: '해당 ID의 캐릭터를 찾을 수 없습니다.',
      );
    }

    List<String>? tags;
    if (args['tags'] != null) {
      tags = (args['tags'] as List).cast<String>();
    }

    DateTime? nextWorldStartDate = character.worldStartDate;
    if (args.containsKey('worldStartDate')) {
      final raw = args['worldStartDate'] as String?;
      nextWorldStartDate = (raw == null || raw.isEmpty)
          ? null
          : DateTime.tryParse(raw);
    }

    final updated = character.copyWith(
      name: args['name'] as String? ?? character.name,
      nickname: args['nickname'] as String? ?? character.nickname,
      description: args['description'] as String? ?? character.description,
      tags: tags ?? character.tags,
      creatorNotes: args['creatorNotes'] as String? ?? character.creatorNotes,
      communityName: args.containsKey('communityName')
          ? args['communityName'] as String?
          : character.communityName,
      communityMood: args.containsKey('communityMood')
          ? args['communityMood'] as String?
          : character.communityMood,
      communityLanguage: args.containsKey('communityLanguage')
          ? args['communityLanguage'] as String?
          : character.communityLanguage,
      worldStartDate: nextWorldStartDate,
      updatedAt: DateTime.now(),
    );

    await _db.updateCharacter(updated);

    return AgentToolResult(
      success: true,
      data: {'id': id, 'name': updated.name},
      message: '캐릭터 "${updated.name}"을(를) 수정했습니다.',
    );
  }
}

class CreatePersonaTool extends AgentTool {
  final DatabaseHelper _db;

  CreatePersonaTool(this._db);

  @override
  String get name => 'create_persona';

  @override
  String get description => 'Add a persona to a character.';

  @override
  List<AgentToolParameter> get parameters => [
    const AgentToolParameter(
      name: 'characterId',
      type: 'int',
      description: 'Character ID to add persona to',
      required: true,
    ),
    const AgentToolParameter(
      name: 'name',
      type: 'string',
      description: 'Persona name',
      required: true,
    ),
    const AgentToolParameter(
      name: 'content',
      type: 'string',
      description: 'Persona content/description (optional)',
    ),
  ];

  @override
  Future<AgentToolResult> execute(Map<String, dynamic> args) async {
    final characterId = args['characterId'] as int;
    final name = args['name'] as String;
    final content = args['content'] as String?;

    final character = await _db.readCharacter(characterId);
    if (character == null) {
      return const AgentToolResult(
        success: false,
        message: '해당 ID의 캐릭터를 찾을 수 없습니다.',
      );
    }

    final existingPersonas = await _db.readPersonas(characterId);

    final persona = Persona(
      characterId: characterId,
      name: name,
      order: existingPersonas.length,
      content: content,
    );

    final id = await _db.createPersona(persona);

    return AgentToolResult(
      success: true,
      data: {'id': id, 'name': name, 'characterId': characterId},
      message: '캐릭터 "${character.name}"에 페르소나 "$name"을(를) 추가했습니다.',
    );
  }
}

class UpdatePersonaTool extends AgentTool {
  final DatabaseHelper _db;

  UpdatePersonaTool(this._db);

  @override
  String get name => 'update_persona';

  @override
  String get description => 'Update an existing persona.';

  @override
  List<AgentToolParameter> get parameters => [
    const AgentToolParameter(
      name: 'id',
      type: 'int',
      description: 'Persona ID to update',
      required: true,
    ),
    const AgentToolParameter(
      name: 'name',
      type: 'string',
      description: 'New name (optional)',
    ),
    const AgentToolParameter(
      name: 'content',
      type: 'string',
      description: 'New content (optional)',
    ),
  ];

  @override
  Future<AgentToolResult> execute(Map<String, dynamic> args) async {
    final id = args['id'] as int;
    final persona = await _db.readPersona(id);
    if (persona == null) {
      return const AgentToolResult(
        success: false,
        message: '해당 ID의 페르소나를 찾을 수 없습니다.',
      );
    }

    final updated = persona.copyWith(
      name: args['name'] as String? ?? persona.name,
      content: args['content'] as String? ?? persona.content,
    );

    await _db.updatePersona(updated);

    return AgentToolResult(
      success: true,
      data: {'id': id, 'name': updated.name},
      message: '페르소나 "${updated.name}"을(를) 수정했습니다.',
    );
  }
}

class DeletePersonaTool extends AgentTool {
  final DatabaseHelper _db;

  DeletePersonaTool(this._db);

  @override
  String get name => 'delete_persona';

  @override
  String get description => 'Delete a persona by ID.';

  @override
  List<AgentToolParameter> get parameters => [
    const AgentToolParameter(
      name: 'id',
      type: 'int',
      description: 'Persona ID to delete',
      required: true,
    ),
  ];

  @override
  Future<AgentToolResult> execute(Map<String, dynamic> args) async {
    final id = args['id'] as int;
    final persona = await _db.readPersona(id);
    if (persona == null) {
      return const AgentToolResult(
        success: false,
        message: '해당 ID의 페르소나를 찾을 수 없습니다.',
      );
    }

    await _db.deletePersona(id);

    return AgentToolResult(
      success: true,
      data: {'id': id, 'name': persona.name},
      message: '페르소나 "${persona.name}"을(를) 삭제했습니다.',
    );
  }
}

// ── StartScenario Tools ──

class CreateStartScenarioTool extends AgentTool {
  final DatabaseHelper _db;

  CreateStartScenarioTool(this._db);

  @override
  String get name => 'create_start_scenario';

  @override
  String get description =>
      'Add a start scenario to a character. A start scenario defines the opening setting and first message of a conversation.';

  @override
  List<AgentToolParameter> get parameters => [
    const AgentToolParameter(
      name: 'characterId',
      type: 'int',
      description: 'Character ID to add scenario to',
      required: true,
    ),
    const AgentToolParameter(
      name: 'name',
      type: 'string',
      description: 'Scenario name',
      required: true,
    ),
    const AgentToolParameter(
      name: 'startSetting',
      type: 'string',
      description: 'Scene/situation description that sets the context (optional)',
    ),
    const AgentToolParameter(
      name: 'startMessage',
      type: 'string',
      description: 'The first message the character sends to open the conversation (optional)',
    ),
  ];

  @override
  Future<AgentToolResult> execute(Map<String, dynamic> args) async {
    final characterId = args['characterId'] as int;
    final scenarioName = args['name'] as String;
    final startSetting = args['startSetting'] as String?;
    final startMessage = args['startMessage'] as String?;

    final character = await _db.readCharacter(characterId);
    if (character == null) {
      return const AgentToolResult(
        success: false,
        message: '해당 ID의 캐릭터를 찾을 수 없습니다.',
      );
    }

    final existing = await _db.readStartScenarios(characterId);

    final scenario = StartScenario(
      characterId: characterId,
      name: scenarioName,
      order: existing.length,
      startSetting: startSetting,
      startMessage: startMessage,
    );

    final id = await _db.createStartScenario(scenario);

    return AgentToolResult(
      success: true,
      data: {'id': id, 'name': scenarioName, 'characterId': characterId},
      message: '캐릭터 "${character.name}"에 시작 시나리오 "$scenarioName"을(를) 추가했습니다.',
    );
  }
}

class UpdateStartScenarioTool extends AgentTool {
  final DatabaseHelper _db;

  UpdateStartScenarioTool(this._db);

  @override
  String get name => 'update_start_scenario';

  @override
  String get description => 'Update an existing start scenario.';

  @override
  List<AgentToolParameter> get parameters => [
    const AgentToolParameter(
      name: 'id',
      type: 'int',
      description: 'Start scenario ID to update',
      required: true,
    ),
    const AgentToolParameter(
      name: 'name',
      type: 'string',
      description: 'New name (optional)',
    ),
    const AgentToolParameter(
      name: 'startSetting',
      type: 'string',
      description: 'New scene/situation description (optional)',
    ),
    const AgentToolParameter(
      name: 'startMessage',
      type: 'string',
      description: 'New first message (optional)',
    ),
  ];

  @override
  Future<AgentToolResult> execute(Map<String, dynamic> args) async {
    final id = args['id'] as int;
    final scenarios = await _db.database.then((db) async {
      final maps = await db.query('start_scenarios', where: 'id = ?', whereArgs: [id]);
      return maps.map((m) => StartScenario.fromMap(m)).toList();
    });

    if (scenarios.isEmpty) {
      return const AgentToolResult(
        success: false,
        message: '해당 ID의 시작 시나리오를 찾을 수 없습니다.',
      );
    }

    final scenario = scenarios.first;
    final updated = scenario.copyWith(
      name: args['name'] as String? ?? scenario.name,
      startSetting: args['startSetting'] as String? ?? scenario.startSetting,
      startMessage: args['startMessage'] as String? ?? scenario.startMessage,
    );

    await _db.updateStartScenario(updated);

    return AgentToolResult(
      success: true,
      data: {'id': id, 'name': updated.name},
      message: '시작 시나리오 "${updated.name}"을(를) 수정했습니다.',
    );
  }
}

class DeleteStartScenarioTool extends AgentTool {
  final DatabaseHelper _db;

  DeleteStartScenarioTool(this._db);

  @override
  String get name => 'delete_start_scenario';

  @override
  String get description => 'Delete a start scenario by ID.';

  @override
  List<AgentToolParameter> get parameters => [
    const AgentToolParameter(
      name: 'id',
      type: 'int',
      description: 'Start scenario ID to delete',
      required: true,
    ),
  ];

  @override
  Future<AgentToolResult> execute(Map<String, dynamic> args) async {
    final id = args['id'] as int;
    final scenarios = await _db.database.then((db) async {
      final maps = await db.query('start_scenarios', where: 'id = ?', whereArgs: [id]);
      return maps.map((m) => StartScenario.fromMap(m)).toList();
    });

    if (scenarios.isEmpty) {
      return const AgentToolResult(
        success: false,
        message: '해당 ID의 시작 시나리오를 찾을 수 없습니다.',
      );
    }

    await _db.deleteStartScenario(id);

    return AgentToolResult(
      success: true,
      data: {'id': id, 'name': scenarios.first.name},
      message: '시작 시나리오 "${scenarios.first.name}"을(를) 삭제했습니다.',
    );
  }
}

// ── CharacterBook Tools ──

class CreateCharacterBookTool extends AgentTool {
  final DatabaseHelper _db;

  CreateCharacterBookTool(this._db);

  @override
  String get name => 'create_character_book';

  @override
  String get description =>
      'Add a knowledge entry (character book) to a character. Character books store lore organized by category (character/location/event/other). Each category has its own structured fields — only pass the fields relevant to the chosen category.';

  @override
  List<AgentToolParameter> get parameters => _characterBookCreateParameters;

  @override
  Future<AgentToolResult> execute(Map<String, dynamic> args) async {
    final characterId = args['characterId'] as int;
    final entryName = args['name'] as String;

    final character = await _db.readCharacter(characterId);
    if (character == null) {
      return const AgentToolResult(
        success: false,
        message: '해당 ID의 캐릭터를 찾을 수 없습니다.',
      );
    }

    final category = _parseCategory(args['category'] as String?) ??
        CharacterBookCategory.other;

    List<String>? keys;
    if (args['keys'] != null) {
      keys = (args['keys'] as List).cast<String>();
    }

    final enabled = _parseActivation(args['enabled'] as String?) ??
        CharacterBookActivationCondition.enabled;

    final existing = await _db.readCharacterBooks(characterId);

    final book = CharacterBook(
      characterId: characterId,
      folderId: args['folderId'] as int?,
      name: entryName,
      order: existing.length,
      enabled: enabled,
      keys: keys,
      category: category,
      oneLineDescription: (args['oneLineDescription'] as String?) ?? '',
      autoSummaryInsert: (args['autoSummaryInsert'] as bool?) ?? true,
    );

    _applyBookStructuredFields(book, args);

    final id = await _db.createCharacterBook(book);

    return AgentToolResult(
      success: true,
      data: {
        'id': id,
        'name': entryName,
        'characterId': characterId,
        'category': category.name,
      },
      message:
          '캐릭터 "${character.name}"에 ${category.displayName} 설정집 "$entryName"을(를) 추가했습니다.',
    );
  }
}

class UpdateCharacterBookTool extends AgentTool {
  final DatabaseHelper _db;

  UpdateCharacterBookTool(this._db);

  @override
  String get name => 'update_character_book';

  @override
  String get description =>
      'Update an existing character book entry. Only supplied fields are changed; pass category-specific fields only when you mean to change them (empty string clears the field).';

  @override
  List<AgentToolParameter> get parameters => _characterBookUpdateParameters;

  @override
  Future<AgentToolResult> execute(Map<String, dynamic> args) async {
    final id = args['id'] as int;
    final books = await _db.database.then((db) async {
      final maps = await db.query('character_books', where: 'id = ?', whereArgs: [id]);
      return maps.map((m) => CharacterBook.fromMap(m)).toList();
    });

    if (books.isEmpty) {
      return const AgentToolResult(
        success: false,
        message: '해당 ID의 캐릭터북을 찾을 수 없습니다.',
      );
    }

    final book = books.first;

    List<String>? keys;
    if (args['keys'] != null) {
      keys = (args['keys'] as List).cast<String>();
    }

    final enabled = _parseActivation(args['enabled'] as String?) ?? book.enabled;
    final category = _parseCategory(args['category'] as String?) ?? book.category;

    // If category changed, drop old structured data so stale fields don't bleed through.
    final preservedContent = category == book.category ? book.content : null;

    final updated = book.copyWith(
      name: args['name'] as String? ?? book.name,
      keys: keys ?? book.keys,
      enabled: enabled,
      category: category,
      oneLineDescription: args.containsKey('oneLineDescription')
          ? (args['oneLineDescription'] as String?) ?? ''
          : book.oneLineDescription,
      autoSummaryInsert: args.containsKey('autoSummaryInsert')
          ? (args['autoSummaryInsert'] as bool?) ?? book.autoSummaryInsert
          : book.autoSummaryInsert,
      content: preservedContent,
    );

    _applyBookStructuredFields(updated, args);

    await _db.updateCharacterBook(updated);

    return AgentToolResult(
      success: true,
      data: {
        'id': id,
        'name': updated.name,
        'category': updated.category.name,
      },
      message: '설정집 "${updated.name}"을(를) 수정했습니다.',
    );
  }
}

class DeleteCharacterBookTool extends AgentTool {
  final DatabaseHelper _db;

  DeleteCharacterBookTool(this._db);

  @override
  String get name => 'delete_character_book';

  @override
  String get description => 'Delete a character book entry by ID.';

  @override
  List<AgentToolParameter> get parameters => [
    const AgentToolParameter(
      name: 'id',
      type: 'int',
      description: 'Character book entry ID to delete',
      required: true,
    ),
  ];

  @override
  Future<AgentToolResult> execute(Map<String, dynamic> args) async {
    final id = args['id'] as int;
    final books = await _db.database.then((db) async {
      final maps = await db.query('character_books', where: 'id = ?', whereArgs: [id]);
      return maps.map((m) => CharacterBook.fromMap(m)).toList();
    });

    if (books.isEmpty) {
      return const AgentToolResult(
        success: false,
        message: '해당 ID의 캐릭터북을 찾을 수 없습니다.',
      );
    }

    await _db.deleteCharacterBook(id);

    return AgentToolResult(
      success: true,
      data: {'id': id, 'name': books.first.name},
      message: '캐릭터북 "${books.first.name}"을(를) 삭제했습니다.',
    );
  }
}

// ============================================================================
// CharacterBook tool helpers — shared between create/update
// ============================================================================

const List<AgentToolParameter> _characterBookBaseCreateParameters = [
  AgentToolParameter(
    name: 'characterId',
    type: 'int',
    description: 'Character ID',
    required: true,
  ),
  AgentToolParameter(
    name: 'name',
    type: 'string',
    description: 'Entry title. For category="character" use the person\'s name; for "location" the place name.',
    required: true,
  ),
  AgentToolParameter(
    name: 'category',
    type: 'string',
    description:
        'Category — determines which structured fields are valid. One of: "character" (persons/NPCs), "location" (places), "event" (historical events), "other" (world mechanics / rules / lore).',
    required: true,
  ),
  AgentToolParameter(
    name: 'oneLineDescription',
    type: 'string',
    description:
        'One-line summary. If non-empty, always injected with {{character_book}} as a quick reference regardless of activation condition. Written in English.',
  ),
  AgentToolParameter(
    name: 'autoSummaryInsert',
    type: 'bool',
    description:
        'When true (default), this entry is copied into the per-chat AgentEntry on the first message, so it is visible to the summary agent.',
  ),
  AgentToolParameter(
    name: 'enabled',
    type: 'string',
    description:
        'Activation condition: "enabled" (always injected), "keyBased" (injected only when keys match), "disabled". Defaults to "enabled".',
  ),
  AgentToolParameter(
    name: 'keys',
    type: 'List<string>',
    description: 'Trigger keywords for keyBased activation.',
  ),
  AgentToolParameter(
    name: 'folderId',
    type: 'int',
    description:
        'Folder ID — only meaningful for category="other". Character/location/event entries are grouped by category automatically.',
  ),
];

const List<AgentToolParameter> _characterBookStructuredParameters = [
  // character category
  AgentToolParameter(
    name: 'subNames',
    type: 'string',
    description:
        '[character] Comma-separated aliases used for <img> tag matching, e.g. "Alice, alice, 앨리스".',
  ),
  AgentToolParameter(
    name: 'appearance',
    type: 'string',
    description: '[character] Physical appearance. English.',
  ),
  AgentToolParameter(
    name: 'gender',
    type: 'string',
    description: '[character] One of: "male", "female", "other".',
  ),
  AgentToolParameter(
    name: 'genderOther',
    type: 'string',
    description: '[character] Free-form gender description when gender="other".',
  ),
  AgentToolParameter(
    name: 'age',
    type: 'string',
    description: '[character] Age (number or descriptor). English.',
  ),
  AgentToolParameter(
    name: 'personality',
    type: 'string',
    description: '[character] Personality traits and mannerisms. English.',
  ),
  AgentToolParameter(
    name: 'past',
    type: 'string',
    description: '[character] Background / history. English.',
  ),
  AgentToolParameter(
    name: 'abilities',
    type: 'string',
    description: '[character] Notable skills / powers. English.',
  ),
  AgentToolParameter(
    name: 'dialogueStyle',
    type: 'string',
    description: '[character] Speech style / catchphrases. English.',
  ),
  // location / other category
  AgentToolParameter(
    name: 'setting',
    type: 'string',
    description:
        '[location | other] Detailed setting description (for location: atmosphere, layout, notable features; for other: the rule, mechanic, or lore text). English.',
  ),
  // event category
  AgentToolParameter(
    name: 'datetime',
    type: 'string',
    description: '[event] When the event occurred (date or in-world time descriptor).',
  ),
  AgentToolParameter(
    name: 'eventContent',
    type: 'string',
    description: '[event] What happened. English.',
  ),
  AgentToolParameter(
    name: 'result',
    type: 'string',
    description: '[event] Aftermath / consequences. English.',
  ),
];

final List<AgentToolParameter> _characterBookCreateParameters = [
  ..._characterBookBaseCreateParameters,
  ..._characterBookStructuredParameters,
];

final List<AgentToolParameter> _characterBookUpdateParameters = [
  const AgentToolParameter(
    name: 'id',
    type: 'int',
    description: 'Character book entry ID',
    required: true,
  ),
  const AgentToolParameter(
    name: 'name',
    type: 'string',
    description: 'New entry title (optional).',
  ),
  const AgentToolParameter(
    name: 'category',
    type: 'string',
    description:
        'New category (optional). Changing category clears the previous structured content — re-pass the relevant fields for the new category.',
  ),
  const AgentToolParameter(
    name: 'oneLineDescription',
    type: 'string',
    description: 'New one-line summary (optional, empty string clears).',
  ),
  const AgentToolParameter(
    name: 'autoSummaryInsert',
    type: 'bool',
    description: 'Toggle AgentEntry auto-insert on first message (optional).',
  ),
  const AgentToolParameter(
    name: 'enabled',
    type: 'string',
    description: 'New activation condition: "enabled", "keyBased", "disabled" (optional).',
  ),
  const AgentToolParameter(
    name: 'keys',
    type: 'List<string>',
    description: 'New trigger keywords (optional).',
  ),
  ..._characterBookStructuredParameters,
];

CharacterBookCategory? _parseCategory(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  for (final c in CharacterBookCategory.values) {
    if (c.name == raw) return c;
  }
  return null;
}

CharacterBookActivationCondition? _parseActivation(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  for (final c in CharacterBookActivationCondition.values) {
    if (c.name == raw) return c;
  }
  return null;
}

/// Apply category-specific structured fields from [args] to [book].
/// Only fields explicitly present in [args] are touched — use an empty string
/// to clear a field. Fields irrelevant to the current category are ignored.
void _applyBookStructuredFields(CharacterBook book, Map<String, dynamic> args) {
  String? take(String key) =>
      args.containsKey(key) ? ((args[key] as String?) ?? '') : null;

  switch (book.category) {
    case CharacterBookCategory.character:
      final subNames = take('subNames');
      if (subNames != null) book.subNames = subNames;
      final appearance = take('appearance');
      if (appearance != null) book.appearance = appearance;
      if (args.containsKey('gender')) {
        final raw = args['gender'] as String?;
        if (raw == null || raw.isEmpty) {
          book.gender = null;
        } else {
          book.gender = CharacterBookGender.values.firstWhere(
            (e) => e.name == raw,
            orElse: () => CharacterBookGender.other,
          );
        }
      }
      final genderOther = take('genderOther');
      if (genderOther != null) book.genderOther = genderOther;
      final age = take('age');
      if (age != null) book.age = age;
      final personality = take('personality');
      if (personality != null) book.personality = personality;
      final past = take('past');
      if (past != null) book.past = past;
      final abilities = take('abilities');
      if (abilities != null) book.abilities = abilities;
      final dialogueStyle = take('dialogueStyle');
      if (dialogueStyle != null) book.dialogueStyle = dialogueStyle;
      break;
    case CharacterBookCategory.location:
    case CharacterBookCategory.other:
      final setting = take('setting');
      if (setting != null) book.setting = setting;
      break;
    case CharacterBookCategory.event:
      final datetime = take('datetime');
      if (datetime != null) book.eventDatetime = datetime;
      final eventContent = take('eventContent');
      if (eventContent != null) book.eventContent = eventContent;
      final result = take('result');
      if (result != null) book.eventResult = result;
      break;
  }
}
