import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

/// 앱 전체에서 사용할 에러 타입
enum AppErrorType {
  network,           // 네트워크 연결 오류
  timeout,           // 타임아웃
  unauthorized,      // 인증 실패 (401)
  forbidden,         // 권한 없음 (403)
  notFound,          // 리소스 없음 (404)
  serverError,       // 서버 오류 (500+)
  tokenExpired,      // 토큰 만료
  invalidResponse,   // 잘못된 응답 형식
  unknown,           // 알 수 없는 오류
}

/// 앱 에러 클래스
class AppError {
  final AppErrorType type;
  final String message;
  final String? detail;
  final int? statusCode;
  final dynamic originalError;

  AppError({
    required this.type,
    required this.message,
    this.detail,
    this.statusCode,
    this.originalError,
  });

  @override
  String toString() {
    if (detail != null) {
      return '$message: $detail';
    }
    return message;
  }

  /// 사용자에게 표시할 메시지
  String get userMessage {
    switch (type) {
      case AppErrorType.network:
        return '네트워크 연결을 확인해주세요.';
      case AppErrorType.timeout:
        return '요청 시간이 초과되었습니다.\n잠시 후 다시 시도해주세요.';
      case AppErrorType.unauthorized:
        return '인증이 필요합니다.\n다시 로그인해주세요.';
      case AppErrorType.forbidden:
        return '접근 권한이 없습니다.';
      case AppErrorType.notFound:
        return '요청한 리소스를 찾을 수 없습니다.';
      case AppErrorType.serverError:
        return '서버 오류가 발생했습니다.\n잠시 후 다시 시도해주세요.';
      case AppErrorType.tokenExpired:
        return '세션이 만료되었습니다.\n다시 로그인해주세요.';
      case AppErrorType.invalidResponse:
        return '서버 응답 형식이 올바르지 않습니다.';
      case AppErrorType.unknown:
        return '알 수 없는 오류가 발생했습니다.';
    }
  }

  /// 로그용 상세 메시지
  String get logMessage {
    final buffer = StringBuffer();
    buffer.writeln('AppError:');
    buffer.writeln('  Type: $type');
    buffer.writeln('  Message: $message');
    if (detail != null) buffer.writeln('  Detail: $detail');
    if (statusCode != null) buffer.writeln('  Status: $statusCode');
    if (originalError != null) buffer.writeln('  Original: $originalError');
    return buffer.toString();
  }
}

/// 에러 핸들러 클래스
class ErrorHandler {
  /// DioException을 AppError로 변환
  static AppError handleDioError(DioException e) {
    final statusCode = e.response?.statusCode;
    final data = e.response?.data;

    // HTML 응답 에러 처리
    if (data is String &&
        (data.trim().startsWith('<!DOCTYPE') || data.trim().startsWith('<html'))) {
      return AppError(
        type: AppErrorType.serverError,
        message: '서버 오류 (HTML 응답)',
        detail: 'HTML 에러 페이지가 반환되었습니다.',
        statusCode: statusCode,
        originalError: e,
      );
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return AppError(
          type: AppErrorType.timeout,
          message: '요청 시간 초과',
          detail: '서버 응답이 지연되고 있습니다.',
          statusCode: statusCode,
          originalError: e,
        );

      case DioExceptionType.connectionError:
        return AppError(
          type: AppErrorType.network,
          message: '네트워크 연결 오류',
          detail: '인터넷 연결을 확인해주세요.',
          statusCode: statusCode,
          originalError: e,
        );

      case DioExceptionType.badResponse:
        return _handleBadResponse(e);

      case DioExceptionType.cancel:
        return AppError(
          type: AppErrorType.unknown,
          message: '요청이 취소되었습니다',
          statusCode: statusCode,
          originalError: e,
        );

      case DioExceptionType.badCertificate:
        return AppError(
          type: AppErrorType.network,
          message: 'SSL 인증서 오류',
          detail: '서버 인증서가 유효하지 않습니다.',
          statusCode: statusCode,
          originalError: e,
        );

      case DioExceptionType.unknown:
      default:
        return AppError(
          type: AppErrorType.unknown,
          message: '알 수 없는 오류',
          detail: e.message,
          statusCode: statusCode,
          originalError: e,
        );
    }
  }

  /// HTTP 응답 에러 처리
  static AppError _handleBadResponse(DioException e) {
    final statusCode = e.response?.statusCode;
    final data = e.response?.data;

    // 에러 메시지 추출 (Django REST Framework 형식)
    String? errorMessage;
    if (data is Map) {
      errorMessage = data['detail'] as String? ??
                     data['message'] as String? ??
                     data['error'] as String?;

      // non_field_errors 처리
      if (data['non_field_errors'] is List) {
        errorMessage = (data['non_field_errors'] as List).join(', ');
      }
    } else if (data is String) {
      errorMessage = data;
    }

    switch (statusCode) {
      case 400:
        return AppError(
          type: AppErrorType.invalidResponse,
          message: '잘못된 요청',
          detail: errorMessage ?? '요청 데이터를 확인해주세요.',
          statusCode: statusCode,
          originalError: e,
        );

      case 401:
        return AppError(
          type: AppErrorType.unauthorized,
          message: '인증 실패',
          detail: errorMessage ?? '로그인이 필요합니다.',
          statusCode: statusCode,
          originalError: e,
        );

      case 403:
        return AppError(
          type: AppErrorType.forbidden,
          message: '접근 권한 없음',
          detail: errorMessage ?? '권한이 부족합니다.',
          statusCode: statusCode,
          originalError: e,
        );

      case 404:
        return AppError(
          type: AppErrorType.notFound,
          message: '리소스를 찾을 수 없음',
          detail: errorMessage ?? '요청한 데이터가 존재하지 않습니다.',
          statusCode: statusCode,
          originalError: e,
        );

      case 500:
      case 502:
      case 503:
      case 504:
        return AppError(
          type: AppErrorType.serverError,
          message: '서버 오류',
          detail: errorMessage ?? '서버에 문제가 발생했습니다.',
          statusCode: statusCode,
          originalError: e,
        );

      default:
        return AppError(
          type: AppErrorType.unknown,
          message: 'HTTP 오류',
          detail: errorMessage ?? 'HTTP $statusCode 오류가 발생했습니다.',
          statusCode: statusCode,
          originalError: e,
        );
    }
  }

  /// 일반 Exception을 AppError로 변환
  static AppError handleException(dynamic error, [StackTrace? stackTrace]) {
    if (error is DioException) {
      return handleDioError(error);
    }

    if (error is AppError) {
      return error;
    }

    return AppError(
      type: AppErrorType.unknown,
      message: '예상치 못한 오류',
      detail: error.toString(),
      originalError: error,
    );
  }

  /// 에러를 로그에 출력
  static void logError(AppError error) {
    debugPrint(error.logMessage);
  }

  /// 에러를 사용자에게 표시 (SnackBar)
  static void showErrorSnackBar(BuildContext context, AppError error) {
    if (!context.mounted) return;

    final snackBar = SnackBar(
      content: Text(error.userMessage),
      backgroundColor: Colors.red[700],
      duration: const Duration(seconds: 4),
      action: SnackBarAction(
        label: '확인',
        textColor: Colors.white,
        onPressed: () {},
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  /// 에러를 사용자에게 표시 (Dialog)
  static void showErrorDialog(
    BuildContext context,
    AppError error, {
    VoidCallback? onRetry,
    VoidCallback? onLogout,
  }) {
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red[700]),
            const SizedBox(width: 8),
            const Text('오류'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(error.userMessage),
            if (error.detail != null && error.detail!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                error.detail!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
        actions: [
          // 토큰 만료 또는 인증 실패 시 로그아웃 버튼
          if ((error.type == AppErrorType.tokenExpired ||
                  error.type == AppErrorType.unauthorized) &&
              onLogout != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onLogout();
              },
              child: const Text('로그아웃'),
            ),

          // 재시도 버튼
          if (onRetry != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              child: const Text('재시도'),
            ),

          // 확인 버튼
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  /// 토큰 만료 여부 확인
  static bool isTokenExpired(AppError error) {
    return error.type == AppErrorType.tokenExpired ||
           (error.type == AppErrorType.unauthorized &&
            error.detail?.contains('token') == true);
  }

  /// 재시도 가능한 에러인지 확인
  static bool isRetryable(AppError error) {
    return error.type == AppErrorType.timeout ||
           error.type == AppErrorType.network ||
           error.type == AppErrorType.serverError;
  }
}

/// try-catch 헬퍼 함수 (재시도 로직 포함)
class ErrorHandlerHelper {
  /// 비동기 작업을 안전하게 실행 (재시도 포함)
  static Future<T?> executeWithRetry<T>({
    required Future<T> Function() task,
    int maxRetries = 2,
    Duration retryDelay = const Duration(seconds: 1),
    void Function(AppError)? onError,
  }) async {
    int attempts = 0;

    while (attempts <= maxRetries) {
      try {
        return await task();
      } catch (error, stackTrace) {
        attempts++;
        final appError = ErrorHandler.handleException(error, stackTrace);
        ErrorHandler.logError(appError);

        // 재시도 가능한 에러이고 재시도 횟수가 남았으면 재시도
        if (ErrorHandler.isRetryable(appError) && attempts <= maxRetries) {
          debugPrint('재시도 $attempts/$maxRetries...');
          await Future.delayed(retryDelay);
          continue;
        }

        // 재시도 불가능하거나 최대 재시도 횟수 초과
        if (onError != null) {
          onError(appError);
        }
        return null;
      }
    }

    return null;
  }

  /// 비동기 작업을 안전하게 실행 (재시도 없음)
  static Future<T?> execute<T>({
    required Future<T> Function() task,
    void Function(AppError)? onError,
  }) async {
    try {
      return await task();
    } catch (error, stackTrace) {
      final appError = ErrorHandler.handleException(error, stackTrace);
      ErrorHandler.logError(appError);

      if (onError != null) {
        onError(appError);
      }
      return null;
    }
  }

  /// 동기 작업을 안전하게 실행
  static T? executeSync<T>({
    required T Function() task,
    void Function(AppError)? onError,
  }) {
    try {
      return task();
    } catch (error, stackTrace) {
      final appError = ErrorHandler.handleException(error, stackTrace);
      ErrorHandler.logError(appError);

      if (onError != null) {
        onError(appError);
      }
      return null;
    }
  }
}
