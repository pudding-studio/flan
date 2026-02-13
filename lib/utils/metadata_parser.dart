import '../models/chat/chat_message_metadata.dart';

class MetadataParser {
  static final _locationPattern = RegExp(r'\[📍\|([^\]]*)\]');
  static final _datePattern = RegExp(r'\[📅\|([^\]]*)\]');
  static final _timePattern = RegExp(r'\[🕰\|([^\]]*)\]');

  static ({String? location, String? date, String? time}) parse(String content) {
    final locationMatch = _locationPattern.firstMatch(content);
    final dateMatch = _datePattern.firstMatch(content);
    final timeMatch = _timePattern.firstMatch(content);

    return (
      location: locationMatch?.group(1),
      date: dateMatch?.group(1),
      time: timeMatch?.group(1),
    );
  }

  static String _addMinutes(String time, int minutes) {
    final parts = time.split(':');
    if (parts.length != 2) return time;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return time;

    final totalMinutes = hour * 60 + minute + minutes;
    final newHour = (totalMinutes ~/ 60) % 24;
    final newMinute = totalMinutes % 60;

    return '${newHour.toString().padLeft(2, '0')}:${newMinute.toString().padLeft(2, '0')}';
  }

  static ChatMessageMetadata buildMetadata({
    required int chatMessageId,
    required int chatRoomId,
    required String content,
    ChatMessageMetadata? previous,
  }) {
    final parsed = parse(content);

    final location = parsed.location ?? previous?.location;
    final date = parsed.date ?? previous?.date;

    String? time;
    if (parsed.time != null) {
      time = parsed.time;
    } else if (previous?.time != null) {
      time = _addMinutes(previous!.time!, 10);
    }

    return ChatMessageMetadata(
      chatMessageId: chatMessageId,
      chatRoomId: chatRoomId,
      location: location,
      date: date,
      time: time,
    );
  }

  static int _timeToMinutes(String time) {
    final parts = time.split(':');
    if (parts.length != 2) return -1;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return -1;
    return hour * 60 + minute;
  }

  static bool shouldAutoPin(ChatMessageMetadata current, ChatMessageMetadata? previous) {
    if (previous == null) return false;

    if (current.location != null && previous.location != null &&
        current.location != previous.location) {
      return true;
    }

    if (current.date != null && previous.date != null &&
        current.date != previous.date) {
      return true;
    }

    if (current.time != null && previous.time != null) {
      final currentMinutes = _timeToMinutes(current.time!);
      final previousMinutes = _timeToMinutes(previous.time!);
      if (currentMinutes >= 0 && previousMinutes >= 0) {
        final diff = (currentMinutes - previousMinutes).abs();
        if (diff >= 180) return true;
      }
    }

    return false;
  }

  static bool hasMetadataPattern(String content) {
    return _locationPattern.hasMatch(content) ||
        _datePattern.hasMatch(content) ||
        _timePattern.hasMatch(content);
  }

  static final _locationLinePattern = RegExp(r'^\[📍\|[^\]]*\]\s*\n?', multiLine: true);
  static final _dateLinePattern = RegExp(r'^\[📅\|[^\]]*\]\s*\n?', multiLine: true);
  static final _timeLinePattern = RegExp(r'^\[🕰\|[^\]]*\]\s*\n?', multiLine: true);

  static String removeMetadataTags(String content) {
    var result = content
        .replaceAll(_locationLinePattern, '')
        .replaceAll(_dateLinePattern, '')
        .replaceAll(_timeLinePattern, '')
        .replaceAll(_locationPattern, '')
        .replaceAll(_datePattern, '')
        .replaceAll(_timePattern, '');
    result = result.replaceAll(RegExp(r'^\n+'), '');
    return result.trim();
  }

  static const _dayNamesEn = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  static String _formatDateForScene(String date) {
    final segments = date.split('.');
    if (segments.length != 3) return date;
    final year = int.tryParse(segments[0]);
    final month = int.tryParse(segments[1]);
    final day = int.tryParse(segments[2]);
    if (year == null || month == null || day == null) return date;
    final dt = DateTime(year, month, day);
    final dayName = _dayNamesEn[dt.weekday - 1];
    return '${segments[0]}-${segments[1].padLeft(2, '0')}-${segments[2].padLeft(2, '0')}($dayName)';
  }

  static String _formatTimeForScene(String time) {
    final parts = time.split(':');
    if (parts.length != 2) return time;
    final hour = int.tryParse(parts[0]);
    if (hour == null) return time;
    final period = (hour >= 6 && hour < 18) ? 'Day' : 'Night';
    return '$time($period)';
  }

  static String buildSceneOpenTag({
    required int sceneNumber,
    required ChatMessageMetadata metadata,
  }) {
    final infoParts = <String>[];
    if (metadata.location != null) infoParts.add(metadata.location!);
    if (metadata.date != null) {
      infoParts.add('Date=${_formatDateForScene(metadata.date!)}');
    }
    if (metadata.time != null) {
      infoParts.add('Time=${_formatTimeForScene(metadata.time!)}');
    }
    final infoStr = infoParts.join('|');
    return '<$sceneNumber>\n<Info>$infoStr</Info>';
  }

  static String buildSceneCloseTag(int sceneNumber) {
    return '</$sceneNumber>';
  }

  /// 종료된 씬의 열기 태그 (시작~종료 시간 포함)
  static String buildSceneOpenTagWithEndTime({
    required int sceneNumber,
    required ChatMessageMetadata startMetadata,
    required ChatMessageMetadata endMetadata,
  }) {
    final infoParts = <String>[];
    if (startMetadata.location != null) infoParts.add(startMetadata.location!);
    if (startMetadata.date != null) {
      infoParts.add('Date=${_formatDateForScene(startMetadata.date!)}');
    }
    if (startMetadata.time != null && endMetadata.time != null) {
      infoParts.add(
        'Time=${_formatTimeForScene(startMetadata.time!)}~${_formatTimeForScene(endMetadata.time!)}',
      );
    } else if (startMetadata.time != null) {
      infoParts.add('Time=${_formatTimeForScene(startMetadata.time!)}');
    }
    final infoStr = infoParts.join('|');
    return '<$sceneNumber>\n<Info>$infoStr</Info>';
  }
}
