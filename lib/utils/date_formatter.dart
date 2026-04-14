import '../l10n/app_localizations.dart';

class DateFormatter {
  static String formatRelativeDate(DateTime dateTime, AppLocalizations l10n) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return l10n.chatDateToday;
    } else if (difference.inDays == 1) {
      return l10n.chatDateYesterday;
    } else if (difference.inDays < 7) {
      return l10n.chatDateDaysAgo(difference.inDays);
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return l10n.chatDateWeeksAgo(weeks);
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return l10n.chatDateMonthsAgo(months);
    } else {
      final years = (difference.inDays / 365).floor();
      return l10n.chatDateYearsAgo(years);
    }
  }

  /// For UI display: "2026.04.14 09:30"
  static String formatDateTime(DateTime dt) {
    return '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  /// For AI prompts: "2026-04-14 09:30"
  static String formatPromptDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
