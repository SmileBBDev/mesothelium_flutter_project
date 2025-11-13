// API통신, DB통신 코드 작성
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:jwt_decode/jwt_decode.dart';
import '../../config/base_config.dart';

class AuthUser {
  final int? userId;
  final String username;
  final String role;
  AuthUser({this.userId, required this.username, required this.role});
}

class AuthService {
  final _api = BaseConfig();

  /// 저장소(access)에서 유저 복원
  Future<AuthUser?> loadFromStorage() async {
    final access = await _api.storage.read(key: 'access');
    if (access == null) return null;

    try {
      return _parseAuthUserFromAccess(access);
    } catch (_) {
      return null;
    }
  }

  // 로그인 API호출
  Future<AuthUser> login(String username, String password) async {
    print("이게 넘어왔다");
    print("🔥 baseUrl: ${_api.dio.options.baseUrl}");
    print(username);
    print(password);
    try {
      final resp = await _api.dio.post(
        '/api/auth/token/',
        data: jsonEncode({'username': username, 'password': password}),
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );

      final access = (resp.data['access'] ?? '') as String;
      final refresh = (resp.data['refresh'] ?? '') as String;
      await _api.setTokens(access, refresh);

      // 토큰으로 유저 복원 (payload에 username/role 없으면 폴백)
      final user = _parseAuthUserFromAccess(
        access,
        fallbackUsername: username,
        fallbackRole: 'general',
      );
      return user;
    } on DioException catch (e) {
      final msg = e.response?.data?.toString() ?? e.message;
      throw Exception('로그인 실패: $msg');
    }
  }

  /// 회원가입 (role 지원: 기본값 'general')
  /// 서버가 토큰을 내려주지 않아도 성공 처리(폴백)하도록 구현
  Future<AuthUser> register(
      String username,
      String email,
      String password, {
        String role = 'general',
      }) async {
    try {
      final resp = await _api.dio.post(
        '/api/auth/register/',
        data: {
          'username': username,
          'email': email,
          'password': password,
          'role': role,
        },
      );

      final status = resp.statusCode ?? 200;
      if (status < 200 || status >= 300) {
        throw Exception('회원가입 실패: $status ${resp.data}');
      }

      // 토큰이 있으면 저장 + 토큰으로 유저 복원
      final access = resp.data['access'] as String?;
      final refresh = resp.data['refresh'] as String?;
      if (access != null && refresh != null) {
        await _api.setTokens(access, refresh);
        final user = _parseAuthUserFromAccess(
          access,
          fallbackUsername: username,
          fallbackRole: role,
        );
        return user;
      }

      // 토큰이 없어도 가입 자체는 성공 → 폴백 유저 리턴
      return AuthUser(userId: null, username: username, role: role);
    } on DioException catch (e) {
      final msg = e.response?.data?.toString() ?? e.message;
      throw Exception('회원가입 실패: $msg');
    }
  }

  /// 인증된 사용자(me)
  Future<Map<String, dynamic>> me() async {
    final resp = await _api.dio.get('/api/auth/me/');
    return Map<String, dynamic>.from(resp.data); // {username, email, role}
  }

  /// 로그아웃(토큰 정리)
  Future<void> logout() async {
    await _api.clearTokens();
  }

  // ------------------------
  // helpers
  // ------------------------
  static AuthUser _parseAuthUserFromAccess(
      String access, {
        String? fallbackUsername,
        String? fallbackRole,
      }) {
    final payload = Jwt.parseJwt(access);
    return AuthUser(
      userId: _toInt(payload['user_id']),
      username: (payload['username'] ?? fallbackUsername ?? '') as String,
      role: (payload['role'] ?? fallbackRole ?? 'general') as String,
    );
  }

  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse('$v');
  }
}
