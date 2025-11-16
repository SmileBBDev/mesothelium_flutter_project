// HTTP 클라이언트 - 공통 API 호출 로직
import 'dart:convert';
// import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';

import 'api_config.dart';
import '../../config/base_config.dart';
import 'error_handler.dart';

class ApiClient {
  final Dio _dio = BaseConfig().dio;

  // 공통 요청 처리 (재시도 로직 포함)
  Future<ApiResponse> _safeRequest(
    Future<Response> Function() request, {
    int maxRetries = 2,
    Duration retryDelay = const Duration(seconds: 1),
  }) async {
    int attempts = 0;

    while (attempts <= maxRetries) {
      try {
        final res = await request();

        /// 1) HTML 응답 필터링
        if (res.data is String) {
          final str = res.data as String;

          // HTML 에러 페이지인지 검사
          if (str.trim().startsWith("<!DOCTYPE") ||
              str.trim().startsWith("<html")) {
            return ApiResponse(
              success: false,
              message: "서버 오류 (HTML 응답)",
              statusCode: res.statusCode,
              data: null,
              errorType: AppErrorType.serverError,
            );
          }

          // JSON 문자열이면 Map으로 변환
          try {
            final decoded = jsonDecode(str);
            return ApiResponse(
              success: res.statusCode != null && res.statusCode! < 400,
              data: decoded,
              message: null,
              statusCode: res.statusCode,
            );
          } catch (_) {
            // JSON 파싱 실패 → 문자열 그대로 유지
            return ApiResponse(
              success: res.statusCode != null && res.statusCode! < 400,
              data: str,
              message: null,
              statusCode: res.statusCode,
            );
          }
        }

        /// 2) 정상 Map 응답 처리
        return ApiResponse(
          success: res.statusCode != null && res.statusCode! < 400,
          data: res.data,
          statusCode: res.statusCode,
        );
      } on DioException catch (e) {
        attempts++;
        final appError = ErrorHandler.handleDioError(e);
        ErrorHandler.logError(appError);

        // 재시도 가능한 에러이고 재시도 횟수가 남았으면 재시도
        if (ErrorHandler.isRetryable(appError) && attempts <= maxRetries) {
          await Future.delayed(retryDelay);
          continue;
        }

        // 재시도 불가능하거나 최대 재시도 횟수 초과
        return _handleDioError(e);
      } catch (e) {
        // 일반 예외 처리
        final appError = ErrorHandler.handleException(e);
        ErrorHandler.logError(appError);
        return ApiResponse(
          success: false,
          message: appError.message,
          data: null,
          errorType: appError.type,
        );
      }
    }

    // 최대 재시도 초과 (도달하지 않아야 하지만 안전장치)
    return ApiResponse(
      success: false,
      message: "최대 재시도 횟수를 초과했습니다",
      data: null,
      errorType: AppErrorType.unknown,
    );
  }

  // GET 요청
  Future<ApiResponse> get(
    String endpoint, {
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      return await _safeRequest(
        () => _dio.get(ApiConfig.getUrl(endpoint), queryParameters: queryParams),
      );
    } catch (e) {
      final appError = ErrorHandler.handleException(e);
      ErrorHandler.logError(appError);
      return ApiResponse(
        success: false,
        message: appError.message,
        errorType: appError.type,
      );
    }
  }

  // POST 요청
  Future<ApiResponse> post(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    try {
      return await _safeRequest(
        () => _dio.post(ApiConfig.getUrl(endpoint), data: body),
      );
    } catch (e) {
      final appError = ErrorHandler.handleException(e);
      ErrorHandler.logError(appError);
      return ApiResponse(
        success: false,
        message: appError.message,
        errorType: appError.type,
      );
    }
  }

  // PUT 요청
  Future<ApiResponse> put(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    try {
      return await _safeRequest(
        () => _dio.put(ApiConfig.getUrl(endpoint), data: body),
      );
    } catch (e) {
      final appError = ErrorHandler.handleException(e);
      ErrorHandler.logError(appError);
      return ApiResponse(
        success: false,
        message: appError.message,
        errorType: appError.type,
      );
    }
  }

  // PATCH 요청
  Future<ApiResponse> patch(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    try {
      return await _safeRequest(
        () => _dio.patch(ApiConfig.getUrl(endpoint), data: body),
      );
    } catch (e) {
      final appError = ErrorHandler.handleException(e);
      ErrorHandler.logError(appError);
      return ApiResponse(
        success: false,
        message: appError.message,
        errorType: appError.type,
      );
    }
  }

  // DELETE 요청
  Future<ApiResponse> delete(String endpoint) async {
    try {
      return await _safeRequest(
        () => _dio.delete(ApiConfig.getUrl(endpoint)),
      );
    } catch (e) {
      final appError = ErrorHandler.handleException(e);
      ErrorHandler.logError(appError);
      return ApiResponse(
        success: false,
        message: appError.message,
        errorType: appError.type,
      );
    }
  }

  // 공통 에러 처리
  ApiResponse _handleDioError(DioException e) {
    final appError = ErrorHandler.handleDioError(e);
    final status = e.response?.statusCode;
    final data = e.response?.data;

    // HTML 응답 에러 처리
    if (data is String &&
        (data.startsWith("<!DOCTYPE") || data.startsWith("<html"))) {
      return ApiResponse(
        success: false,
        message: "서버 오류 (HTML 응답)",
        statusCode: status,
        data: null,
        errorType: AppErrorType.serverError,
      );
    }

    // Django 에러 응답 처리: {"detail": "error message"}
    String? errorMessage = appError.message;
    if (data is Map<String, dynamic> && data.containsKey('detail')) {
      errorMessage = data['detail'].toString();
    }

    return ApiResponse(
      success: false,
      message: errorMessage,
      statusCode: status,
      data: data,
      errorType: appError.type,
    );
  }
}

// API 응답 클래스
class ApiResponse {
  final bool success;
  final String? message;
  final dynamic data;
  final int? statusCode;
  final AppErrorType? errorType;

  ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.statusCode,
    this.errorType,
  });

  /// 에러 메시지 반환 (사용자 친화적)
  String get errorMessage {
    if (errorType != null) {
      final appError = AppError(
        type: errorType!,
        message: message ?? '알 수 없는 오류',
        statusCode: statusCode,
      );
      return appError.userMessage;
    }
    return message ?? '알 수 없는 오류가 발생했습니다.';
  }

  /// AppError 객체로 변환
  AppError? toAppError() {
    if (!success && errorType != null) {
      return AppError(
        type: errorType!,
        message: message ?? '요청 실패',
        statusCode: statusCode,
        detail: data?.toString(),
      );
    }
    return null;
  }
}
