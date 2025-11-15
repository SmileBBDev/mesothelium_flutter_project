import 'api_client.dart';
import 'api_config.dart';

class StaffService {
  static final StaffService _instance = StaffService._internal();
  factory StaffService() => _instance;
  StaffService._internal();

  final ApiClient _apiClient = ApiClient();

  // 대량 회원 등록
  Future<BulkRegisterResult> bulkRegister(List<Map<String, dynamic>> users) async {
    final response = await _apiClient.post(
      ApiConfig.bulkRegisterEndpoint,
      body: {'users': users},
    );

    if (response.success && response.data != null) {
      return BulkRegisterResult(
        success: true,
        message: response.data['message'],
        results: response.data['results'],
      );
    }

    return BulkRegisterResult(
      success: false,
      message: response.message ?? '대량 등록에 실패했습니다.',
    );
  }

  // 환자에게 의사 배정
  Future<AssignDoctorsResult> assignDoctors({
    required int patientId,
    required List<int> doctorIds,
  }) async {
    final response = await _apiClient.post(
      ApiConfig.assignDoctorsEndpoint,
      body: {
        'patient_id': patientId,
        'doctor_ids': doctorIds,
      },
    );

    if (response.success && response.data != null) {
      return AssignDoctorsResult(
        success: true,
        message: response.data['message'],
        patient: response.data['patient'],
      );
    }

    return AssignDoctorsResult(
      success: false,
      message: response.message ?? '의사 배정에 실패했습니다.',
    );
  }

  // 여러 환자에게 한 의사 일괄 배정
  Future<BulkAssignDoctorResult> bulkAssignDoctor({
    required List<int> patientIds,
    required int doctorId,
    required String action, // 'add' or 'remove'
  }) async {
    final response = await _apiClient.post(
      ApiConfig.bulkAssignDoctorEndpoint,
      body: {
        'patient_ids': patientIds,
        'doctor_id': doctorId,
        'action': action,
      },
    );

    if (response.success && response.data != null) {
      return BulkAssignDoctorResult(
        success: true,
        message: response.data['message'],
        doctor: response.data['doctor'],
        results: response.data['results'],
      );
    }

    return BulkAssignDoctorResult(
      success: false,
      message: response.message ?? '일괄 배정에 실패했습니다.',
    );
  }

  // 대량 승인/거부
  Future<BulkApproveResult> bulkApprove({
    required List<int> userIds,
    required String action, // 'approve' or 'reject'
  }) async {
    final response = await _apiClient.post(
      ApiConfig.bulkApproveEndpoint,
      body: {
        'user_ids': userIds,
        'action': action,
      },
    );

    if (response.success && response.data != null) {
      return BulkApproveResult(
        success: true,
        message: response.data['message'],
        results: response.data['results'],
      );
    }

    return BulkApproveResult(
      success: false,
      message: response.message ?? '승인 처리에 실패했습니다.',
    );
  }
}

// Result classes
class BulkRegisterResult {
  final bool success;
  final String? message;
  final Map<String, dynamic>? results;

  BulkRegisterResult({
    required this.success,
    this.message,
    this.results,
  });
}

class AssignDoctorsResult {
  final bool success;
  final String? message;
  final Map<String, dynamic>? patient;

  AssignDoctorsResult({
    required this.success,
    this.message,
    this.patient,
  });
}

class BulkAssignDoctorResult {
  final bool success;
  final String? message;
  final Map<String, dynamic>? doctor;
  final Map<String, dynamic>? results;

  BulkAssignDoctorResult({
    required this.success,
    this.message,
    this.doctor,
    this.results,
  });
}

class BulkApproveResult {
  final bool success;
  final String? message;
  final Map<String, dynamic>? results;

  BulkApproveResult({
    required this.success,
    this.message,
    this.results,
  });
}
