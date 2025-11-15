// 환자 관리 서비스
import 'api_client.dart';
import 'api_config.dart';

class PatientService {
  static final PatientService _instance = PatientService._internal();
  factory PatientService() => _instance;
  PatientService._internal();

  final ApiClient _apiClient = ApiClient();

  // 환자 목록 조회
  Future<PatientsResult> getPatients({
    Map<String, dynamic>? filters,
  }) async {
    try {
      final response = await _apiClient.get(
        ApiConfig.patientsEndpoint,
        queryParams: filters,
      );

      if (response.success && response.data != null) {
        return PatientsResult(
          success: true,
          patients: List<Map<String, dynamic>>.from(response.data as List),
        );
      }

      return PatientsResult(
        success: false,
        message: response.message ?? '환자 목록 조회 실패',
      );
    } catch (e) {
      return PatientsResult(
        success: false,
        message: '환자 목록 조회 중 오류 발생: $e',
      );
    }
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

  // 특정 의사의 환자 목록 조회
  Future<PatientsResult> getPatientsByDoctor(int doctorId) async {
    try {
      final response = await _apiClient.get(
        '${ApiConfig.patientsByDoctorEndpoint}$doctorId/',
      );

      if (response.success && response.data != null) {
        return PatientsResult(
          success: true,
          patients: List<Map<String, dynamic>>.from(response.data as List),
        );
      }

      return PatientsResult(
        success: false,
        message: response.message ?? '의사의 환자 목록 조회 실패',
      );
    } catch (e) {
      return PatientsResult(
        success: false,
        message: '의사의 환자 목록 조회 중 오류 발생: $e',
      );
    }
  }

  // 내 환자 목록 조회 (의사용)
  Future<PatientsResult> getMyPatients() async {
    try {
      final response = await _apiClient.get(ApiConfig.patientsMineEndpoint);

      if (response.success && response.data != null) {
        return PatientsResult(
          success: true,
          patients: List<Map<String, dynamic>>.from(response.data as List),
        );
      }

      return PatientsResult(
        success: false,
        message: response.message ?? '내 환자 목록 조회 실패',
      );
    } catch (e) {
      return PatientsResult(
        success: false,
        message: '내 환자 목록 조회 중 오류 발생: $e',
      );
    }
  }

  // 특정 환자 조회
  Future<PatientResult> getPatient(int patientId) async {
    try {
      final response = await _apiClient.get('${ApiConfig.patientsEndpoint}$patientId/');

      if (response.success && response.data != null) {
        return PatientResult(
          success: true,
          patient: response.data as Map<String, dynamic>,
        );
      }

      return PatientResult(
        success: false,
        message: response.message ?? '환자 정보 조회 실패',
      );
    } catch (e) {
      return PatientResult(
        success: false,
        message: '환자 정보 조회 중 오류 발생: $e',
      );
    }
  }

  // 환자 생성 (스태프/관리자 전용)
  Future<PatientResult> createPatient({
    required String name,
    required int birthYear,
    required String phone,
    List<int>? assignedDoctors,
    String? address,
    String? notes,
  }) async {
    try {
      final body = {
        'name': name,
        'birth_year': birthYear,
        'phone': phone,
        if (assignedDoctors != null) 'assigned_doctors': assignedDoctors,
        if (address != null) 'address': address,
        if (notes != null) 'notes': notes,
      };

      final response = await _apiClient.post(
        ApiConfig.patientsEndpoint,
        body: body,
      );

      if (response.success && response.data != null) {
        return PatientResult(
          success: true,
          patient: response.data as Map<String, dynamic>,
          message: '환자가 생성되었습니다.',
        );
      }

      return PatientResult(
        success: false,
        message: response.message ?? '환자 생성 실패',
      );
    } catch (e) {
      return PatientResult(
        success: false,
        message: '환자 생성 중 오류 발생: $e',
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

  // 환자 삭제 (관리자 전용)
  Future<DeleteResult> deletePatient(int patientId) async {
    try {
      final response = await _apiClient.delete(
        '${ApiConfig.patientsEndpoint}$patientId/',
      );

      if (response.success) {
        return DeleteResult(
          success: true,
          message: '환자가 삭제되었습니다.',
        );
      }

      return DeleteResult(
        success: false,
        message: response.message ?? '환자 삭제 실패',
      );
    } catch (e) {
      return DeleteResult(
        success: false,
        message: '환자 삭제 중 오류 발생: $e',
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

// 삭제 결과
class DeleteResult {
  final bool success;
  final String message;

  DeleteResult({
    required this.success,
    required this.message,
  });
}
