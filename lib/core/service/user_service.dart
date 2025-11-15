import 'api_client.dart';

class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  final ApiClient _apiClient = ApiClient();

  /// 프로필 업데이트
  /// updateData: { 'name': '...', 'email': '...', 'phone': '...', 'password': '...' (선택) }
  Future<ApiResponse> updateProfile(Map<String, dynamic> updateData) async {
    // /api/auth/me/ PATCH 요청으로 프로필 업데이트
    final response = await _apiClient.patch(
      '/api/auth/me/',
      body: updateData,
    );

    return response;
  }

  /// 현재 사용자 정보 조회
  Future<Map<String, dynamic>> getCurrentUser() async {
    final response = await _apiClient.get('/api/auth/me/');

    if (response.success && response.data != null) {
      return response.data as Map<String, dynamic>;
    }

    throw Exception(response.message ?? '사용자 정보를 불러올 수 없습니다');
  }
}
