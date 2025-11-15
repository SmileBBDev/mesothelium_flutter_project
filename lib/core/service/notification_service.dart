import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:convert';
import 'error_handler.dart';

/// 알림 타입
enum NotificationType {
  mlPrediction,      // ML 예측 완료
  appointmentReminder, // 진료 예약 알림
  messageReceived,   // 메시지 수신
  systemNotice,      // 시스템 공지
}

/// 알림 우선순위
enum NotificationPriority {
  low,
  normal,
  high,
}

/// 알림 데이터 모델
class NotificationData {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final Map<String, dynamic>? payload;
  final DateTime createdAt;
  final bool isRead;

  NotificationData({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.payload,
    DateTime? createdAt,
    this.isRead = false,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type.toString().split('.').last,
      'payload': payload,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
    };
  }

  factory NotificationData.fromJson(Map<String, dynamic> json) {
    return NotificationData(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      type: NotificationType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => NotificationType.systemNotice,
      ),
      payload: json['payload'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isRead: json['isRead'] as bool? ?? false,
    );
  }
}

/// 알림 서비스 (Singleton)
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // FirebaseMessaging? _firebaseMessaging;

  bool _isInitialized = false;
  final List<NotificationData> _notifications = [];
  final List<Function(NotificationData)> _listeners = [];

  /// 알림 서비스 초기화
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // 로컬 알림 초기화
      await _initializeLocalNotifications();

      // FCM 초기화 (주석 처리 - firebase_messaging 패키지 설치 시 활성화)
      // await _initializeFirebaseMessaging();

      _isInitialized = true;
      debugPrint('NotificationService initialized successfully');
    } catch (e) {
      debugPrint('NotificationService initialization failed: $e');
      final appError = ErrorHandler.handleException(e);
      ErrorHandler.logError(appError);
    }
  }

  /// 로컬 알림 초기화
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Android 알림 채널 생성
    const androidChannel = AndroidNotificationChannel(
      'default_channel',
      '기본 알림',
      description: '일반 알림을 위한 채널',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  /// Firebase Cloud Messaging 초기화 (FCM)
  /// 주석 처리 - firebase_messaging 패키지 설치 시 활성화
  /*
  Future<void> _initializeFirebaseMessaging() async {
    _firebaseMessaging = FirebaseMessaging.instance;

    // 권한 요청
    final settings = await _firebaseMessaging!.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('FCM permission granted');

      // FCM 토큰 가져오기
      final token = await _firebaseMessaging!.getToken();
      debugPrint('FCM Token: $token');

      // 포그라운드 메시지 수신
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // 백그라운드 메시지 수신 (앱이 백그라운드에 있을 때)
      FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

      // 앱이 종료된 상태에서 알림 탭으로 실행된 경우
      final initialMessage = await _firebaseMessaging!.getInitialMessage();
      if (initialMessage != null) {
        _handleBackgroundMessage(initialMessage);
      }
    } else {
      debugPrint('FCM permission denied');
    }
  }

  /// 포그라운드 메시지 처리
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Foreground message received: ${message.notification?.title}');

    final notification = NotificationData(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: message.notification?.title ?? '알림',
      body: message.notification?.body ?? '',
      type: _parseNotificationType(message.data['type']),
      payload: message.data,
    );

    // 로컬 알림 표시
    showLocalNotification(notification);

    // 알림 저장 및 리스너 호출
    _addNotification(notification);
  }

  /// 백그라운드 메시지 처리
  void _handleBackgroundMessage(RemoteMessage message) {
    debugPrint('Background message received: ${message.notification?.title}');

    final notification = NotificationData(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: message.notification?.title ?? '알림',
      body: message.notification?.body ?? '',
      type: _parseNotificationType(message.data['type']),
      payload: message.data,
    );

    _addNotification(notification);
    // 알림 탭 시 페이지 이동 등의 처리
  }

  /// FCM 토큰 가져오기
  Future<String?> getFCMToken() async {
    try {
      return await _firebaseMessaging?.getToken();
    } catch (e) {
      debugPrint('Failed to get FCM token: $e');
      return null;
    }
  }

  /// FCM 토큰 갱신 리스너
  void onTokenRefresh(Function(String) callback) {
    _firebaseMessaging?.onTokenRefresh.listen(callback);
  }
  */

  /// 로컬 알림 표시
  Future<void> showLocalNotification(
    NotificationData notification, {
    NotificationPriority priority = NotificationPriority.normal,
  }) async {
    try {
      final id = int.tryParse(notification.id) ??
          DateTime.now().millisecondsSinceEpoch % 100000;

      final androidDetails = AndroidNotificationDetails(
        'default_channel',
        '기본 알림',
        channelDescription: '일반 알림을 위한 채널',
        importance: _mapPriorityToImportance(priority),
        priority: _mapPriorityToPriority(priority),
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        id,
        notification.title,
        notification.body,
        details,
        payload: jsonEncode(notification.toJson()),
      );

      _addNotification(notification);
    } catch (e) {
      debugPrint('Failed to show local notification: $e');
      final appError = ErrorHandler.handleException(e);
      ErrorHandler.logError(appError);
    }
  }

  /// 알림 탭 이벤트 처리
  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!) as Map<String, dynamic>;
        final notification = NotificationData.fromJson(data);
        debugPrint('Notification tapped: ${notification.title}');

        // 알림을 읽음 상태로 변경
        markAsRead(notification.id);

        // 리스너 호출
        for (final listener in _listeners) {
          listener(notification);
        }
      } catch (e) {
        debugPrint('Failed to parse notification payload: $e');
      }
    }
  }

  /// 예약 알림 (특정 시간에 알림)
  Future<void> scheduleNotification({
    required NotificationData notification,
    required DateTime scheduledTime,
  }) async {
    try {
      final id = int.tryParse(notification.id) ??
          DateTime.now().millisecondsSinceEpoch % 100000;

      const androidDetails = AndroidNotificationDetails(
        'default_channel',
        '기본 알림',
        channelDescription: '일반 알림을 위한 채널',
        importance: Importance.high,
        priority: Priority.high,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // flutter_local_notifications v17+ 사용 시
      // await _localNotifications.zonedSchedule(
      //   id,
      //   notification.title,
      //   notification.body,
      //   tz.TZDateTime.from(scheduledTime, tz.local),
      //   details,
      //   androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      //   uiLocalNotificationDateInterpretation:
      //       UILocalNotificationDateInterpretation.absoluteTime,
      //   payload: jsonEncode(notification.toJson()),
      // );

      debugPrint('Notification scheduled for: $scheduledTime');
    } catch (e) {
      debugPrint('Failed to schedule notification: $e');
      final appError = ErrorHandler.handleException(e);
      ErrorHandler.logError(appError);
    }
  }

  /// 알림 취소
  Future<void> cancelNotification(String id) async {
    try {
      final notificationId = int.tryParse(id);
      if (notificationId != null) {
        await _localNotifications.cancel(notificationId);
      }
    } catch (e) {
      debugPrint('Failed to cancel notification: $e');
    }
  }

  /// 모든 알림 취소
  Future<void> cancelAllNotifications() async {
    try {
      await _localNotifications.cancelAll();
    } catch (e) {
      debugPrint('Failed to cancel all notifications: $e');
    }
  }

  /// 알림 리스너 추가
  void addListener(Function(NotificationData) listener) {
    _listeners.add(listener);
  }

  /// 알림 리스너 제거
  void removeListener(Function(NotificationData) listener) {
    _listeners.remove(listener);
  }

  /// 알림 저장 및 리스너 호출
  void _addNotification(NotificationData notification) {
    _notifications.insert(0, notification);

    // 최대 100개까지만 보관
    if (_notifications.length > 100) {
      _notifications.removeLast();
    }

    for (final listener in _listeners) {
      listener(notification);
    }
  }

  /// 모든 알림 가져오기
  List<NotificationData> getAllNotifications() {
    return List.unmodifiable(_notifications);
  }

  /// 읽지 않은 알림 가져오기
  List<NotificationData> getUnreadNotifications() {
    return _notifications.where((n) => !n.isRead).toList();
  }

  /// 읽지 않은 알림 개수
  int getUnreadCount() {
    return _notifications.where((n) => !n.isRead).length;
  }

  /// 알림을 읽음 상태로 변경
  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = NotificationData(
        id: _notifications[index].id,
        title: _notifications[index].title,
        body: _notifications[index].body,
        type: _notifications[index].type,
        payload: _notifications[index].payload,
        createdAt: _notifications[index].createdAt,
        isRead: true,
      );
    }
  }

  /// 모든 알림을 읽음 상태로 변경
  void markAllAsRead() {
    for (int i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        _notifications[i] = NotificationData(
          id: _notifications[i].id,
          title: _notifications[i].title,
          body: _notifications[i].body,
          type: _notifications[i].type,
          payload: _notifications[i].payload,
          createdAt: _notifications[i].createdAt,
          isRead: true,
        );
      }
    }
  }

  /// 알림 삭제
  void deleteNotification(String id) {
    _notifications.removeWhere((n) => n.id == id);
  }

  /// 모든 알림 삭제
  void clearAllNotifications() {
    _notifications.clear();
  }

  /// 알림 타입 파싱
  NotificationType _parseNotificationType(dynamic type) {
    if (type == null) return NotificationType.systemNotice;
    if (type is String) {
      return NotificationType.values.firstWhere(
        (e) => e.toString().split('.').last == type,
        orElse: () => NotificationType.systemNotice,
      );
    }
    return NotificationType.systemNotice;
  }

  /// 우선순위를 Importance로 매핑
  Importance _mapPriorityToImportance(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return Importance.low;
      case NotificationPriority.normal:
        return Importance.defaultImportance;
      case NotificationPriority.high:
        return Importance.high;
    }
  }

  /// 우선순위를 Priority로 매핑
  Priority _mapPriorityToPriority(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return Priority.low;
      case NotificationPriority.normal:
        return Priority.defaultPriority;
      case NotificationPriority.high:
        return Priority.high;
    }
  }
}

/// 알림 UI 위젯
class NotificationBadge extends StatelessWidget {
  final int count;
  final Widget child;

  const NotificationBadge({
    super.key,
    required this.count,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        if (count > 0)
          Positioned(
            right: -8,
            top: -8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              constraints: const BoxConstraints(
                minWidth: 20,
                minHeight: 20,
              ),
              child: Center(
                child: Text(
                  count > 99 ? '99+' : count.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
