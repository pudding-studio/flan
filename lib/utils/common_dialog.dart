import 'package:flutter/material.dart';

class CommonDialog {
  static Future<bool?> showConfirmation({
    required BuildContext context,
    required String title,
    required String content,
    String confirmText = '확인',
    String cancelText = '취소',
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelText),
          ),
          if (isDestructive)
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: Text(confirmText),
            )
          else
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(confirmText),
            ),
        ],
      ),
    );
  }

  static Future<void> showInfo({
    required BuildContext context,
    String? title,
    required String content,
    String confirmText = '확인',
  }) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: title != null ? Text(title) : null,
        contentPadding: const EdgeInsets.fromLTRB(24, 30, 24, 10),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  static void showSnackBar({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 2),
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        action: action,
      ),
    );
  }

  static Future<bool> showDeleteConfirmation({
    required BuildContext context,
    required String itemName,
  }) async {
    final result = await showConfirmation(
      context: context,
      title: '삭제 확인',
      content: '$itemName을(를) 삭제하시겠습니까?',
      confirmText: '삭제',
      cancelText: '취소',
      isDestructive: true,
    );
    return result ?? false;
  }

  CommonDialog._();
}
