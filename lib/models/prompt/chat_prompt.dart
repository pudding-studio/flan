import 'dart:convert';

import 'prompt_item.dart';
import 'prompt_parameters.dart';

class ChatPrompt {
  final int? id;
  final String name;
  final String? description;
  final String supportedModel;
  final PromptParameters? parameters;
  final bool isSelected;
  final int order;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<PromptItem> items;

  ChatPrompt({
    this.id,
    required this.name,
    this.description,
    String? supportedModel,
    this.parameters,
    this.isSelected = false,
    this.order = 0,
    List<PromptItem>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : supportedModel = supportedModel ?? 'ALL',
        items = items ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory ChatPrompt.fromMap(Map<String, dynamic> map) {
    return ChatPrompt(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String?,
      supportedModel: map['supported_model'] as String? ?? 'ALL',
      parameters: map['parameters'] != null
          ? PromptParameters.fromJson(jsonDecode(map['parameters'] as String))
          : null,
      isSelected: (map['is_selected'] as int? ?? 0) == 1,
      order: map['order'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'supported_model': supportedModel,
      'parameters': parameters != null ? jsonEncode(parameters!.toJson()) : null,
      'is_selected': isSelected ? 1 : 0,
      'order': order,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ChatPrompt copyWith({
    int? id,
    String? name,
    String? description,
    String? supportedModel,
    PromptParameters? parameters,
    bool? isSelected,
    int? order,
    List<PromptItem>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChatPrompt(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      supportedModel: supportedModel ?? this.supportedModel,
      parameters: parameters ?? this.parameters,
      isSelected: isSelected ?? this.isSelected,
      order: order ?? this.order,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'supportedModel': supportedModel,
      'parameters': parameters?.toJson(),
      'items': items.map((item) => item.toMap()).toList(),
    };
  }

  factory ChatPrompt.fromJson(Map<String, dynamic> json) {
    return ChatPrompt(
      name: json['name'] as String,
      description: json['description'] as String?,
      supportedModel: json['supportedModel'] as String?,
      parameters: json['parameters'] != null
          ? PromptParameters.fromJson(json['parameters'] as Map<String, dynamic>)
          : null,
      items: (json['items'] as List<dynamic>?)
          ?.map((item) => PromptItem.fromMap(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
