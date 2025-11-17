// ML 예측 서비스 (Django 프록시를 통해 Flask ML 서버와 통신)
import 'api_client.dart';
import 'api_config.dart';
import 'error_handler.dart';

class MlService {
  static final MlService _instance = MlService._internal();
  factory MlService() => _instance;
  MlService._internal();

  final ApiClient _apiClient = ApiClient();

  // ML 스키마 조회 (필요한 입력 필드 정보)
  Future<MlSchemaResult> getSchema() async {
    try {
      final response = await _apiClient.get(ApiConfig.mlSchemaEndpoint);

      if (response.success && response.data != null) {
        return MlSchemaResult(
          success: true,
          schema: response.data as Map<String, dynamic>,
        );
      }

      return MlSchemaResult(
        success: false,
        message: response.errorMessage,
        errorType: response.errorType,
      );
    } catch (e) {
      final appError = ErrorHandler.handleException(e);
      ErrorHandler.logError(appError);
      return MlSchemaResult(
        success: false,
        message: appError.userMessage,
        errorType: appError.type,
      );
    }
  }

  // ML 예측 수행 (Django 프록시 사용, 자동 저장 포함)
  Future<MlPredictResult> predict({
    required int patientId,
    required List<Map<String, dynamic>> data,
    String? modelName,
  }) async {
    try {
      final body = {
        'patient_id': patientId,  // 자동 저장을 위해 필수
        'data': data,
      };

      if (modelName != null) {
        body['model_name'] = modelName;
      }

      print('[ML 예측 요청] Patient ID: $patientId');
      print('[ML 예측 요청] Data: $data');
      print('[ML 예측 요청] Body: $body');

      final response = await _apiClient.post(
        ApiConfig.mlPredictEndpoint,
        body: body,
      );

      print('[ML 예측 응답] Success: ${response.success}');
      print('[ML 예측 응답] Status: ${response.statusCode}');
      print('[ML 예측 응답] Data: ${response.data}');
      print('[ML 예측 응답] Message: ${response.errorMessage}');

      if (response.success && response.data != null) {
        return MlPredictResult(
          success: true,
          result: response.data as Map<String, dynamic>,
        );
      }

      return MlPredictResult(
        success: false,
        message: response.errorMessage,
        errorType: response.errorType,
      );
    } catch (e) {
      print('[ML 예측 오류] Exception: $e');
      final appError = ErrorHandler.handleException(e);
      ErrorHandler.logError(appError);
      return MlPredictResult(
        success: false,
        message: appError.userMessage,
        errorType: appError.type,
      );
    }
  }

  // 단일 예측 (편의 메서드) - 11개 base_features
  Future<MlPredictResult> predictSingle({
    required int patientId,
    required int age,
    required int durationOfSymptoms,
    required double plateletCount,
    required double cellCount,
    required double bloodLacticDehydrogenise,
    required double pleuralLacticDehydrogenise,
    required double pleuralProtein,
    required double totalProtein,
    required double albumin,
    required double cReactiveProtein,
    required int durationOfAsbestosExposure,
    String? modelName,
  }) async {
    final data = {
      'age': age,
      'duration_of_symptoms': durationOfSymptoms,
      'platelet_count_(PLT)': plateletCount,
      'cell_count_(WBC)': cellCount,
      'blood_lactic_dehydrogenise_(LDH)': bloodLacticDehydrogenise,
      'pleural_lactic_dehydrogenise': pleuralLacticDehydrogenise,
      'pleural_protein': pleuralProtein,
      'total_protein': totalProtein,
      'albumin': albumin,
      'C-reactive_protein_(CRP)': cReactiveProtein,
      'duration_of_asbestos_exposure': durationOfAsbestosExposure,
    };

    return predict(
      patientId: patientId,
      data: [data],
      modelName: modelName,
    );
  }

  // ML 모델 리로드 (관리자 전용)
  Future<MlReloadResult> reloadModel() async {
    try {
      final response = await _apiClient.post(ApiConfig.mlReloadEndpoint);

      if (response.success) {
        return MlReloadResult(
          success: true,
          message: 'ML 모델이 리로드되었습니다.',
        );
      }

      return MlReloadResult(
        success: false,
        message: response.errorMessage,
        errorType: response.errorType,
      );
    } catch (e) {
      final appError = ErrorHandler.handleException(e);
      ErrorHandler.logError(appError);
      return MlReloadResult(
        success: false,
        message: appError.userMessage,
        errorType: appError.type,
      );
    }
  }
}

// ML 스키마 조회 결과
class MlSchemaResult {
  final bool success;
  final String? message;
  final Map<String, dynamic>? schema;
  final AppErrorType? errorType;

  MlSchemaResult({
    required this.success,
    this.message,
    this.schema,
    this.errorType,
  });
}

// ML 예측 결과
class MlPredictResult {
  final bool success;
  final String? message;
  final Map<String, dynamic>? result;
  final AppErrorType? errorType;

  MlPredictResult({
    required this.success,
    this.message,
    this.result,
    this.errorType,
  });

  // 예측 확률 가져오기 (0.0 ~ 1.0)
  List<double>? get predictionProbabilities {
    if (result == null) return null;
    final proba = result!['pred_proba'];
    if (proba is List) {
      return proba.map((e) => (e as num).toDouble()).toList();
    }
    return null;
  }

  // 예측 레이블 가져오기 (0 또는 1)
  List<int>? get predictionLabels {
    if (result == null) return null;
    final labels = result!['pred_label'];
    if (labels is List) {
      return labels.map((e) => (e as num).toInt()).toList();
    }
    return null;
  }

  // 첫 번째 예측 확률 (단일 예측용)
  double? get firstProbability {
    final probas = predictionProbabilities;
    return probas != null && probas.isNotEmpty ? probas.first : null;
  }

  // 첫 번째 예측 레이블 (단일 예측용)
  int? get firstLabel {
    final labels = predictionLabels;
    return labels != null && labels.isNotEmpty ? labels.first : null;
  }
}

// ML 모델 리로드 결과
class MlReloadResult {
  final bool success;
  final String message;
  final AppErrorType? errorType;

  MlReloadResult({
    required this.success,
    required this.message,
    this.errorType,
  });
}
