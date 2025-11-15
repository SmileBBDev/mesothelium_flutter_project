import '../../config/base_config.dart';
import '../model/patient.dart';
import 'api_client.dart';
import 'api_config.dart';

class PatientService {
  final BaseConfig _api = BaseConfig();
  final ApiClient _apiClient = ApiClient();

  /**
   * 의사에 맞는 환자 조회 api
   */
  Future<List<Patient>> getMyPatients(int? doctorId) async {
    final resp = await _api.dio.get('/api/patients/?by-doctor=$doctorId');
    return (resp.data as List)
        .map((e) => Patient.fromJson(e))
        .toList();
  }

  // 전체 환자 목록 조회 (관리자/스태프용)
  Future<PatientsResult> getAllPatients() async {
    try {
      final response = await _apiClient.get(ApiConfig.patientsAllEndpoint);

      if (response.success && response.data != null) {
        return PatientsResult(
          success: true,
          patients: List<Map<String, dynamic>>.from(response.data as List),
        );
      }

      return PatientsResult(
        success: false,
        message: response.message ?? '전체 환자 목록 조회 실패',
      );
    } catch (e) {
      return PatientsResult(
        success: false,
        message: '전체 환자 목록 조회 중 오류 발생: $e',
      );
    }
  }

  // 환자 정보 수정
  Future<PatientResult> updatePatient({
    required int patientId,
    String? name,
    int? birthYear,
    String? phone,
    List<int>? assignedDoctors,
    String? address,
    String? notes,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (birthYear != null) body['birth_year'] = birthYear;
      if (phone != null) body['phone'] = phone;
      if (assignedDoctors != null) body['assigned_doctors'] = assignedDoctors;
      if (address != null) body['address'] = address;
      if (notes != null) body['notes'] = notes;

      final response = await _apiClient.patch(
        '${ApiConfig.patientsEndpoint}$patientId/',
        body: body,
      );

      if (response.success && response.data != null) {
        return PatientResult(
          success: true,
          patient: response.data as Map<String, dynamic>,
          message: '환자 정보가 수정되었습니다.',
        );
      }

      return PatientResult(
        success: false,
        message: response.message ?? '환자 정보 수정 실패',
      );
    } catch (e) {
      return PatientResult(
        success: false,
        message: '환자 정보 수정 중 오류 발생: $e',
      );
    }
  }
}

// 환자 목록 조회 결과
class PatientsResult {
  final bool success;
  final String? message;
  final List<Map<String, dynamic>>? patients;

  PatientsResult({
    required this.success,
    this.message,
    this.patients,
  });
}

// 환자 정보 조회/생성/수정 결과
class PatientResult {
  final bool success;
  final String? message;
  final Map<String, dynamic>? patient;

  PatientResult({
    required this.success,
    this.message,
    this.patient,
  });
}
