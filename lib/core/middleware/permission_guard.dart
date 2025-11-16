import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

/// 사용자 역할
enum UserRole {
  patient,    // 환자
  doctor,     // 의사
  staff,      // 원무과
  admin,      // 관리자
  general,    // 일반 사용자 (미승인)
}

/// 역할 문자열을 UserRole로 변환
UserRole? userRoleFromString(String? role) {
  if (role == null) return null;
  switch (role.toLowerCase()) {
    case 'patient':
      return UserRole.patient;
    case 'doctor':
      return UserRole.doctor;
    case 'staff':
      return UserRole.staff;
    case 'admin':
      return UserRole.admin;
    case 'general':
      return UserRole.general;
    default:
      return null;
  }
}

/// UserRole을 문자열로 변환
String userRoleToString(UserRole role) {
  return role.toString().split('.').last;
}

/// 권한 관리 서비스
class PermissionGuard {
  static final PermissionGuard _instance = PermissionGuard._internal();
  factory PermissionGuard() => _instance;
  PermissionGuard._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  UserRole? _currentRole;
  Map<String, dynamic>? _currentUser;

  /// 현재 사용자 역할 가져오기
  Future<UserRole?> getCurrentRole() async {
    if (_currentRole != null) return _currentRole;

    final userJson = await _storage.read(key: 'user_data');
    if (userJson == null) return null;

    try {
      final userData = jsonDecode(userJson) as Map<String, dynamic>;
      _currentUser = userData;
      final roleString = userData['role'] as String?;
      _currentRole = userRoleFromString(roleString);
      return _currentRole;
    } catch (e) {
      debugPrint('Failed to parse user role: $e');
      return null;
    }
  }

  /// 현재 사용자 정보 가져오기
  Future<Map<String, dynamic>?> getCurrentUser() async {
    if (_currentUser != null) return _currentUser;

    final userJson = await _storage.read(key: 'user_data');
    if (userJson == null) return null;

    try {
      _currentUser = jsonDecode(userJson) as Map<String, dynamic>;
      return _currentUser;
    } catch (e) {
      debugPrint('Failed to parse user data: $e');
      return null;
    }
  }

  /// 역할 설정 (로그인 시 사용)
  Future<void> setUserRole(UserRole role, Map<String, dynamic> userData) async {
    _currentRole = role;
    _currentUser = userData;
    await _storage.write(key: 'user_data', value: jsonEncode(userData));
  }

  /// 역할 초기화 (로그아웃 시 사용)
  Future<void> clearUserRole() async {
    _currentRole = null;
    _currentUser = null;
    await _storage.delete(key: 'user_data');
  }

  /// 특정 역할 확인
  Future<bool> hasRole(UserRole role) async {
    final currentRole = await getCurrentRole();
    return currentRole == role;
  }

  /// 여러 역할 중 하나라도 가지고 있는지 확인
  Future<bool> hasAnyRole(List<UserRole> roles) async {
    final currentRole = await getCurrentRole();
    if (currentRole == null) return false;
    return roles.contains(currentRole);
  }

  /// 모든 역할을 가지고 있는지 확인 (현실적으로는 사용 안 함)
  Future<bool> hasAllRoles(List<UserRole> roles) async {
    final currentRole = await getCurrentRole();
    if (currentRole == null) return false;
    // 사용자는 하나의 역할만 가질 수 있으므로 roles.length가 1일 때만 true
    return roles.length == 1 && roles.contains(currentRole);
  }

  /// 관리자 권한 확인
  Future<bool> isAdmin() async {
    return await hasRole(UserRole.admin);
  }

  /// 의사 권한 확인
  Future<bool> isDoctor() async {
    return await hasRole(UserRole.doctor);
  }

  /// 환자 권한 확인
  Future<bool> isPatient() async {
    return await hasRole(UserRole.patient);
  }

  /// 원무과 권한 확인
  Future<bool> isStaff() async {
    return await hasRole(UserRole.staff);
  }

  /// 일반 사용자(미승인) 확인
  Future<bool> isGeneral() async {
    return await hasRole(UserRole.general);
  }

  /// 승인된 사용자인지 확인 (general 제외)
  Future<bool> isApproved() async {
    final currentRole = await getCurrentRole();
    return currentRole != null && currentRole != UserRole.general;
  }
}

/// 권한 기반 위젯 (특정 역할만 표시)
class PermissionWidget extends StatelessWidget {
  final List<UserRole> allowedRoles;
  final Widget child;
  final Widget? fallback;

  const PermissionWidget({
    super.key,
    required this.allowedRoles,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserRole?>(
      future: PermissionGuard().getCurrentRole(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        final currentRole = snapshot.data;
        if (currentRole != null && allowedRoles.contains(currentRole)) {
          return child;
        }

        return fallback ?? const SizedBox.shrink();
      },
    );
  }
}

/// 권한 기반 라우트 가드
class PermissionRoute extends StatelessWidget {
  final List<UserRole> allowedRoles;
  final Widget page;
  final Widget? unauthorizedPage;
  final String? unauthorizedRoute;

  const PermissionRoute({
    super.key,
    required this.allowedRoles,
    required this.page,
    this.unauthorizedPage,
    this.unauthorizedRoute,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserRole?>(
      future: PermissionGuard().getCurrentRole(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final currentRole = snapshot.data;

        // 역할이 없으면 로그인 페이지로
        if (currentRole == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, '/login');
          });
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // 권한이 있으면 페이지 표시
        if (allowedRoles.contains(currentRole)) {
          return page;
        }

        // 권한이 없으면 unauthorizedPage 또는 unauthorizedRoute로 이동
        if (unauthorizedPage != null) {
          return unauthorizedPage!;
        }

        if (unauthorizedRoute != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, unauthorizedRoute!);
          });
        } else {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, '/');
          });
        }

        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  '접근 권한이 없습니다',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '이 페이지에 접근할 수 있는 권한이 없습니다.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 권한 체크 mixin (StatefulWidget에서 사용)
mixin PermissionCheckMixin<T extends StatefulWidget> on State<T> {
  UserRole? _currentRole;

  Future<void> checkPermission() async {
    _currentRole = await PermissionGuard().getCurrentRole();
    if (mounted) {
      setState(() {});
    }
  }

  bool hasRole(UserRole role) {
    return _currentRole == role;
  }

  bool hasAnyRole(List<UserRole> roles) {
    return _currentRole != null && roles.contains(_currentRole);
  }

  bool get isAdmin => hasRole(UserRole.admin);
  bool get isDoctor => hasRole(UserRole.doctor);
  bool get isPatient => hasRole(UserRole.patient);
  bool get isStaff => hasRole(UserRole.staff);
  bool get isGeneral => hasRole(UserRole.general);
  bool get isApproved => _currentRole != null && _currentRole != UserRole.general;

  @override
  void initState() {
    super.initState();
    checkPermission();
  }
}

/// 권한별 페이지 설정
class PermissionConfig {
  // 환자만 접근 가능한 페이지
  static const List<String> patientOnlyPages = [
    '/patient/home',
    '/patient/records',
    '/patient/predictions',
  ];

  // 의사만 접근 가능한 페이지
  static const List<String> doctorOnlyPages = [
    '/doctor/home',
    '/doctor/patients',
    '/doctor/ml-prediction',
  ];

  // 원무과만 접근 가능한 페이지
  static const List<String> staffOnlyPages = [
    '/staff/home',
    '/staff/patient-management',
    '/staff/user-approval',
  ];

  // 관리자만 접근 가능한 페이지
  static const List<String> adminOnlyPages = [
    '/admin/home',
    '/admin/users',
    '/admin/system-settings',
  ];

  // 승인된 사용자만 접근 가능한 페이지 (general 제외)
  static const List<String> approvedOnlyPages = [
    '/profile',
    '/settings',
  ];

  /// 페이지별 허용 역할 반환
  static List<UserRole>? getAllowedRoles(String route) {
    if (patientOnlyPages.contains(route)) {
      return [UserRole.patient];
    }
    if (doctorOnlyPages.contains(route)) {
      return [UserRole.doctor];
    }
    if (staffOnlyPages.contains(route)) {
      return [UserRole.staff];
    }
    if (adminOnlyPages.contains(route)) {
      return [UserRole.admin];
    }
    if (approvedOnlyPages.contains(route)) {
      return [UserRole.patient, UserRole.doctor, UserRole.staff, UserRole.admin];
    }
    return null; // 모두 접근 가능
  }

  /// 역할별 홈 페이지 경로 반환
  static String getHomeRoute(UserRole role) {
    switch (role) {
      case UserRole.patient:
        return '/patient/home';
      case UserRole.doctor:
        return '/doctor/home';
      case UserRole.staff:
        return '/staff/home';
      case UserRole.admin:
        return '/admin/home';
      case UserRole.general:
        return '/general/waiting';
    }
  }
}
