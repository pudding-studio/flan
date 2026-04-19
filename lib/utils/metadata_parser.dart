import '../models/chat/chat_message_metadata.dart';
import 'date_formatter.dart';

class CharacterTag {
  final bool isMain; // 👤 = main, 👥 = sub
  final String name;
  final String? outfit;
  final String? memo;

  const CharacterTag({
    required this.isMain,
    required this.name,
    this.outfit,
    this.memo,
  });
}

class MetadataParser {
  static final _locationPattern = RegExp(r'【📍\|?([^】]*)】');
  static final _datePattern = RegExp(r'【📅\|?([^】]*)】');
  static final _timePattern = RegExp(r'【🕰\|?([^】]*)】');
  static final _pinPattern = RegExp(r'【📌\|?([^】]*)】', caseSensitive: false);
  static final _characterPattern = RegExp(r'【(👤|👥)\|?([^】]*)】');

  // Split by | or by lookahead on sub-field emoji markers (handles missing |)
  static final _charFieldSplitter = RegExp(r'\|(?=👔:|📝:)|(?=👔:|📝:)|\|');

  static List<CharacterTag> parseCharacterTags(String content) {
    final matches = _characterPattern.allMatches(content);
    return matches.map((m) {
      final isMain = m.group(1) == '👤';
      final parts = m.group(2)!
          .split(_charFieldSplitter)
          .where((p) => p.isNotEmpty)
          .toList();
      final name = parts[0];
      String? outfit;
      String? memo;
      for (var i = 1; i < parts.length; i++) {
        final part = parts[i];
        if (part.startsWith('👔:')) {
          outfit = part.substring(3);
        } else if (part.startsWith('📝:')) {
          memo = part.substring(3);
        }
      }
      return CharacterTag(isMain: isMain, name: name, outfit: outfit, memo: memo);
    }).toList();
  }

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

  /// 📌 태그에서 AI 자동 핀 ON/OFF 파싱
  /// 【📌|ON】 → true, 【📌|OFF】 → false, 없으면 null
  static bool? parseAiPinTag(String content) {
    final match = _pinPattern.firstMatch(content);
    if (match == null) return null;
    final value = match.group(1)?.trim().toUpperCase();
    if (value == 'ON') return true;
    if (value == 'OFF') return false;
    return null;
  }

  /// 옵션별 자동 핀 판정
  static bool shouldAutoPinWithOptions(
    ChatMessageMetadata current,
    ChatMessageMetadata? previous, {
    required bool byDate,
    required bool byLocation,
  }) {
    if (previous == null) return false;

    // 장소 기준
    if (byLocation &&
        current.location != null && previous.location != null &&
        current.location != previous.location) {
      return true;
    }

    // 날짜 기준
    if (byDate &&
        current.date != null && previous.date != null &&
        current.date != previous.date) {
      return true;
    }

    return false;
  }

  static final _bracketTagLinePattern = RegExp(r'^【[^】]*】\s*\n?', multiLine: true);
  static final _bracketTagPattern = RegExp(r'【[^】]*】');

  static bool hasMetadataPattern(String content) {
    return _bracketTagPattern.hasMatch(content);
  }

  static String removeMetadataTags(String content) {
    var result = content
        .replaceAll(_bracketTagLinePattern, '')
        .replaceAll(_bracketTagPattern, '');
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
    DateTime? worldStartDate,
  }) {
    final infoParts = <String>[];
    if (metadata.location != null) infoParts.add(metadata.location!);
    final resolvedDate =
        DateFormatter.canonicalMetadataDate(metadata.date, worldStartDate);
    infoParts.add('Date=${_formatDateForScene(resolvedDate)}');
    if (metadata.time != null && metadata.time!.isNotEmpty) {
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
    DateTime? worldStartDate,
  }) {
    final infoParts = <String>[];
    if (startMetadata.location != null) infoParts.add(startMetadata.location!);
    final resolvedDate = DateFormatter.canonicalMetadataDate(
      startMetadata.date,
      worldStartDate,
    );
    infoParts.add('Date=${_formatDateForScene(resolvedDate)}');
    final hasStartTime =
        startMetadata.time != null && startMetadata.time!.isNotEmpty;
    final hasEndTime = endMetadata.time != null && endMetadata.time!.isNotEmpty;
    if (hasStartTime && hasEndTime) {
      infoParts.add(
        'Time=${_formatTimeForScene(startMetadata.time!)}~${_formatTimeForScene(endMetadata.time!)}',
      );
    } else if (hasStartTime) {
      infoParts.add('Time=${_formatTimeForScene(startMetadata.time!)}');
    }
    final infoStr = infoParts.join('|');
    return '<$sceneNumber>\n<Info>$infoStr</Info>';
  }
}
