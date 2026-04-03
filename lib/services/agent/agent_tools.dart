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
  String get description => 'Get full details of a character including its personas.';

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
        'createdAt': character.createdAt.toIso8601String(),
        'updatedAt': character.updatedAt.toIso8601String(),
        'personas': personas.map((p) => {
          'id': p.id,
          'name': p.name,
          'content': p.content,
          'order': p.order,
        }).toList(),
      },
      message: '캐릭터 "${character.name}" 정보를 가져왔습니다.',
    );
  }
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

    final character = Character(
      name: name,
      nickname: nickname,
      description: description,
      tags: tags,
      creatorNotes: creatorNotes,
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

    final updated = character.copyWith(
      name: args['name'] as String? ?? character.name,
      nickname: args['nickname'] as String? ?? character.nickname,
      description: args['description'] as String? ?? character.description,
      tags: tags ?? character.tags,
      creatorNotes: args['creatorNotes'] as String? ?? character.creatorNotes,
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
      'Add a knowledge entry (character book) to a character. Character books store lore, world-building facts, or supplementary information that gets injected into prompts.';

  @override
  List<AgentToolParameter> get parameters => [
    const AgentToolParameter(
      name: 'characterId',
      type: 'int',
      description: 'Character ID',
      required: true,
    ),
    const AgentToolParameter(
      name: 'name',
      type: 'string',
      description: 'Entry name / title',
      required: true,
    ),
    const AgentToolParameter(
      name: 'content',
      type: 'string',
      description: 'The lore / knowledge content',
      required: true,
    ),
    const AgentToolParameter(
      name: 'keys',
      type: 'List<string>',
      description: 'Trigger keywords — entry is activated when these appear in conversation (optional)',
    ),
    const AgentToolParameter(
      name: 'enabled',
      type: 'string',
      description: 'Activation condition: "enabled" (always on), "keyBased" (trigger by keys), "disabled" (off). Defaults to "enabled".',
    ),
    const AgentToolParameter(
      name: 'folderId',
      type: 'int',
      description: 'Folder ID to put this entry in (optional, standalone if omitted)',
    ),
  ];

  @override
  Future<AgentToolResult> execute(Map<String, dynamic> args) async {
    final characterId = args['characterId'] as int;
    final entryName = args['name'] as String;
    final content = args['content'] as String;

    final character = await _db.readCharacter(characterId);
    if (character == null) {
      return const AgentToolResult(
        success: false,
        message: '해당 ID의 캐릭터를 찾을 수 없습니다.',
      );
    }

    List<String>? keys;
    if (args['keys'] != null) {
      keys = (args['keys'] as List).cast<String>();
    }

    final enabledStr = args['enabled'] as String? ?? 'enabled';
    final enabled = CharacterBookActivationCondition.values.firstWhere(
      (e) => e.name == enabledStr,
      orElse: () => CharacterBookActivationCondition.enabled,
    );

    final existing = await _db.readCharacterBooks(characterId);

    final book = CharacterBook(
      characterId: characterId,
      folderId: args['folderId'] as int?,
      name: entryName,
      order: existing.length,
      enabled: enabled,
      keys: keys,
      content: content,
    );

    final id = await _db.createCharacterBook(book);

    return AgentToolResult(
      success: true,
      data: {'id': id, 'name': entryName, 'characterId': characterId},
      message: '캐릭터 "${character.name}"에 캐릭터북 "$entryName"을(를) 추가했습니다.',
    );
  }
}

class UpdateCharacterBookTool extends AgentTool {
  final DatabaseHelper _db;

  UpdateCharacterBookTool(this._db);

  @override
  String get name => 'update_character_book';

  @override
  String get description => 'Update an existing character book entry.';

  @override
  List<AgentToolParameter> get parameters => [
    const AgentToolParameter(
      name: 'id',
      type: 'int',
      description: 'Character book entry ID',
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
    const AgentToolParameter(
      name: 'keys',
      type: 'List<string>',
      description: 'New trigger keywords (optional)',
    ),
    const AgentToolParameter(
      name: 'enabled',
      type: 'string',
      description: 'New activation condition: "enabled", "keyBased", "disabled" (optional)',
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

    final book = books.first;
    List<String>? keys;
    if (args['keys'] != null) {
      keys = (args['keys'] as List).cast<String>();
    }

    CharacterBookActivationCondition? enabled;
    if (args['enabled'] != null) {
      enabled = CharacterBookActivationCondition.values.firstWhere(
        (e) => e.name == args['enabled'],
        orElse: () => book.enabled,
      );
    }

    final updated = book.copyWith(
      name: args['name'] as String? ?? book.name,
      content: args['content'] as String? ?? book.content,
      keys: keys ?? book.keys,
      enabled: enabled ?? book.enabled,
    );

    await _db.updateCharacterBook(updated);

    return AgentToolResult(
      success: true,
      data: {'id': id, 'name': updated.name},
      message: '캐릭터북 "${updated.name}"을(를) 수정했습니다.',
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
