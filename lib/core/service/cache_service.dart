import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';

/// 캐시 타입
enum CacheType {
  memory,      // 메모리 캐시 (앱 실행 중에만 유지)
  preferences, // SharedPreferences (간단한 key-value)
  hive,        // Hive (복잡한 객체)
}

/// 캐시 데이터 래퍼 (만료 시간 포함)
class CacheData<T> {
  final T data;
  final DateTime cachedAt;
  final Duration? ttl; // Time To Live

  CacheData({
    required this.data,
    required this.cachedAt,
    this.ttl,
  });

  bool get isExpired {
    if (ttl == null) return false;
    return DateTime.now().difference(cachedAt) > ttl!;
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data,
      'cachedAt': cachedAt.toIso8601String(),
      'ttl': ttl?.inSeconds,
    };
  }

  factory CacheData.fromJson(Map<String, dynamic> json, T Function(dynamic) fromData) {
    return CacheData(
      data: fromData(json['data']),
      cachedAt: DateTime.parse(json['cachedAt']),
      ttl: json['ttl'] != null ? Duration(seconds: json['ttl']) : null,
    );
  }
}

/// 캐시 서비스 (Singleton)
class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  // 메모리 캐시
  final Map<String, CacheData> _memoryCache = {};

  // SharedPreferences 인스턴스
  SharedPreferences? _prefs;

  // Hive Box들
  Box? _userBox;
  Box? _dataBox;

  bool _isInitialized = false;

  /// 캐시 서비스 초기화
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // SharedPreferences 초기화
      _prefs = await SharedPreferences.getInstance();

      // Hive 초기화
      await Hive.initFlutter();
      _userBox = await Hive.openBox('user_cache');
      _dataBox = await Hive.openBox('data_cache');

      _isInitialized = true;
      debugPrint('CacheService initialized successfully');
    } catch (e) {
      debugPrint('CacheService initialization failed: $e');
      rethrow;
    }
  }

  /// 초기화 여부 확인
  void _ensureInitialized() {
    if (!_isInitialized) {
      throw Exception('CacheService not initialized. Call init() first.');
    }
  }

  // ==================== 메모리 캐시 ====================

  /// 메모리 캐시에 저장
  void setMemory<T>(String key, T data, {Duration? ttl}) {
    _memoryCache[key] = CacheData(
      data: data,
      cachedAt: DateTime.now(),
      ttl: ttl,
    );
    debugPrint('Memory cache set: $key');
  }

  /// 메모리 캐시에서 가져오기
  T? getMemory<T>(String key) {
    final cached = _memoryCache[key];
    if (cached == null) return null;

    if (cached.isExpired) {
      _memoryCache.remove(key);
      debugPrint('Memory cache expired: $key');
      return null;
    }

    return cached.data as T;
  }

  /// 메모리 캐시 삭제
  void removeMemory(String key) {
    _memoryCache.remove(key);
    debugPrint('Memory cache removed: $key');
  }

  /// 메모리 캐시 전체 삭제
  void clearMemory() {
    _memoryCache.clear();
    debugPrint('Memory cache cleared');
  }

  // ==================== SharedPreferences 캐시 ====================

  /// SharedPreferences에 String 저장
  Future<void> setString(String key, String value) async {
    _ensureInitialized();
    await _prefs!.setString(key, value);
    debugPrint('Preferences set (string): $key');
  }

  /// SharedPreferences에서 String 가져오기
  String? getString(String key) {
    _ensureInitialized();
    return _prefs!.getString(key);
  }

  /// SharedPreferences에 int 저장
  Future<void> setInt(String key, int value) async {
    _ensureInitialized();
    await _prefs!.setInt(key, value);
    debugPrint('Preferences set (int): $key');
  }

  /// SharedPreferences에서 int 가져오기
  int? getInt(String key) {
    _ensureInitialized();
    return _prefs!.getInt(key);
  }

  /// SharedPreferences에 bool 저장
  Future<void> setBool(String key, bool value) async {
    _ensureInitialized();
    await _prefs!.setBool(key, value);
    debugPrint('Preferences set (bool): $key');
  }

  /// SharedPreferences에서 bool 가져오기
  bool? getBool(String key) {
    _ensureInitialized();
    return _prefs!.getBool(key);
  }

  /// SharedPreferences에 double 저장
  Future<void> setDouble(String key, double value) async {
    _ensureInitialized();
    await _prefs!.setDouble(key, value);
    debugPrint('Preferences set (double): $key');
  }

  /// SharedPreferences에서 double 가져오기
  double? getDouble(String key) {
    _ensureInitialized();
    return _prefs!.getDouble(key);
  }

  /// SharedPreferences에 List<String> 저장
  Future<void> setStringList(String key, List<String> value) async {
    _ensureInitialized();
    await _prefs!.setStringList(key, value);
    debugPrint('Preferences set (string list): $key');
  }

  /// SharedPreferences에서 List<String> 가져오기
  List<String>? getStringList(String key) {
    _ensureInitialized();
    return _prefs!.getStringList(key);
  }

  /// SharedPreferences에 JSON 객체 저장
  Future<void> setJson(String key, Map<String, dynamic> value) async {
    _ensureInitialized();
    final jsonString = jsonEncode(value);
    await _prefs!.setString(key, jsonString);
    debugPrint('Preferences set (json): $key');
  }

  /// SharedPreferences에서 JSON 객체 가져오기
  Map<String, dynamic>? getJson(String key) {
    _ensureInitialized();
    final jsonString = _prefs!.getString(key);
    if (jsonString == null) return null;

    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Failed to decode JSON for key $key: $e');
      return null;
    }
  }

  /// SharedPreferences에서 키 삭제
  Future<void> removePreference(String key) async {
    _ensureInitialized();
    await _prefs!.remove(key);
    debugPrint('Preferences removed: $key');
  }

  /// SharedPreferences 전체 삭제
  Future<void> clearPreferences() async {
    _ensureInitialized();
    await _prefs!.clear();
    debugPrint('Preferences cleared');
  }

  // ==================== Hive 캐시 ====================

  /// Hive에 사용자 데이터 저장
  Future<void> setUser(String key, dynamic value) async {
    _ensureInitialized();
    await _userBox!.put(key, value);
    debugPrint('Hive user cache set: $key');
  }

  /// Hive에서 사용자 데이터 가져오기
  T? getUser<T>(String key) {
    _ensureInitialized();
    final value = _userBox!.get(key);
    return value as T?;
  }

  /// Hive 사용자 데이터 삭제
  Future<void> removeUser(String key) async {
    _ensureInitialized();
    await _userBox!.delete(key);
    debugPrint('Hive user cache removed: $key');
  }

  /// Hive에 일반 데이터 저장
  Future<void> setData(String key, dynamic value) async {
    _ensureInitialized();
    await _dataBox!.put(key, value);
    debugPrint('Hive data cache set: $key');
  }

  /// Hive에서 일반 데이터 가져오기
  T? getData<T>(String key) {
    _ensureInitialized();
    final value = _dataBox!.get(key);
    return value as T?;
  }

  /// Hive 일반 데이터 삭제
  Future<void> removeData(String key) async {
    _ensureInitialized();
    await _dataBox!.delete(key);
    debugPrint('Hive data cache removed: $key');
  }

  /// Hive 전체 삭제
  Future<void> clearHive() async {
    _ensureInitialized();
    await _userBox!.clear();
    await _dataBox!.clear();
    debugPrint('Hive cache cleared');
  }

  // ==================== 통합 캐시 메서드 ====================

  /// 통합 캐시 저장 (자동으로 적절한 캐시 타입 선택)
  Future<void> set<T>(
    String key,
    T value, {
    CacheType type = CacheType.memory,
    Duration? ttl,
  }) async {
    switch (type) {
      case CacheType.memory:
        setMemory(key, value, ttl: ttl);
        break;

      case CacheType.preferences:
        if (value is String) {
          await setString(key, value);
        } else if (value is int) {
          await setInt(key, value);
        } else if (value is bool) {
          await setBool(key, value);
        } else if (value is double) {
          await setDouble(key, value);
        } else if (value is List<String>) {
          await setStringList(key, value);
        } else if (value is Map<String, dynamic>) {
          await setJson(key, value);
        } else {
          // 복잡한 객체는 JSON으로 직렬화
          await setJson(key, {'data': value});
        }
        break;

      case CacheType.hive:
        await setData(key, value);
        break;
    }
  }

  /// 통합 캐시 가져오기
  T? get<T>(String key, {CacheType type = CacheType.memory}) {
    switch (type) {
      case CacheType.memory:
        return getMemory<T>(key);

      case CacheType.preferences:
        if (T == String) {
          return getString(key) as T?;
        } else if (T == int) {
          return getInt(key) as T?;
        } else if (T == bool) {
          return getBool(key) as T?;
        } else if (T == double) {
          return getDouble(key) as T?;
        } else {
          final json = getJson(key);
          return json?['data'] as T?;
        }

      case CacheType.hive:
        return getData<T>(key);
    }
  }

  /// 통합 캐시 삭제
  Future<void> remove(String key, {CacheType type = CacheType.memory}) async {
    switch (type) {
      case CacheType.memory:
        removeMemory(key);
        break;
      case CacheType.preferences:
        await removePreference(key);
        break;
      case CacheType.hive:
        await removeData(key);
        break;
    }
  }

  /// 전체 캐시 삭제
  Future<void> clearAll() async {
    clearMemory();
    await clearPreferences();
    await clearHive();
    debugPrint('All cache cleared');
  }

  // ==================== 유틸리티 메서드 ====================

  /// 캐시 크기 확인 (메모리)
  int get memoryCacheSize => _memoryCache.length;

  /// 캐시 크기 확인 (Hive 사용자)
  int get userCacheSize {
    _ensureInitialized();
    return _userBox!.length;
  }

  /// 캐시 크기 확인 (Hive 데이터)
  int get dataCacheSize {
    _ensureInitialized();
    return _dataBox!.length;
  }

  /// 만료된 메모리 캐시 정리
  void cleanExpiredMemoryCache() {
    final expiredKeys = <String>[];
    _memoryCache.forEach((key, value) {
      if (value.isExpired) {
        expiredKeys.add(key);
      }
    });

    for (final key in expiredKeys) {
      _memoryCache.remove(key);
    }

    if (expiredKeys.isNotEmpty) {
      debugPrint('Cleaned ${expiredKeys.length} expired memory cache entries');
    }
  }
}

/// 캐시 키 상수
class CacheKeys {
  // 사용자 관련
  static const String userProfile = 'user_profile';
  static const String userRole = 'user_role';
  static const String userId = 'user_id';

  // 토큰 관련 (주의: 민감 정보는 FlutterSecureStorage 사용)
  static const String lastLoginTime = 'last_login_time';

  // 앱 설정
  static const String isDarkMode = 'is_dark_mode';
  static const String language = 'language';
  static const String notificationsEnabled = 'notifications_enabled';

  // 데이터 캐시
  static const String patientsList = 'patients_list';
  static const String doctorsList = 'doctors_list';
  static const String predictionsList = 'predictions_list';

  // 임시 데이터
  static const String lastSearchQuery = 'last_search_query';
  static const String lastSelectedPatientId = 'last_selected_patient_id';
}
