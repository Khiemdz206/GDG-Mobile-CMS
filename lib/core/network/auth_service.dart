import 'package:supabase_flutter/supabase_flutter.dart';

/// auth_service.dart
/// Layer: Core
/// Module: Network
/// Description: Đăng ký, đăng nhập, đăng xuất qua Supabase Auth.
///
/// Supabase SDK tự lưu và làm mới phiên đăng nhập (access/refresh token),
/// app không tự lưu token.
class AuthService {
  AuthService([SupabaseClient? client]) : _client = client;

  final SupabaseClient? _client;
  SupabaseClient get _supabase => _client ?? Supabase.instance.client;

  /// Người dùng đang đăng nhập, `null` nếu chưa đăng nhập.
  User? get currentUser => _supabase.auth.currentUser;

  bool get isSignedIn => _supabase.auth.currentSession != null;

  /// Tạo tài khoản. Hồ sơ trong bảng `profiles` được database tự tạo
  /// từ [username], [firstName], [lastName].
  ///
  /// Trả về [SignUpResult.needsEmailConfirmation] nếu project Supabase bật
  /// xác minh email: người dùng phải bấm link trong email rồi mới đăng nhập.
  Future<SignUpResult> register({
    required String username,
    required String password,
    required String email,
    required String firstName,
    required String lastName,
  }) async {
    final AuthResponse response = await _supabase.auth.signUp(
      email: email.trim(),
      password: password,
      data: {
        'username': username.trim(),
        'first_name': firstName.trim(),
        'last_name': lastName.trim(),
      },
    );
    return response.session != null
        ? SignUpResult.signedIn
        : SignUpResult.needsEmailConfirmation;
  }

  /// Đăng nhập bằng email và mật khẩu. Sai thì ném [AuthException].
  Future<void> login({required String email, required String password}) async {
    await _supabase.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Đăng xuất. Nếu không báo được cho server (mất mạng),
  /// vẫn xoá phiên trên máy để người dùng không bị kẹt trong trạng thái đăng nhập.
  Future<void> logout() async {
    try {
      await _supabase.auth.signOut();
    } catch (_) {
      await _supabase.auth.signOut(scope: SignOutScope.local);
    }
  }
}

enum SignUpResult { signedIn, needsEmailConfirmation }
