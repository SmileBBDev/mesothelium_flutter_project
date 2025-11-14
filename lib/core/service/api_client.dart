// HTTP 클라이언트 - 공통 API 호출 로직
import 'dart:convert';
// import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';
import '../../config/base_config.dart';

class ApiClient {
  final Dio _dio = BaseConfig().dio;

  // 공통 요청 처리
  Future<ApiResponse> _safeRequest(Future<Response> Function() request) async {
    try {
      final res = await request();

      /// 1) HTML 응답 필터링
      if (res.data is String) {
        final str = res.data as String;

        // HTML 에러 페이지인지 검사
        if (str.trim().startsWith("<!DOCTYPE") || str.trim().startsWith("<html")) {
          return ApiResponse(
            success: false,
            message: "서버 오류 (HTML 응답)",
            statusCode: res.statusCode,
            data: null,
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
      return _handleDioError(e);
    }
  }

  // GET 요청
  Future<ApiResponse> get(
    String endpoint, {
    Map<String, dynamic>? queryParams,
  }) async {
    return _safeRequest(() => _dio.get(ApiConfig.getUrl(endpoint), queryParameters: queryParams));
  }

  // POST 요청
  Future<ApiResponse> post(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    return _safeRequest(() => _dio.post(ApiConfig.getUrl(endpoint), data: body));
  }

  // PUT 요청
  Future<ApiResponse> put(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    return _safeRequest(() => _dio.put(ApiConfig.getUrl(endpoint), data: body));
  }

  // PATCH 요청
  Future<ApiResponse> patch(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    return _safeRequest(() => _dio.patch(ApiConfig.getUrl(endpoint), data: body));
  }

  // DELETE 요청
  Future<ApiResponse> delete(String endpoint) async {
    return _safeRequest(() => _dio.delete(ApiConfig.getUrl(endpoint)));
  }

  // 공통 에러 처리
  ApiResponse _handleDioError(DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;

    // HTML 응답 에러 처리
    if (data is String && (data.startsWith("<!DOCTYPE") || data.startsWith("<html"))) {
      return ApiResponse(
        success: false,
        message: "서버 오류 (HTML 응답)",
        statusCode: status,
        data: null,
      );
    }

    return ApiResponse(
      success: false,
      message: e.message ?? "요청 실패",
      statusCode: status,
      data: data,
    );
  }
}


// API 응답 클래스
class ApiResponse {
  final bool success;
  final String? message;
  final dynamic data;
  final int? statusCode;

  ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.statusCode,
  });
}
