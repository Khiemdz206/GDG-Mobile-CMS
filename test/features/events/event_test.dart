import 'package:flutter_test/flutter_test.dart';
import 'package:gdgocms/features/events/data/event.dart';

void main() {
  group('Event.fromRow', () {
    test('đọc đủ trường từ kết quả Supabase', () {
      final event = Event.fromRow({
        'id': 'e1',
        'title': ' Workshop Flutter ',
        'description': 'Học Flutter cơ bản',
        'location': 'D3-301',
        'start_at': '2026-12-05T11:30:00+00:00',
        'author': {'username': 'an', 'first_name': 'An', 'last_name': 'Nguyen'},
        'event_participants': [
          {'count': 12},
        ],
      });

      expect(event.title, 'Workshop Flutter');
      expect(event.location, 'D3-301');
      expect(event.startAt, DateTime.utc(2026, 12, 5, 11, 30));
      expect(event.authorName, 'An Nguyen');
      expect(event.participantCount, 12);
    });

    test('thiếu tác giả, lịch, người tham gia vẫn hiển thị được', () {
      final view = Event.fromRow({
        'id': 'e2',
        'title': '',
        'description': null,
        'location': null,
        'start_at': null,
        'author': null,
        'event_participants': [],
      }).toViewData();

      expect(view['title'], 'Sự kiện chưa đặt tên');
      expect(view['time'], 'Chưa có lịch');
      expect(view['author'], 'Ban tổ chức');
      expect(view['vote'], 0);
      expect(view['description'], '');
    });

    test('tác giả chưa có họ tên thì dùng username', () {
      final event = Event.fromRow({
        'id': 'e3',
        'title': 'Meetup',
        'author': {'username': 'binh', 'first_name': '', 'last_name': ''},
      });
      expect(event.authorName, 'binh');
    });
  });
}
