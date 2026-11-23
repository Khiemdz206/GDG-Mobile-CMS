import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

/// error_messages.dart
/// Layer: Core
/// Description: Đổi lỗi từ Supabase/mạng thành câu tiếng Việt cho người dùng.
/// Không hiện lỗi SQL/SDK thô ra giao diện.
String errorMessage(Object error) {
  if (error is SocketException ||
      error is TimeoutException ||
      error is AuthRetryableFetchException) {
    return 'Không kết nối được máy chủ. Kiểm tra mạng rồi thử lại.';
  }

  if (error is AuthException) {
    switch (error.code) {
      case 'invalid_credentials':
        return 'Email hoặc mật khẩu chưa đúng.';
      case 'email_not_confirmed':
        return 'Bạn cần bấm link xác minh trong email trước khi đăng nhập.';
      case 'user_already_exists':
      case 'email_exists':
        return 'Email này đã có tài khoản. Hãy đăng nhập.';
      case 'weak_password':
        return 'Mật khẩu quá yếu. Dùng ít nhất 6 ký tự, khó đoán hơn.';
      case 'email_address_invalid':
        return 'Email chưa hợp lệ.';
      case 'over_request_rate_limit':
      case 'over_email_send_rate_limit':
        return 'Bạn thử quá nhiều lần. Đợi vài phút rồi thử lại.';
      case 'signup_disabled':
        return 'Hiện chưa cho phép đăng ký tài khoản mới.';
      case 'session_expired':
      case 'refresh_token_not_found':
        return 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
    }
    // Lỗi từ trigger tạo hồ sơ khi đăng ký (thường là trùng username).
    if (error.message.contains('Database error saving new user')) {
      return 'Username đã có người dùng hoặc không hợp lệ (3–30 ký tự: chữ, số, _ hoặc .).';
    }
  }

  if (error is PostgrestException) {
    switch (error.code) {
      case 'PGRST301':
      case 'PGRST303':
        return 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
      case '42501':
        return 'Tài khoản của bạn không có quyền làm thao tác này.';
      case 'PGRST116':
        return 'Không tìm thấy dữ liệu.';
      case '23514':
        return 'Dữ liệu chưa hợp lệ. Kiểm tra lại rồi thử lại.';
    }
  }

  return 'Có lỗi xảy ra. Vui lòng thử lại.';
}
