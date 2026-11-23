import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gdgocms/core/network/api_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Chạy [body] với một server giả: mọi lệnh `http.get/post` bên trong
/// đều đi vào [handler] thay vì gọi https://gdg-cms.vercel.app thật.
Future<T> withFakeServer<T>(
  Future<http.Response> Function(http.Request request) handler,
  Future<T> Function() body,
) {
  return http.runWithClient(body, () => MockClient(handler));
}

http.Response jsonResponse(Object body, int status) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

void main() {
  late AuthService auth;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    auth = AuthService();
  });

  group('login', () {
    test('lưu token và thông tin user khi server trả 200', () async {
      late http.Request sent;
      final ok = await withFakeServer((request) async {
        sent = request;
        return jsonResponse({
          'accessToken': 'access-1',
          'refreshToken': 'refresh-1',
          'user': {
            'username': 'an',
            'firstName': 'An',
            'lastName': 'Nguyen',
            'email': 'an@example.com',
            'role': 'Leader',
          },
        }, 200);
      }, () => auth.login('an', 'secret'));

      expect(ok, isTrue);
      expect(sent.method, 'POST');
      expect(sent.url.path, '/login');
      expect(jsonDecode(sent.body), {'username': 'an', 'password': 'secret'});

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('accessToken'), 'access-1');
      expect(prefs.getString('refreshToken'), 'refresh-1');
      expect(prefs.getString('role'), 'Leader');
      expect(prefs.getString('email'), 'an@example.com');
    });

    test('trả false và không lưu gì khi server từ chối', () async {
      final ok = await withFakeServer(
        (_) async => jsonResponse({'message': 'Invalid'}, 401),
        () => auth.login('an', 'wrong'),
      );

      expect(ok, isFalse);
      expect(await auth.getAccessToken(), isNull);
    });

    test('trả false khi mất mạng', () async {
      final ok = await withFakeServer(
        (_) async => throw http.ClientException('offline'),
        () => auth.login('an', 'secret'),
      );

      expect(ok, isFalse);
    });
  });

  group('refreshToken', () {
    test('gửi refresh token đã lưu và cập nhật access token mới', () async {
      SharedPreferences.setMockInitialValues({
        'accessToken': 'old',
        'refreshToken': 'refresh-1',
      });

      late http.Request sent;
      final token = await withFakeServer((request) async {
        sent = request;
        return jsonResponse({'accessToken': 'new'}, 200);
      }, () => auth.refreshToken());

      expect(token, 'new');
      expect(sent.url.path, '/refresh');
      expect(jsonDecode(sent.body), {'refreshToken': 'refresh-1'});
      expect(await auth.getAccessToken(), 'new');
    });

    test('không gọi server khi chưa có refresh token', () async {
      var called = false;
      final token = await withFakeServer((_) async {
        called = true;
        return jsonResponse({}, 200);
      }, () => auth.refreshToken());

      expect(token, isNull);
      expect(called, isFalse);
    });
  });
}
