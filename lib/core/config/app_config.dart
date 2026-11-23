import 'dart:convert';

/// app_config.dart
/// Layer: Core
/// Description: Đọc và kiểm tra cấu hình Supabase truyền vào lúc build.
///
/// Giá trị đến từ `--dart-define-from-file=env.json` (xem env.example.json).
/// Chỉ được dùng publishable/anon key; secret/service_role key có toàn quyền
/// database nên tuyệt đối không đưa vào app.
class AppConfig {
  final String supabaseUrl;
  final String supabaseKey;

  const AppConfig._(this.supabaseUrl, this.supabaseKey);

  /// Cấu hình đọc từ biến build.
  static AppConfig fromEnvironment() => parse(
    url: const String.fromEnvironment('SUPABASE_URL'),
    key: const String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY'),
  );

  /// Kiểm tra cấu hình; sai thì ném [AppConfigException] với thông báo dễ hiểu.
  static AppConfig parse({required String url, required String key}) {
    if (url.trim().isEmpty || key.trim().isEmpty) {
      throw const AppConfigException(
        'Thiếu cấu hình Supabase. Tạo file env.json từ env.example.json rồi '
        'chạy: flutter run --dart-define-from-file=env.json',
      );
    }

    final Uri? uri = Uri.tryParse(url.trim());
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw const AppConfigException('SUPABASE_URL không phải địa chỉ hợp lệ.');
    }
    // 10.0.2.2 là địa chỉ máy tính khi nhìn từ emulator Android.
    const localHosts = {'localhost', '127.0.0.1', '10.0.2.2'};
    final bool isLocal = localHosts.contains(uri.host);
    if (uri.scheme != 'https' && !(isLocal && uri.scheme == 'http')) {
      throw const AppConfigException(
        'SUPABASE_URL phải dùng https (chỉ Supabase chạy trên máy mới dùng http).',
      );
    }

    final String trimmedKey = key.trim();
    if (trimmedKey.startsWith('sb_secret_') || _isNonAnonJwt(trimmedKey)) {
      throw const AppConfigException(
        'Không được đưa secret key vào app. Dùng publishable key (sb_publishable_...).',
      );
    }

    return AppConfig._(uri.origin, trimmedKey);
  }

  /// Key kiểu cũ là JWT; chỉ chấp nhận JWT có role `anon`.
  static bool _isNonAnonJwt(String key) {
    final List<String> parts = key.split('.');
    if (parts.length != 3) return false;
    try {
      final Object? payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      return payload is! Map || payload['role'] != 'anon';
    } on FormatException {
      return true;
    }
  }
}

class AppConfigException implements Exception {
  final String message;
  const AppConfigException(this.message);

  @override
  String toString() => message;
}
