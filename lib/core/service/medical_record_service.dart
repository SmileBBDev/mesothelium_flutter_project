// 진료 기록 서비스 - Django API 연동
import 'api_client.dart';
import 'api_config.dart';

class MedicalRecordService {
  static final MedicalRecordService _instance = MedicalRecordService._internal();
  factory MedicalRecordService() => _instance;
  MedicalRecordService._internal();

  final ApiClient _apiClient = ApiClient();

  /// 진료 기록 목록 조회
  Future<MedicalRecordsResult> getMedicalRecords({
    int? patientId,
    int? doctorId,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (patientId != null) queryParams['patient_id'] = patientId.toString();
      if (doctorId != null) queryParams['doctor_id'] = doctorId.toString();

      final response = await _apiClient.get(
        ApiConfig.medicalRecordsEndpoint,
        queryParams: queryParams,
      );

      if (response.success && response.data != null) {
        return MedicalRecordsResult(
          success: true,
          records: List<Map<String, dynamic>>.from(response.data as List),
        );
      }

      return MedicalRecordsResult(
        success: false,
        message: response.message ?? '진료 기록 조회 실패',
      );
    } catch (e) {
      return MedicalRecordsResult(
        success: false,
        message: '진료 기록 조회 중 오류 발생: $e',
      );
    }
  }

  /// 특정 환자의 진료 기록 목록 조회
  Future<MedicalRecordsResult> getRecordsByPatient(int patientId) async {
    try {
      final response = await _apiClient.get(
        '${ApiConfig.medicalRecordsEndpoint}by-patient/$patientId/',
      );

      if (response.success && response.data != null) {
        return MedicalRecordsResult(
          success: true,
          records: List<Map<String, dynamic>>.from(response.data as List),
        );
      }

      return MedicalRecordsResult(
        success: false,
        message: response.message ?? '환자 진료 기록 조회 실패',
      );
    } catch (e) {
      return MedicalRecordsResult(
        success: false,
        message: '환자 진료 기록 조회 중 오류 발생: $e',
      );
    }
  }

  /// 특정 환자의 최신 진료 기록 조회
  Future<MedicalRecordResult> getLatestRecord(int patientId) async {
    try {
      final response = await _apiClient.get(
        '${ApiConfig.medicalRecordsEndpoint}latest/$patientId/',
      );

      if (response.success && response.data != null) {
        return MedicalRecordResult(
          success: true,
          record: response.data as Map<String, dynamic>,
        );
      }

      return MedicalRecordResult(
        success: false,
        message: response.message ?? '최신 진료 기록 조회 실패',
      );
    } catch (e) {
      return MedicalRecordResult(
        success: false,
        message: '최신 진료 기록 조회 중 오류 발생: $e',
      );
    }
  }

  /// 특정 진료 기록 상세 조회
  Future<MedicalRecordResult> getMedicalRecord(int recordId) async {
    try {
      final response = await _apiClient.get(
        '${ApiConfig.medicalRecordsEndpoint}$recordId/',
      );

      if (response.success && response.data != null) {
        return MedicalRecordResult(
          success: true,
          record: response.data as Map<String, dynamic>,
        );
      }

      return MedicalRecordResult(
        success: false,
        message: response.message ?? '진료 기록 상세 조회 실패',
      );
    } catch (e) {
      return MedicalRecordResult(
        success: false,
        message: '진료 기록 상세 조회 중 오류 발생: $e',
      );
    }
  }

  /// 진료 기록 생성
  Future<MedicalRecordResult> createMedicalRecord({
    required int patientId,
    int? doctorId,
    String? title,
    String? notes,
    required Map<String, dynamic> contentDeltaJson,
    String? contentHtml,
  }) async {
    try {
      final body = <String, dynamic>{
        'patient_id': patientId,
        'content_delta_json': contentDeltaJson,
      };

      if (doctorId != null) body['doctor_id'] = doctorId;
      if (title != null && title.isNotEmpty) body['title'] = title;
      if (notes != null && notes.isNotEmpty) body['notes'] = notes;
      if (contentHtml != null && contentHtml.isNotEmpty) body['content_html'] = contentHtml;

      final response = await _apiClient.post(
        ApiConfig.medicalRecordsEndpoint,
        body: body,
      );

      if (response.success && response.data != null) {
        return MedicalRecordResult(
          success: true,
          record: response.data as Map<String, dynamic>,
          message: '진료 기록이 생성되었습니다.',
        );
      }

      return MedicalRecordResult(
        success: false,
        message: response.message ?? '진료 기록 생성 실패',
      );
    } catch (e) {
      return MedicalRecordResult(
        success: false,
        message: '진료 기록 생성 중 오류 발생: $e',
      );
    }
  }

  /// 진료 기록 수정
  Future<MedicalRecordResult> updateMedicalRecord({
    required int recordId,
    int? patientId,
    int? doctorId,
    String? title,
    String? notes,
    Map<String, dynamic>? contentDeltaJson,
    String? contentHtml,
  }) async {
    try {
      final body = <String, dynamic>{};

      if (patientId != null) body['patient_id'] = patientId;
      if (doctorId != null) body['doctor_id'] = doctorId;
      if (title != null) body['title'] = title;
      if (notes != null) body['notes'] = notes;
      if (contentDeltaJson != null) body['content_delta_json'] = contentDeltaJson;
      if (contentHtml != null) body['content_html'] = contentHtml;

      final response = await _apiClient.patch(
        '${ApiConfig.medicalRecordsEndpoint}$recordId/',
        body: body,
      );

      if (response.success && response.data != null) {
        return MedicalRecordResult(
          success: true,
          record: response.data as Map<String, dynamic>,
          message: '진료 기록이 수정되었습니다.',
        );
      }

      return MedicalRecordResult(
        success: false,
        message: response.message ?? '진료 기록 수정 실패',
      );
    } catch (e) {
      return MedicalRecordResult(
        success: false,
        message: '진료 기록 수정 중 오류 발생: $e',
      );
    }
  }

  /// 진료 기록 삭제
  Future<DeleteResult> deleteMedicalRecord(int recordId) async {
    try {
      final response = await _apiClient.delete(
        '${ApiConfig.medicalRecordsEndpoint}$recordId/',
      );

      if (response.success) {
        return DeleteResult(
          success: true,
          message: '진료 기록이 삭제되었습니다.',
        );
      }

      return DeleteResult(
        success: false,
        message: response.message ?? '진료 기록 삭제 실패',
      );
    } catch (e) {
      return DeleteResult(
        success: false,
        message: '진료 기록 삭제 중 오류 발생: $e',
      );
    }
  }
}

// 진료 기록 목록 조회 결과
class MedicalRecordsResult {
  final bool success;
  final String? message;
  final List<Map<String, dynamic>>? records;

  MedicalRecordsResult({
    required this.success,
    this.message,
    this.records,
  });
}

// 진료 기록 단일 조회/생성/수정 결과
class MedicalRecordResult {
  final bool success;
  final String? message;
  final Map<String, dynamic>? record;

  MedicalRecordResult({
    required this.success,
    this.message,
    this.record,
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
