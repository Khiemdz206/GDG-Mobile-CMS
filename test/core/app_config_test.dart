import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gdgocms/core/config/app_config.dart';

String fakeJwt(Map<String, Object> payload) {
  String part(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  return '${part({'alg': 'HS256'})}.${part(payload)}.signature';
}

void main() {
  group('AppConfig.parse', () {
    test('chấp nhận URL https và publishable key', () {
      final config = AppConfig.parse(
        url: 'https://abc.supabase.co/',
        key: 'sb_publishable_123',
      );
      expect(config.supabaseUrl, 'https://abc.supabase.co');
      expect(config.supabaseKey, 'sb_publishable_123');
    });

    test('chấp nhận anon key kiểu JWT cũ', () {
      final key = fakeJwt({'role': 'anon'});
      expect(
        AppConfig.parse(url: 'https://abc.supabase.co', key: key).supabaseKey,
        key,
      );
    });

    test('cho phép http với Supabase chạy trên máy (emulator)', () {
      expect(
        AppConfig.parse(
          url: 'http://10.0.2.2:54321',
          key: 'sb_publishable_1',
        ).supabaseUrl,
        'http://10.0.2.2:54321',
      );
    });

    test('báo thiếu cấu hình khi chưa truyền env.json', () {
      expect(
        () => AppConfig.parse(url: '', key: ''),
        throwsA(isA<AppConfigException>()),
      );
    });

    test('từ chối http với server online', () {
      expect(
        () => AppConfig.parse(
          url: 'http://abc.supabase.co',
          key: 'sb_publishable_1',
        ),
        throwsA(isA<AppConfigException>()),
      );
    });

    test('từ chối secret key', () {
      expect(
        () => AppConfig.parse(
          url: 'https://abc.supabase.co',
          key: 'sb_secret_123',
        ),
        throwsA(isA<AppConfigException>()),
      );
    });

    test('từ chối service_role key kiểu JWT cũ', () {
      expect(
        () => AppConfig.parse(
          url: 'https://abc.supabase.co',
          key: fakeJwt({'role': 'service_role'}),
        ),
        throwsA(isA<AppConfigException>()),
      );
    });
  });
}
