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

  /// Parses chat message metadata date/time tags ("YYYY.MM.DD" + "HH:MM") into
  /// a DateTime. Returns null when the date is missing or malformed.
  static DateTime? parseMetadataDateTime(String? date, String? time) {
    if (date == null || date.isEmpty) return null;
    final dParts = date.split('.');
    if (dParts.length != 3) return null;
    final y = int.tryParse(dParts[0]);
    final m = int.tryParse(dParts[1]);
    final d = int.tryParse(dParts[2]);
    if (y == null || m == null || d == null) return null;

    var hour = 0;
    var minute = 0;
    if (time != null && time.isNotEmpty) {
      final tParts = time.split(':');
      if (tParts.length == 2) {
        hour = int.tryParse(tParts[0]) ?? 0;
        minute = int.tryParse(tParts[1]) ?? 0;
      }
    }
    return DateTime(y, m, d, hour, minute);
  }

  /// Returns a canonical "YYYY.MM.DD" date string for AI prompts. Never null:
  /// falls back through metadata → [worldStartDate] → the current wall clock
  /// so downstream tags always carry a date.
  static String canonicalMetadataDate(String? rawDate, DateTime? worldStartDate) {
    if (rawDate != null && rawDate.isNotEmpty) {
      final parts = rawDate.split('.');
      if (parts.length == 3) {
        final y = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        final d = int.tryParse(parts[2]);
        if (y != null && m != null && d != null) {
          return _formatYMD(y, m, d);
        }
      }
    }
    final fallback = worldStartDate ?? DateTime.now();
    return _formatYMD(fallback.year, fallback.month, fallback.day);
  }

  static String _formatYMD(int y, int m, int d) =>
      '${y.toString().padLeft(4, '0')}.'
      '${m.toString().padLeft(2, '0')}.'
      '${d.toString().padLeft(2, '0')}';
}
