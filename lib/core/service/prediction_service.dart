// 예측 결과 저장/조회 서비스
import 'api_client.dart';
import 'api_config.dart';
import 'error_handler.dart';

class PredictionService {
  static final PredictionService _instance = PredictionService._internal();
  factory PredictionService() => _instance;
  PredictionService._internal();

  final ApiClient _apiClient = ApiClient();

  // 예측 결과 저장
  Future<PredictionResult> savePrediction({
    required int patientId,
    required Map<String, dynamic> inputData,
    required int outputLabel,
    required double outputProba,
    int? requestedByDoctorId,
    String modelName = 'meso_xgb',
  }) async {
    try {
      final body = {
        'patient_id': patientId,
        'input_data': inputData,
        'output_label': outputLabel,
        'output_proba': outputProba,
        'model_name': modelName,
      };

      if (requestedByDoctorId != null) {
        body['requested_by_doctor_id'] = requestedByDoctorId;
      }

      final response = await _apiClient.post(
        ApiConfig.predictionsEndpoint,
        body: body,
      );

      if (response.success && response.data != null) {
        return PredictionResult(
          success: true,
          prediction: response.data as Map<String, dynamic>,
          message: '예측 결과가 저장되었습니다.',
        );
      }

      return PredictionResult(
        success: false,
        message: response.errorMessage,
        errorType: response.errorType,
      );
    } catch (e) {
      final appError = ErrorHandler.handleException(e);
      ErrorHandler.logError(appError);
      return PredictionResult(
        success: false,
        message: appError.userMessage,
        errorType: appError.type,
      );
    }
  }

  // 환자별 예측 결과 목록 조회
  Future<PredictionsResult> getPredictionsByPatient(int patientId) async {
    try {
      final response = await _apiClient.get(
        '${ApiConfig.predictionsEndpoint}?patient_id=$patientId',
      );

      if (response.success && response.data != null) {
        return PredictionsResult(
          success: true,
          predictions: List<Map<String, dynamic>>.from(response.data as List),
        );
      }

      return PredictionsResult(
        success: false,
        message: response.errorMessage,
        errorType: response.errorType,
      );
    } catch (e) {
      final appError = ErrorHandler.handleException(e);
      ErrorHandler.logError(appError);
      return PredictionsResult(
        success: false,
        message: appError.userMessage,
        errorType: appError.type,
      );
    }
  }

  // 의사별 예측 결과 목록 조회
  Future<PredictionsResult> getPredictionsByDoctor(int doctorId) async {
    try {
      final response = await _apiClient.get(
        '${ApiConfig.predictionsEndpoint}?doctor_id=$doctorId',
      );

      if (response.success && response.data != null) {
        return PredictionsResult(
          success: true,
          predictions: List<Map<String, dynamic>>.from(response.data as List),
        );
      }

      return PredictionsResult(
        success: false,
        message: response.errorMessage,
        errorType: response.errorType,
      );
    } catch (e) {
      final appError = ErrorHandler.handleException(e);
      ErrorHandler.logError(appError);
      return PredictionsResult(
        success: false,
        message: appError.userMessage,
        errorType: appError.type,
      );
    }
  }

  // 특정 예측 결과 상세 조회
  Future<PredictionResult> getPrediction(int predictionId) async {
    try {
      final response = await _apiClient.get(
        '${ApiConfig.predictionsEndpoint}$predictionId/',
      );

      if (response.success && response.data != null) {
        return PredictionResult(
          success: true,
          prediction: response.data as Map<String, dynamic>,
        );
      }

      return PredictionResult(
        success: false,
        message: response.errorMessage,
        errorType: response.errorType,
      );
    } catch (e) {
      final appError = ErrorHandler.handleException(e);
      ErrorHandler.logError(appError);
      return PredictionResult(
        success: false,
        message: appError.userMessage,
        errorType: appError.type,
      );
    }
  }

  // 전체 예측 결과 목록 조회 (관리자용)
  Future<PredictionsResult> getAllPredictions() async {
    try {
      final response = await _apiClient.get(ApiConfig.predictionsEndpoint);

      if (response.success && response.data != null) {
        return PredictionsResult(
          success: true,
          predictions: List<Map<String, dynamic>>.from(response.data as List),
        );
      }

      return PredictionsResult(
        success: false,
        message: response.errorMessage,
        errorType: response.errorType,
      );
    } catch (e) {
      final appError = ErrorHandler.handleException(e);
      ErrorHandler.logError(appError);
      return PredictionsResult(
        success: false,
        message: appError.userMessage,
        errorType: appError.type,
      );
    }
  }

  // 예측 결과 삭제 (관리자용)
  Future<PredictionResult> deletePrediction(int predictionId) async {
    try {
      final response = await _apiClient.delete(
        '${ApiConfig.predictionsEndpoint}$predictionId/',
      );

      if (response.success) {
        return PredictionResult(
          success: true,
          message: '예측 결과가 삭제되었습니다.',
        );
      }

      return PredictionResult(
        success: false,
        message: response.errorMessage,
        errorType: response.errorType,
      );
    } catch (e) {
      final appError = ErrorHandler.handleException(e);
      ErrorHandler.logError(appError);
      return PredictionResult(
        success: false,
        message: appError.userMessage,
        errorType: appError.type,
      );
    }
  }
}

// 단일 예측 결과
class PredictionResult {
  final bool success;
  final String? message;
  final Map<String, dynamic>? prediction;
  final AppErrorType? errorType;

  PredictionResult({
    required this.success,
    this.message,
    this.prediction,
    this.errorType,
  });
}

// 예측 결과 목록
class PredictionsResult {
  final bool success;
  final String? message;
  final List<Map<String, dynamic>>? predictions;
  final AppErrorType? errorType;

  PredictionsResult({
    required this.success,
    this.message,
    this.predictions,
    this.errorType,
  });
}
