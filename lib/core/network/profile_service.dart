import 'package:supabase_flutter/supabase_flutter.dart';

/// profile_service.dart
/// Layer: Core
/// Module: Network
/// Description: Đọc và sửa hồ sơ của người đang đăng nhập (bảng `profiles`).
class ProfileService {
  ProfileService([SupabaseClient? client]) : _client = client;

  final SupabaseClient? _client;
  SupabaseClient get _supabase => _client ?? Supabase.instance.client;

  static const String _columns = 'id, username, first_name, last_name, role';

  /// Hồ sơ của người đang đăng nhập. Ném [StateError] nếu chưa đăng nhập.
  Future<Profile> fetchMyProfile() async {
    final User user = _requireUser();
    final Map<String, dynamic> row = await _supabase
        .from('profiles')
        .select(_columns)
        .eq('id', user.id)
        .single();
    return Profile.fromRow(row, email: user.email ?? '');
  }

  /// Sửa họ tên. Database chỉ cho sửa hai cột này; role/username không đổi được từ app.
  Future<Profile> updateMyName({
    required String firstName,
    required String lastName,
  }) async {
    final User user = _requireUser();
    final Map<String, dynamic> row = await _supabase
        .from('profiles')
        .update({'first_name': firstName.trim(), 'last_name': lastName.trim()})
        .eq('id', user.id)
        .select(_columns)
        .single();
    return Profile.fromRow(row, email: user.email ?? '');
  }

  User _requireUser() {
    final User? user = _supabase.auth.currentUser;
    if (user == null) {
      throw StateError('Chưa đăng nhập.');
    }
    return user;
  }
}

/// Hồ sơ thành viên.
class Profile {
  final String id;
  final String username;
  final String firstName;
  final String lastName;
  final String email;
  final String role;

  const Profile({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
  });

  /// Tạo từ một dòng của bảng `profiles`; [email] lấy từ Supabase Auth.
  factory Profile.fromRow(Map<String, dynamic> row, {required String email}) {
    String read(String key) => (row[key] as String?)?.trim() ?? '';
    final String role = read('role');
    return Profile(
      id: read('id'),
      username: read('username'),
      firstName: read('first_name'),
      lastName: read('last_name'),
      email: email,
      role: role.isEmpty ? 'Member' : role,
    );
  }

  /// Dạng Map mà màn hình hồ sơ đang dùng.
  Map<String, dynamic> toViewData() => {
    'username': username,
    'firstName': firstName,
    'lastName': lastName,
    'email': email,
    'role': role,
  };
}
