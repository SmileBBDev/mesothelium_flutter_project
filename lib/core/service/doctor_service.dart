// 의사 관리 서비스
import 'api_client.dart';
import 'api_config.dart';

class DoctorService {
  static final DoctorService _instance = DoctorService._internal();
  factory DoctorService() => _instance;
  DoctorService._internal();

  final ApiClient _apiClient = ApiClient();

  // 의사 목록 조회
  Future<DoctorsResult> getDoctors({
    Map<String, dynamic>? filters,
  }) async {
    try {
      final response = await _apiClient.get(
        ApiConfig.doctorsEndpoint,
        queryParams: filters,
      );

      if (response.success && response.data != null) {
        return DoctorsResult(
          success: true,
          doctors: List<Map<String, dynamic>>.from(response.data as List),
        );
      }

      return DoctorsResult(
        success: false,
        message: response.message ?? '의사 목록 조회 실패',
      );
    } catch (e) {
      return DoctorsResult(
        success: false,
        message: '의사 목록 조회 중 오류 발생: $e',
      );
    }
  }

  // 특정 의사 조회
  Future<DoctorResult> getDoctor(int doctorId) async {
    try {
      final response = await _apiClient.get('${ApiConfig.doctorsEndpoint}$doctorId/');

      if (response.success && response.data != null) {
        return DoctorResult(
          success: true,
          doctor: response.data as Map<String, dynamic>,
        );
      }

      return DoctorResult(
        success: false,
        message: response.message ?? '의사 정보 조회 실패',
      );
    } catch (e) {
      return DoctorResult(
        success: false,
        message: '의사 정보 조회 중 오류 발생: $e',
      );
    }
  }

  // 의사 정보 수정 (본인 또는 관리자)
  Future<DoctorResult> updateDoctor({
    required int doctorId,
    String? licenseNumber,
    String? department,
    String? specialty,
    String? phoneWork,
    bool? active,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (licenseNumber != null) body['license_number'] = licenseNumber;
      if (department != null) body['department'] = department;
      if (specialty != null) body['specialty'] = specialty;
      if (phoneWork != null) body['phone_work'] = phoneWork;
      if (active != null) body['active'] = active;

      final response = await _apiClient.patch(
        '${ApiConfig.doctorsEndpoint}$doctorId/',
        body: body,
      );

      if (response.success && response.data != null) {
        return DoctorResult(
          success: true,
          doctor: response.data as Map<String, dynamic>,
          message: '의사 정보가 수정되었습니다.',
        );
      }

      return DoctorResult(
        success: false,
        message: response.message ?? '의사 정보 수정 실패',
      );
    } catch (e) {
      return DoctorResult(
        success: false,
        message: '의사 정보 수정 중 오류 발생: $e',
      );
    }
  }
}

// 의사 목록 조회 결과
class DoctorsResult {
  final bool success;
  final String? message;
  final List<Map<String, dynamic>>? doctors;

  DoctorsResult({
    required this.success,
    this.message,
    this.doctors,
  });
}

// 의사 정보 조회/수정 결과
class DoctorResult {
  final bool success;
  final String? message;
  final Map<String, dynamic>? doctor;

  DoctorResult({
    required this.success,
    this.message,
    this.doctor,
  });
}
