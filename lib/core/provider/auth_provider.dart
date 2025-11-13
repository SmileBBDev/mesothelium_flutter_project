import 'package:flutter/foundation.dart';
import '../../config/base_config.dart';
import '../service/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final _api = BaseConfig();
  final _svc = AuthService();

  bool _ready = false;
  bool get isReady => _ready;

  AuthUser? _user;
  AuthUser? get user => _user;
  bool get isAuthenticated => _user != null;

  /// 앱 시작 시 토큰/유저 로드
  Future<void> init() async {
    await _api.init();
    _user = await _svc.loadFromStorage();
    _ready = true;
    notifyListeners();
  }

  /// 로그인
  Future<void> login(String username, String password) async {
    _user = await _svc.login(username, password);
    notifyListeners();
  }

  /// 회원가입 (role 지원: 기본값 'general')
  Future<void> register(
      String username,
      String email,
      String password, {
        String role = 'general',
      }) async {
    _user = await _svc.register(username, email, password, role: role);
    notifyListeners();
  }

  /// 로그아웃
  Future<void> logout() async {
    await _svc.logout();
    _user = null;
    notifyListeners();
  }
}
