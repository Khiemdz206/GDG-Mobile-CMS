import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// event.dart
/// Layer: Data
/// Feature: Events
/// Description: Model sự kiện và cách đọc danh sách sự kiện từ Supabase.

/// Một sự kiện của CLB (một dòng bảng `events`).
class Event {
  final String id;
  final String title;
  final String description;
  final String location;
  final DateTime? startAt;
  final String authorName;
  final int participantCount;

  const Event({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.startAt,
    required this.authorName,
    required this.participantCount,
  });

  /// Tạo từ kết quả của [EventRepository.selectColumns].
  factory Event.fromRow(Map<String, dynamic> row) {
    final Object? author = row['author'];
    final Object? participants = row['event_participants'];
    final String? startAtText = row['start_at'] as String?;

    return Event(
      id: row['id'] as String,
      title: (row['title'] as String?)?.trim() ?? '',
      description: (row['description'] as String?)?.trim() ?? '',
      location: (row['location'] as String?)?.trim() ?? '',
      startAt: startAtText == null ? null : DateTime.parse(startAtText),
      authorName: author is Map<String, dynamic> ? _displayName(author) : '',
      // PostgREST trả số đếm dạng [{"count": 3}].
      participantCount:
          participants is List &&
              participants.isNotEmpty &&
              participants.first is Map
          ? ((participants.first as Map)['count'] as num?)?.toInt() ?? 0
          : 0,
    );
  }

  static String _displayName(Map<String, dynamic> author) {
    final String fullName = [author['first_name'], author['last_name']]
        .whereType<String>()
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .join(' ');
    if (fullName.isNotEmpty) return fullName;
    return (author['username'] as String?)?.trim() ?? '';
  }

  /// Thời gian hiển thị, ví dụ "Ngày 05 tháng 12, 2026 lúc 18:30".
  String get timeLabel {
    final DateTime? start = startAt;
    if (start == null) return 'Chưa có lịch';
    return DateFormat(
      "'Ngày' dd 'tháng' MM, yyyy 'lúc' HH:mm",
    ).format(start.toLocal());
  }

  /// Dạng Map mà màn hình sự kiện và màn chi tiết đang dùng.
  Map<String, dynamic> toViewData() => {
    'id': id,
    'title': title.isEmpty ? 'Sự kiện chưa đặt tên' : title,
    'time': timeLabel,
    'location': location,
    'author': authorName.isEmpty ? 'Ban tổ chức' : authorName,
    'vote': participantCount,
    'description': description,
  };
}

/// Đọc sự kiện từ bảng `events`.
class EventRepository {
  EventRepository([SupabaseClient? client]) : _client = client;

  final SupabaseClient? _client;
  SupabaseClient get _supabase => _client ?? Supabase.instance.client;

  static const String selectColumns =
      'id, title, description, location, start_at, '
      'author:profiles!events_created_by_fkey(username, first_name, last_name), '
      'event_participants(count)';

  /// Sự kiện chưa diễn ra (hoặc chưa có lịch), sắp theo thời gian bắt đầu.
  Future<List<Event>> fetchUpcoming({DateTime? now}) async {
    final String nowIso = (now ?? DateTime.now()).toUtc().toIso8601String();
    final List<Map<String, dynamic>> rows = await _supabase
        .from('events')
        .select(selectColumns)
        .or('start_at.is.null,start_at.gte.$nowIso')
        .order('start_at', ascending: true, nullsFirst: false);
    return rows.map(Event.fromRow).toList();
  }
}
