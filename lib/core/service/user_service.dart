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

  /// 전체 사용자 목록 조회 (role 필터 선택사항)
  /// GET /api/auth/users/?role=general
  Future<List<Map<String, dynamic>>> getUserList({String? role}) async {
    String url = '/api/auth/users/';
    if (role != null && role.isNotEmpty) {
      url += '?role=$role';
    }

    final response = await _apiClient.get(url);

    if (response.success && response.data != null) {
      final List<dynamic> data = response.data as List<dynamic>;
      return data.map((e) => e as Map<String, dynamic>).toList();
    }

    throw Exception(response.message ?? '사용자 목록을 불러올 수 없습니다');
  }

  /// 의사 목록 조회
  /// GET /api/doctors/
  Future<List<Map<String, dynamic>>> getDoctorList() async {
    final response = await _apiClient.get('/api/doctors/');

    if (response.success && response.data != null) {
      final List<dynamic> data = response.data as List<dynamic>;
      return data.map((e) => e as Map<String, dynamic>).toList();
    }

    throw Exception(response.message ?? '의사 목록을 불러올 수 없습니다');
  }

  /// 역할 변경 및 환자 승인
  /// POST /api/auth/change-role/
  /// payload 예: { "user_id": 8, "role": "patient", "patient": {"assigned_doctor_ids": [1, 2]} }
  Future<ApiResponse> changeRole({
    required int userId,
    required String role,
    Map<String, dynamic>? doctorPayload,
    Map<String, dynamic>? patientPayload,
  }) async {
    final body = <String, dynamic>{
      'user_id': userId,
      'role': role,
    };

    if (doctorPayload != null) {
      body['doctor'] = doctorPayload;
    }

    if (patientPayload != null) {
      body['patient'] = patientPayload;
    }

    // ignore: avoid_print
    print('[API] POST /api/auth/change-role/');
    // ignore: avoid_print
    print('[API] Request body: $body');

    final response = await _apiClient.post(
      '/api/auth/change-role/',
      body: body,
    );

    // ignore: avoid_print
    print('[API] Response success: ${response.success}');
    // ignore: avoid_print
    print('[API] Response statusCode: ${response.statusCode}');
    // ignore: avoid_print
    print('[API] Response data: ${response.data}');

    return response;
  }
}
