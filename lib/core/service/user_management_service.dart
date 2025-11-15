import 'api_client.dart';
import 'api_config.dart';

class UserManagementService {
  static final UserManagementService _instance = UserManagementService._internal();
  factory UserManagementService() => _instance;
  UserManagementService._internal();

  final ApiClient _apiClient = ApiClient();

  // 전체 사용자 목록 조회
  Future<UsersResult> getUsers({String? role}) async {
    String endpoint = ApiConfig.usersEndpoint;
    if (role != null && role.isNotEmpty) {
      endpoint += '?role=$role';
    }

    final response = await _apiClient.get(endpoint);

    if (response.success && response.data != null) {
      final users = (response.data as List)
          .map((json) => json as Map<String, dynamic>)
          .toList();
      return UsersResult(success: true, users: users);
    }

    return UsersResult(
      success: false,
      message: response.message ?? '사용자 목록을 불러올 수 없습니다.',
    );
  }

  // 승인 대기 중인 사용자 목록 조회
  Future<UsersResult> getPendingUsers() async {
    final response = await _apiClient.get('${ApiConfig.usersEndpoint}?is_approved=false');

    if (response.success && response.data != null) {
      final users = (response.data as List)
          .map((json) => json as Map<String, dynamic>)
          .toList();
      return UsersResult(success: true, users: users);
    }

    return UsersResult(
      success: false,
      message: response.message ?? '승인 대기 목록을 불러올 수 없습니다.',
    );
  }

  // 사용자 승인
  Future<ApiResponse> approveUser(int userId) async {
    final response = await _apiClient.patch(
      '${ApiConfig.usersEndpoint}$userId/',
      body: {'is_approved': true},
    );

    return response;
  }

  // 사용자 비활성화/활성화
  Future<ApiResponse> toggleUserActive(int userId, bool isActive) async {
    final response = await _apiClient.patch(
      '${ApiConfig.usersEndpoint}$userId/',
      body: {'is_active': isActive},
    );

    return response;
  }

  // 사용자 삭제
  Future<ApiResponse> deleteUser(int userId) async {
    final response = await _apiClient.delete('${ApiConfig.usersEndpoint}$userId/');
    return response;
  }

  // 사용자 역할 변경
  Future<ApiResponse> changeUserRole(int userId, String newRole) async {
    final response = await _apiClient.post(
      ApiConfig.changeRoleEndpoint,
      body: {'user_id': userId, 'new_role': newRole},
    );

    return response;
  }

  // 사용자 상세 정보 조회
  Future<UserResult> getUserDetail(int userId) async {
    final response = await _apiClient.get('${ApiConfig.usersEndpoint}$userId/');

    if (response.success && response.data != null) {
      return UserResult(success: true, user: response.data);
    }

    return UserResult(
      success: false,
      message: response.message ?? '사용자 정보를 불러올 수 없습니다.',
    );
  }
}

class UsersResult {
  final bool success;
  final List<Map<String, dynamic>>? users;
  final String? message;

  UsersResult({
    required this.success,
    this.users,
    this.message,
  });
}

class UserResult {
  final bool success;
  final Map<String, dynamic>? user;
  final String? message;

  UserResult({
    required this.success,
    this.user,
    this.message,
  });
}
