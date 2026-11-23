import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gdgocms/core/error/error_messages.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('sai mật khẩu và mất mạng ra hai thông báo khác nhau', () {
    final wrongPassword = errorMessage(
      const AuthException('Invalid login', code: 'invalid_credentials'),
    );
    final offline = errorMessage(const SocketException('Failed host lookup'));

    expect(wrongPassword, 'Email hoặc mật khẩu chưa đúng.');
    expect(offline, contains('Kiểm tra mạng'));
  });

  test('trùng username khi đăng ký có thông báo riêng', () {
    expect(
      errorMessage(
        const AuthException(
          'Database error saving new user',
          code: 'unexpected_failure',
        ),
      ),
      contains('Username'),
    );
  });

  test('bị RLS chặn thì báo không có quyền', () {
    expect(
      errorMessage(const PostgrestException(message: 'denied', code: '42501')),
      contains('không có quyền'),
    );
  });

  test('lỗi lạ không lộ chi tiết kỹ thuật', () {
    expect(
      errorMessage(Exception('relation "events" does not exist')),
      'Có lỗi xảy ra. Vui lòng thử lại.',
    );
  });
}
