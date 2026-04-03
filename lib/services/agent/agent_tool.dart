import 'dart:convert';

class AgentToolParameter {
  final String name;
  final String type;
  final String description;
  final bool required;

  const AgentToolParameter({
    required this.name,
    required this.type,
    required this.description,
    this.required = false,
  });

  Map<String, dynamic> toSchema() => {
    'name': name,
    'type': type,
    'description': description,
    'required': required,
  };
}

class AgentToolResult {
  final bool success;
  final dynamic data;
  final String message;

  const AgentToolResult({
    required this.success,
    this.data,
    required this.message,
  });

  String toJsonString() => jsonEncode({
    'success': success,
    'message': message,
    if (data != null) 'data': data,
  });
}

abstract class AgentTool {
  String get name;
  String get description;
  List<AgentToolParameter> get parameters;

  Future<AgentToolResult> execute(Map<String, dynamic> args);

  Map<String, dynamic> toSchema() => {
    'name': name,
    'description': description,
    'parameters': parameters.map((p) => p.toSchema()).toList(),
  };
}
