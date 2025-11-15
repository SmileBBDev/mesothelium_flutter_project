/**
 * base_config.dart
 * 기본 설정 값 모음
 */
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BaseConfig{

  // 공통 config 정보
  static final BaseConfig _i = BaseConfig._();
  factory BaseConfig() => _i;
  BaseConfig._();

  // GCP 배포 서버 (Nginx 80포트)
  static String baseUrl = 'http://34.61.113.204';

  // 로컬 개발 서버 - 로컬 개발 시 사용
  // static String baseUrl = 'http://localhost:8000';
  // static String baseUrl = 'http://192.168.41.126:8000';

  final Dio dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
      validateStatus: (status) => true,  // ⭐ 모든 응답 허용
    ),
  );

  final _storage = const FlutterSecureStorage();
  String? _access;
  String? _refresh;
  bool _isRefreshing = false;
  final List<Function(String)> _retryQueue = [];

  Future<void> init() async {
    _access = await _storage.read(key: 'access');
    _refresh = await _storage.read(key: 'refresh');

    dio.interceptors.clear();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_access != null) {
            options.headers['Authorization'] = 'Bearer $_access';
          }
          handler.next(options);
        },
        onError: (e, handler) async {
          if (e.response?.statusCode == 401 && _refresh != null) {
            final req = e.requestOptions;

            if (_isRefreshing) {
              // 다른 refresh 진행 중이면 큐에 넣고 대기 후 재시도
              final completer = Completer<Response>();
              _retryQueue.add((String newAccess) async {
                req.headers['Authorization'] = 'Bearer $newAccess';
                completer.complete(await dio.fetch(req));
              });
              return handler.resolve(await completer.future);
            }

            _isRefreshing = true;
            try {
              // 표준 simplejwt refresh 엔드포인트 권장
              final resp = await Dio().post(
                '$baseUrl/api/auth/token/refresh/',
                data: {'refresh': _refresh},
              );

              final newAccess = resp.data['access'] as String;
              final newRefresh = (resp.data['refresh'] ?? _refresh) as String;

              await setTokens(newAccess, newRefresh);
              // 대기 중인 요청들 처리
              for (final cb in _retryQueue) {
                await cb(newAccess);
              }
              _retryQueue.clear();

              // 실패한 원 요청 재시도
              req.headers['Authorization'] = 'Bearer $newAccess';
              final retryResp = await dio.fetch(req);
              return handler.resolve(retryResp);
            } catch (_) {
              await clearTokens();
              _retryQueue.clear();
              _isRefreshing = false;
              return handler.reject(e);
            } finally {
              _isRefreshing = false;
            }
          }
          handler.next(e);
        },
      ),
    );
  }

  Future<void> setTokens(String access, String refresh) async {
    _access = access;
    _refresh = refresh;
    await _storage.write(key: 'access', value: access);
    await _storage.write(key: 'refresh', value: refresh);
  }

  Future<void> clearTokens() async {
    _access = null;
    _refresh = null;
    await _storage.delete(key: 'access');
    await _storage.delete(key: 'refresh');
  }

  FlutterSecureStorage get storage => _storage;



  static String vWorldKey = '0CFB4211-C4B2-3C4D-B3D9-CBB71FFB3CE9'; // 26년 5월 만료
  static String vWorldUrl = 'https://api.vworld.kr/req/wmts/1.0.0/<APIKEY>/Base/{z}/{y}/{x}.png';

}