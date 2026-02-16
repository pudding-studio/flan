import 'dart:convert';
import 'package:flutter/services.dart';

enum SummaryPromptRole {
  system,
  user,
  assistant,
  summary;

  String get displayName {
    switch (this) {
      case SummaryPromptRole.system:
        return '시스템';
      case SummaryPromptRole.user:
        return '사용자';
      case SummaryPromptRole.assistant:
        return '모델';
      case SummaryPromptRole.summary:
        return '요약대상';
    }
  }
}

class SummaryPromptItem {
  final SummaryPromptRole role;
  final String content;
  final String? name;
  final int order;
  bool isExpanded;

  SummaryPromptItem({
    required this.role,
    this.content = '',
    this.name,
    this.order = 0,
    this.isExpanded = false,
  });

  factory SummaryPromptItem.fromJson(Map<String, dynamic> json) {
    return SummaryPromptItem(
      role: SummaryPromptRole.values.firstWhere(
        (r) => r.name == (json['role'] as String? ?? 'user'),
        orElse: () => SummaryPromptRole.user,
      ),
      content: json['content'] as String? ?? '',
      name: json['name'] as String?,
      order: json['order'] as int? ?? 0,
      isExpanded: json['isExpanded'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'role': role.name,
      'content': content,
      'name': name,
      'order': order,
      'isExpanded': isExpanded,
    };
  }

  SummaryPromptItem copyWith({
    SummaryPromptRole? role,
    String? content,
    String? name,
    int? order,
    bool? isExpanded,
  }) {
    return SummaryPromptItem(
      role: role ?? this.role,
      content: content ?? this.content,
      name: name ?? this.name,
      order: order ?? this.order,
      isExpanded: isExpanded ?? this.isExpanded,
    );
  }

  static List<SummaryPromptItem> listFromJson(String? jsonString) {
    if (jsonString == null || jsonString.isEmpty) return [];
    final List<dynamic> list = jsonDecode(jsonString);
    return list.map((e) => SummaryPromptItem.fromJson(e)).toList();
  }

  static String listToJson(List<SummaryPromptItem> items) {
    return jsonEncode(items.map((e) => e.toJson()).toList());
  }

  static Future<List<SummaryPromptItem>> loadDefaultItems() async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/defaults/summary_prompts/default_summary.json',
      );
      final List<dynamic> list = jsonDecode(jsonString);
      return list.map((e) => SummaryPromptItem.fromJson(e)).toList();
    } catch (_) {
      return defaultItems();
    }
  }

  static List<SummaryPromptItem> defaultItems() {
    return [
      SummaryPromptItem(
        role: SummaryPromptRole.user,
        content: 'Please summarize the following conversation concisely.',
        order: 0,
      ),
      SummaryPromptItem(
        role: SummaryPromptRole.summary,
        content: '',
        order: 1,
      ),
    ];
  }
}
