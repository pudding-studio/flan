import 'prompt_item.dart';

class PromptItemFolder {
  final int? id;
  final int? chatPromptId;
  String name;
  int order;
  bool isExpanded;
  List<PromptItem> items;

  PromptItemFolder({
    this.id,
    this.chatPromptId,
    required this.name,
    required this.order,
    this.isExpanded = true,
    List<PromptItem>? items,
  }) : items = items ?? [];

  factory PromptItemFolder.fromMap(Map<String, dynamic> map) {
    return PromptItemFolder(
      id: map['id'] as int?,
      chatPromptId: map['chat_prompt_id'] as int?,
      name: map['name'] as String,
      order: map['order'] as int,
      isExpanded: (map['is_expanded'] as int?) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chat_prompt_id': chatPromptId,
      'name': name,
      'order': order,
      'is_expanded': isExpanded ? 1 : 0,
    };
  }

  PromptItemFolder copyWith({
    int? id,
    int? chatPromptId,
    String? name,
    int? order,
    bool? isExpanded,
    List<PromptItem>? items,
  }) {
    return PromptItemFolder(
      id: id ?? this.id,
      chatPromptId: chatPromptId ?? this.chatPromptId,
      name: name ?? this.name,
      order: order ?? this.order,
      isExpanded: isExpanded ?? this.isExpanded,
      items: items ?? this.items,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chatPromptId': chatPromptId,
      'name': name,
      'order': order,
      'isExpanded': isExpanded,
      'items': items.map((e) => e.toJson()).toList(),
    };
  }

  factory PromptItemFolder.fromJson(Map<String, dynamic> json) {
    return PromptItemFolder(
      id: json['id'] as int?,
      chatPromptId: json['chatPromptId'] as int?,
      name: json['name'] as String,
      order: json['order'] as int,
      isExpanded: json['isExpanded'] as bool? ?? true,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => PromptItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
