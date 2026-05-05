import 'package:cloud_firestore/cloud_firestore.dart';

String? readStringByPaths(Map<String, dynamic> data, List<String> paths) {
  for (final path in paths) {
    final value = readValueByPath(data, path);
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
  }

  return null;
}

bool? readBoolByPaths(Map<String, dynamic> data, List<String> paths) {
  for (final path in paths) {
    final value = readValueByPath(data, path);
    if (value is bool) {
      return value;
    }
  }

  return null;
}

DateTime? readDateTimeByPaths(Map<String, dynamic> data, List<String> paths) {
  for (final path in paths) {
    final value = readValueByPath(data, path);
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) {
        return parsed;
      }
    }
  }

  return null;
}

Object? readValueByPath(Map<String, dynamic> data, String path) {
  Object? current = data;
  for (final segment in path.split('.')) {
    if (current is Map && current.containsKey(segment)) {
      current = current[segment];
      continue;
    }

    return null;
  }

  return current;
}

String formatStatusLabel(String status) {
  final normalized = status.trim();
  if (normalized.isEmpty) {
    return 'Unknown';
  }

  final words = normalized
      .replaceAll('_', ' ')
      .replaceAll('-', ' ')
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty);

  return words
      .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');
}

String formatChatTimestamp(DateTime? date, {bool isPending = false}) {
  if (isPending || date == null) {
    return 'Sending...';
  }

  final local = date.toLocal();
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final suffix = local.hour >= 12 ? 'PM' : 'AM';
  final now = DateTime.now();
  final isToday =
      local.year == now.year &&
      local.month == now.month &&
      local.day == now.day;

  if (isToday) {
    return '$hour:$minute $suffix';
  }

  return '${local.month}/${local.day} $hour:$minute $suffix';
}
