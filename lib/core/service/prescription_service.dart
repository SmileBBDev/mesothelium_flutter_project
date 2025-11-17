// 처방전 CRUD 서비스
import 'api_client.dart';
import 'api_config.dart';
import 'error_handler.dart';

class PrescriptionService {
  static final PrescriptionService _instance = PrescriptionService._internal();
  factory PrescriptionService() => _instance;
  PrescriptionService._internal();

  final ApiClient _apiClient = ApiClient();

  // 처방전 생성
  Future<PrescriptionResult> createPrescription({
    required String title,
    required String contentDelta,
    int? patientId,
    int? doctorId,
  }) async {
    try {
      final body = <String, dynamic>{
        'title': title,
        'content_delta': contentDelta,
      };

      if (patientId != null) {
        body['patient'] = patientId;
      }
      if (doctorId != null) {
        body['doctor'] = doctorId;
      }

      final response = await _apiClient.post(
        ApiConfig.prescriptionsEndpoint,
        body: body,
      );

      if (response.success && response.data != null) {
        return PrescriptionResult(
          success: true,
          prescription: response.data as Map<String, dynamic>,
          message: '처방전이 생성되었습니다.',
        );
      }

      return PrescriptionResult(
        success: false,
        message: response.errorMessage,
        errorType: response.errorType,
      );
    } catch (e) {
      final appError = ErrorHandler.handleException(e);
      ErrorHandler.logError(appError);
      return PrescriptionResult(
        success: false,
        message: appError.userMessage,
        errorType: appError.type,
      );
    }
  }

  // 처방전 조회 (단일)
  Future<PrescriptionResult> getPrescription(int prescriptionId) async {
    try {
      final response = await _apiClient.get(
        '${ApiConfig.prescriptionsEndpoint}$prescriptionId/',
      );

      if (response.success && response.data != null) {
        return PrescriptionResult(
          success: true,
          prescription: response.data as Map<String, dynamic>,
        );
      }

      return PrescriptionResult(
        success: false,
        message: response.errorMessage,
        errorType: response.errorType,
      );
    } catch (e) {
      final appError = ErrorHandler.handleException(e);
      ErrorHandler.logError(appError);
      return PrescriptionResult(
        success: false,
        message: appError.userMessage,
        errorType: appError.type,
      );
    }
  }

  // 처방전 목록 조회 (전체)
  Future<PrescriptionsResult> getAllPrescriptions() async {
    try {
      final response = await _apiClient.get(ApiConfig.prescriptionsEndpoint);

      if (response.success && response.data != null) {
        return PrescriptionsResult(
          success: true,
          prescriptions: List<Map<String, dynamic>>.from(response.data as List),
        );
      }

      return PrescriptionsResult(
        success: false,
        message: response.errorMessage,
        errorType: response.errorType,
      );
    } catch (e) {
      final appError = ErrorHandler.handleException(e);
      ErrorHandler.logError(appError);
      return PrescriptionsResult(
        success: false,
        message: appError.userMessage,
        errorType: appError.type,
      );
    }
  }

  // 환자별 처방전 조회
  Future<PrescriptionsResult> getPrescriptionsByPatient(int patientId) async {
    try {
      final response = await _apiClient.get(
        '${ApiConfig.prescriptionsByPatientEndpoint}$patientId/',
      );

      if (response.success && response.data != null) {
        return PrescriptionsResult(
          success: true,
          prescriptions: List<Map<String, dynamic>>.from(response.data as List),
        );
      }

      return PrescriptionsResult(
        success: false,
        message: response.errorMessage,
        errorType: response.errorType,
      );
    } catch (e) {
      final appError = ErrorHandler.handleException(e);
      ErrorHandler.logError(appError);
      return PrescriptionsResult(
        success: false,
        message: appError.userMessage,
        errorType: appError.type,
      );
    }
  }

  // 의사별 처방전 조회
  Future<PrescriptionsResult> getPrescriptionsByDoctor(int doctorId) async {
    try {
      final response = await _apiClient.get(
        '${ApiConfig.prescriptionsByDoctorEndpoint}$doctorId/',
      );

      if (response.success && response.data != null) {
        return PrescriptionsResult(
          success: true,
          prescriptions: List<Map<String, dynamic>>.from(response.data as List),
        );
      }

      return PrescriptionsResult(
        success: false,
        message: response.errorMessage,
        errorType: response.errorType,
      );
    } catch (e) {
      final appError = ErrorHandler.handleException(e);
      ErrorHandler.logError(appError);
      return PrescriptionsResult(
        success: false,
        message: appError.userMessage,
        errorType: appError.type,
      );
    }
  }

  // 처방전 수정
  Future<PrescriptionResult> updatePrescription({
    required int prescriptionId,
    String? title,
    String? contentDelta,
    int? patientId,
    int? doctorId,
  }) async {
    try {
      final body = <String, dynamic>{};

      if (title != null) body['title'] = title;
      if (contentDelta != null) body['content_delta'] = contentDelta;
      if (patientId != null) body['patient'] = patientId;
      if (doctorId != null) body['doctor'] = doctorId;

      final response = await _apiClient.patch(
        '${ApiConfig.prescriptionsEndpoint}$prescriptionId/',
        body: body,
      );

      if (response.success && response.data != null) {
        return PrescriptionResult(
          success: true,
          prescription: response.data as Map<String, dynamic>,
          message: '처방전이 수정되었습니다.',
        );
      }

      return PrescriptionResult(
        success: false,
        message: response.errorMessage,
        errorType: response.errorType,
      );
    } catch (e) {
      final appError = ErrorHandler.handleException(e);
      ErrorHandler.logError(appError);
      return PrescriptionResult(
        success: false,
        message: appError.userMessage,
        errorType: appError.type,
      );
    }
  }

  // 처방전 삭제
  Future<PrescriptionResult> deletePrescription(int prescriptionId) async {
    try {
      final response = await _apiClient.delete(
        '${ApiConfig.prescriptionsEndpoint}$prescriptionId/',
      );

      if (response.success) {
        return PrescriptionResult(
          success: true,
          message: '처방전이 삭제되었습니다.',
        );
      }

      return PrescriptionResult(
        success: false,
        message: response.errorMessage,
        errorType: response.errorType,
      );
    } catch (e) {
      final appError = ErrorHandler.handleException(e);
      ErrorHandler.logError(appError);
      return PrescriptionResult(
        success: false,
        message: appError.userMessage,
        errorType: appError.type,
      );
    }
  }
}

// 단일 처방전 결과
class PrescriptionResult {
  final bool success;
  final String? message;
  final Map<String, dynamic>? prescription;
  final AppErrorType? errorType;

  PrescriptionResult({
    required this.success,
    this.message,
    this.prescription,
    this.errorType,
  });
}

// 처방전 목록 결과
class PrescriptionsResult {
  final bool success;
  final String? message;
  final List<Map<String, dynamic>>? prescriptions;
  final AppErrorType? errorType;

  PrescriptionsResult({
    required this.success,
    this.message,
    this.prescriptions,
    this.errorType,
  });
}
