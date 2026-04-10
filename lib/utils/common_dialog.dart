import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class CommonDialog {
  static Future<bool?> showConfirmation({
    required BuildContext context,
    required String title,
    required String content,
    String? confirmText,
    String? cancelText,
    bool isDestructive = false,
  }) {
    final l10n = AppLocalizations.of(context);
    final resolvedConfirm = confirmText ?? l10n.commonConfirm;
    final resolvedCancel = cancelText ?? l10n.commonCancel;
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(resolvedCancel),
          ),
          if (isDestructive)
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: Text(resolvedConfirm),
            )
          else
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(resolvedConfirm),
            ),
        ],
      ),
    );
  }

  static Future<void> showInfo({
    required BuildContext context,
    String? title,
    required String content,
    String? confirmText,
  }) {
    final resolvedConfirm =
        confirmText ?? AppLocalizations.of(context).commonConfirm;
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: title != null ? Text(title) : null,
        contentPadding: const EdgeInsets.fromLTRB(24, 30, 24, 10),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(resolvedConfirm),
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
    final l10n = AppLocalizations.of(context);
    final result = await showConfirmation(
      context: context,
      title: l10n.commonDeleteConfirmTitle,
      content: l10n.commonDeleteConfirmContent(itemName),
      confirmText: l10n.commonDelete,
      cancelText: l10n.commonCancel,
      isDestructive: true,
    );
    return result ?? false;
  }

  CommonDialog._();
}
