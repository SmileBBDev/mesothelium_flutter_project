import 'api_client.dart';
import 'api_config.dart';

class PrescriptionService {
  final ApiClient _apiClient = ApiClient();

  /// 진료 기록 생성
  Future<ApiResponse> createPrescription({
    required int patientId,
    required int doctorId,
    required String title,
    required String contentDelta,
  }) async {
    try {
      print('[진료 기록 생성] patientId: $patientId, doctorId: $doctorId, title: $title');

      final response = await _apiClient.post(
        ApiConfig.prescriptionsEndpoint,
        body: {
          'patient_id': patientId,
          'doctor_id': doctorId,
          'title': title,
          'content_delta': contentDelta,
        },
      );

      print('[진료 기록 생성 응답] success: ${response.success}, message: ${response.message}');
      return response;
    } catch (e) {
      print('[진료 기록 생성 에러] $e');
      rethrow;
    }
  }

  /// 특정 환자의 진료 기록 목록 조회
  Future<List<Map<String, dynamic>>> getPrescriptionsByPatient(int patientId) async {
    try {
      print('[진료 기록 조회] patientId: $patientId');

      final response = await _apiClient.get(
        '${ApiConfig.prescriptionsEndpoint}by-patient/$patientId/',
      );

      if (response.success && response.data != null) {
        if (response.data is List) {
          return List<Map<String, dynamic>>.from(response.data);
        }
      }

      return [];
    } catch (e) {
      print('[진료 기록 조회 에러] $e');
      return [];
    }
  }

  /// 특정 의사의 진료 기록 목록 조회
  Future<List<Map<String, dynamic>>> getPrescriptionsByDoctor(int doctorId) async {
    try {
      print('[의사별 진료 기록 조회] doctorId: $doctorId');

      final response = await _apiClient.get(
        '${ApiConfig.prescriptionsEndpoint}by-doctor/$doctorId/',
      );

      if (response.success && response.data != null) {
        if (response.data is List) {
          return List<Map<String, dynamic>>.from(response.data);
        }
      }

      return [];
    } catch (e) {
      print('[의사별 진료 기록 조회 에러] $e');
      return [];
    }
  }

  /// 특정 환자 + 특정 의사의 진료 기록 조회
  Future<List<Map<String, dynamic>>> getPrescriptionsByPatientAndDoctor(
    int patientId,
    int doctorId,
  ) async {
    try {
      print('[환자-의사 진료 기록 조회] patientId: $patientId, doctorId: $doctorId');

      final response = await _apiClient.get(
        '${ApiConfig.prescriptionsEndpoint}by-patient-doctor/$patientId/$doctorId/',
      );

      if (response.success && response.data != null) {
        if (response.data is List) {
          return List<Map<String, dynamic>>.from(response.data);
        }
      }

      return [];
    } catch (e) {
      print('[환자-의사 진료 기록 조회 에러] $e');
      return [];
    }
  }

  /// 진료 기록 상세 조회
  Future<Map<String, dynamic>?> getPrescriptionDetail(int prescriptionId) async {
    try {
      print('[진료 기록 상세 조회] prescriptionId: $prescriptionId');

      final response = await _apiClient.get(
        '${ApiConfig.prescriptionsEndpoint}$prescriptionId/',
      );

      if (response.success && response.data != null) {
        return response.data as Map<String, dynamic>;
      }

      return null;
    } catch (e) {
      print('[진료 기록 상세 조회 에러] $e');
      return null;
    }
  }

  /// 진료 기록 수정
  Future<ApiResponse> updatePrescription({
    required int prescriptionId,
    String? title,
    String? contentDelta,
  }) async {
    try {
      print('[진료 기록 수정] prescriptionId: $prescriptionId');

      final body = <String, dynamic>{};
      if (title != null) body['title'] = title;
      if (contentDelta != null) body['content_delta'] = contentDelta;

      final response = await _apiClient.patch(
        '${ApiConfig.prescriptionsEndpoint}$prescriptionId/',
        body: body,
      );

      print('[진료 기록 수정 응답] success: ${response.success}');
      return response;
    } catch (e) {
      print('[진료 기록 수정 에러] $e');
      rethrow;
    }
  }

  /// 진료 기록 삭제
  Future<ApiResponse> deletePrescription(int prescriptionId) async {
    try {
      print('[진료 기록 삭제] prescriptionId: $prescriptionId');

      final response = await _apiClient.delete(
        '${ApiConfig.prescriptionsEndpoint}$prescriptionId/',
      );

      print('[진료 기록 삭제 응답] success: ${response.success}');
      return response;
    } catch (e) {
      print('[진료 기록 삭제 에러] $e');
      rethrow;
    }
  }
}
