# 중피종 진단 보조 시스템 - Flutter 프로젝트

## 프로젝트 개요

### 목적
중피종(Mesothelioma) 진단을 위한 ML 기반 의료 정보 시스템의 모바일/웹 클라이언트 애플리케이션

### 주요 기능
- 역할별 차별화된 UI/UX (환자, 의사, 원무과, 관리자)
- ML 기반 중피종 예측 (11개 입력 특징 → XGBoost/RandomForest 모델)
- 진료 기록 관리 (Quill 에디터 기반 리치 텍스트)
- 환자-의사 배정 및 관리
- JWT 기반 인증 및 권한 관리
- 실시간 알림 시스템

---

## 기술 스택

### Frontend Framework
- **Flutter 3.9.2+** - 크로스 플랫폼 UI 프레임워크
- **Dart** - 프로그래밍 언어

### 주요 패키지
```yaml
# 상태 관리
provider: ^6.1.2

# HTTP 통신
dio: ^5.7.0
http: ^1.1.0

# 보안 저장소
flutter_secure_storage: ^9.2.2

# JWT 처리
jwt_decode: ^0.3.1

# UI 컴포넌트
google_nav_bar: ^5.0.5
table_calendar: ^3.1.2
syncfusion_flutter_calendar: ^31.2.5
flutter_svg: ^2.0.7

# 에디터
flutter_quill: ^11.5.0
vsc_quill_delta_to_html: ^1.0.5
flutter_widget_from_html: ^0.15.2

# 캐싱
hive: ^2.2.3
hive_flutter: ^1.1.0
shared_preferences: ^2.2.2

# 알림
flutter_local_notifications: ^18.0.1
```

---

## 프로젝트 구조

```
lib/
├── main.dart                          # 앱 진입점
├── constants.dart                     # 전역 상수
│
├── config/
│   └── base_config.dart              # 기본 설정 (API URL, Dio 설정)
│
├── core/                             # 핵심 기능
│   ├── provider/
│   │   └── auth_provider.dart        # 인증 상태 관리 (Provider)
│   │
│   ├── service/                      # 비즈니스 로직
│   │   ├── api_client.dart           # HTTP 클라이언트 (Dio 래퍼, 재시도 로직)
│   │   ├── api_config.dart           # API 엔드포인트 설정
│   │   ├── auth_service.dart         # 인증 서비스 (로그인, 회원가입)
│   │   ├── error_handler.dart        # 에러 처리 (9가지 에러 타입)
│   │   ├── cache_service.dart        # 3-tier 캐싱 (Memory/SharedPrefs/Hive)
│   │   ├── ml_service.dart           # ML 예측 서비스
│   │   ├── prediction_service.dart   # 예측 결과 저장/조회
│   │   ├── patient_service.dart      # 환자 관리
│   │   ├── doctor_service.dart       # 의사 관리
│   │   ├── medical_record_service.dart # 진료 기록 관리
│   │   └── notification_service.dart # 알림 서비스
│   │
│   ├── middleware/
│   │   └── permission_guard.dart     # 권한 관리 (RBAC)
│   │
│   └── widgets/
│       └── loading_indicator.dart    # 로딩 UI 컴포넌트
│
├── features/                         # 기능별 모듈
│   ├── auth/                        # 인증
│   │   ├── sign_in_screen.dart
│   │   ├── sign_up_screen.dart
│   │   └── components/
│   │
│   ├── common/                      # 공통
│   │   └── welcome_screen.dart
│   │
│   ├── home/                        # 홈 화면
│   │   └── HomePage.dart            # 역할별 대시보드
│   │
│   ├── patient/                     # 환자 기능
│   │   ├── ml_prediction_result_page.dart
│   │   └── page/
│   │
│   ├── doctor/                      # 의사 기능
│   │   ├── ml_prediction_page.dart          # ML 예측 실행
│   │   ├── ai_prediction_summary.dart       # 예측 결과 요약
│   │   ├── medical_document_editor.dart     # 진료 기록 작성
│   │   └── patient_list.dart                # 담당 환자 목록
│   │
│   ├── staff/                       # 원무과 기능
│   │   └── patient_management_list.dart     # 환자 관리, 의사 배정
│   │
│   └── admin/                       # 관리자 기능
│       ├── ml_management_page.dart          # ML 모델 관리
│       └── user_approval_page.dart          # 사용자 승인
│
└── routes.dart                      # 라우팅 설정
```

---

## 아키텍처

### 1. 인증 시스템
```
Flutter App
    ↓
AuthProvider (Provider 패턴)
    ↓
AuthService
    ↓
BaseConfig (Dio + Interceptor)
    ↓
Django REST API (JWT)
```

**주요 특징:**
- JWT Access/Refresh 토큰 기반
- 자동 토큰 갱신 (Interceptor)
- FlutterSecureStorage로 안전한 토큰 저장
- 401 에러 시 자동 refresh 시도

### 2. API 통신 구조
```
Service Layer
    ↓
ApiClient (재시도 로직, 에러 핸들링)
    ↓
Dio (HTTP Client)
    ↓
Django REST API (http://34.61.113.204)
    ↓
Flask ML Service (내부 프록시)
```

**에러 처리:**
- 9가지 에러 타입 분류 (network, timeout, unauthorized 등)
- 자동 재시도 (최대 2회, 1초 간격)
- 사용자 친화적 한글 에러 메시지

### 3. ML 예측 플로우
```
ML Prediction Page (Doctor)
    ↓
MlService.predict()
    ↓
Django API /api/ml/predict/
    ↓
Flask ML Server (내부)
    ↓
XGBoost/RandomForest Model
    ↓
Django Auto-save (PredictionResult)
    ↓
Flutter UI 결과 표시
```

**입력 데이터 (11개 필드):**
1. age (나이)
2. duration_of_symptoms (증상 지속 기간, 일)
3. platelet_count (혈소판 수, 10^9/L)
4. cell_count (세포 수)
5. blood_LDH (혈중 LDH, U/L)
6. pleural_LDH (흉막 LDH, U/L)
7. pleural_protein (흉막 단백질, g/dL)
8. total_protein (총 단백질, g/dL)
9. albumin (알부민, g/dL)
10. CRP (C-반응성 단백질, mg/L)
11. duration_of_asbestos_exposure (석면 노출 기간, 년)

**출력:**
- output_label: 0 (음성) / 1 (양성)
- output_proba: 예측 확률 (0.0 ~ 1.0)

### 4. 권한 관리 (RBAC)
```
UserRole Enum
├─ patient   (환자)
├─ doctor    (의사)
├─ staff     (원무과)
├─ admin     (관리자)
└─ general   (미승인 사용자)

PermissionGuard (Singleton)
├─ getCurrentRole()
├─ hasRole()
├─ isAdmin/isDoctor/isPatient/isStaff()
└─ isApproved()

PermissionWidget (조건부 렌더링)
PermissionRoute (라우트 가드)
PermissionCheckMixin (상태 관리)
```

**접근 제어:**
- 환자: 본인 예측 결과 조회
- 의사: ML 예측 실행, 진료 기록 작성
- 원무과: 환자 관리, 의사 배정
- 관리자: 사용자 승인, ML 모델 관리

### 5. 캐싱 전략 (3-Tier)
```
1. Memory Cache
   ├─ TTL 지원
   ├─ 빠른 접근
   └─ 앱 재시작 시 초기화

2. SharedPreferences
   ├─ 간단한 Key-Value
   ├─ 설정, 토큰
   └─ 앱 재시작 후에도 유지

3. Hive (NoSQL)
   ├─ 복잡한 객체
   ├─ 사용자 데이터
   └─ 오프라인 지원
```

### 6. 알림 시스템
```
NotificationService (Singleton)
├─ Local Notifications
│   ├─ showLocalNotification()
│   ├─ scheduleNotification()
│   └─ NotificationBadge (UI)
│
└─ FCM (준비됨, 주석 처리)
    ├─ getFCMToken()
    ├─ onTokenRefresh()
    └─ Background/Foreground 핸들러
```

**알림 타입:**
- mlPrediction: ML 예측 완료
- appointmentReminder: 진료 예약 알림
- messageReceived: 메시지 수신
- systemNotice: 시스템 공지

---

## 주요 기능 상세

### 1. 로그인 / 회원가입
**파일:** `features/auth/sign_in_screen.dart`, `sign_up_screen.dart`

**플로우:**
```
1. 사용자 입력 (username, password)
2. AuthProvider.login()
3. BaseConfig.dio.post('/api/auth/token/')
4. JWT 토큰 저장 (FlutterSecureStorage)
5. 역할별 홈 화면 이동
```

**역할별 홈 라우트:**
- patient → `/patient/home`
- doctor → `/doctor/home`
- staff → `/staff/home`
- admin → `/admin/home`
- general → `/general/waiting` (승인 대기)

### 2. ML 예측 (의사 전용)
**파일:** `features/doctor/ml_prediction_page.dart`

**기능:**
1. 환자 선택 (드롭다운)
2. 11개 검사 수치 입력
3. 예측 실행 버튼
4. 결과 표시 (양성/음성, 확률)
5. Django에 자동 저장 (patient_id 제공 시)

**검증:**
- 모든 필드 필수 입력
- 숫자 범위 검증
- 환자 선택 확인

### 3. 진료 기록 관리
**파일:** `features/doctor/medical_document_editor.dart`

**에디터:**
- 텍스트 기반 간단한 에디터
- 제목 + 내용 (HTML 저장)
- Quill Delta JSON 지원 (향후 확장)

**API:**
- POST `/api/patients/records/` - 생성
- GET `/api/patients/records/<id>/` - 조회
- PUT `/api/patients/records/<id>/` - 수정

### 4. 환자-의사 배정 (원무과)
**파일:** `features/staff/patient_management_list.dart`

**기능:**
1. 환자 목록 조회 (페이지네이션)
2. 검색 (이름, ID)
3. 담당 의사 변경
   - 현재 담당의 제거
   - 새 담당의 추가
   - 다중 담당의 지원

**페이지네이션:**
- 페이지당 10명
- 페이지 버튼 (최대 5개 표시)
- 이전/다음 버튼

### 5. ML 모델 관리 (관리자)
**파일:** `features/admin/ml_management_page.dart`

**기능:**
1. 모델 스키마 조회
   - 11개 필수 특징 목록
   - 특징별 데이터 타입
2. 모델 재로드
   - Flask ML 서버 모델 재로딩
3. 테스트 예측
   - patientId: 0 (저장하지 않음)

### 6. 사용자 승인 (관리자)
**파일:** `features/admin/user_approval_page.dart`

**플로우:**
```
1. 회원가입 시 role: 'general' (미승인)
2. 관리자가 승인 페이지에서 역할 변경
3. PUT /api/auth/change-role/<user_id>/
4. 사용자 재로그인 시 새 역할 적용
```

---

## 상태 관리

### Provider 패턴
**파일:** `core/provider/auth_provider.dart`

```dart
class AuthProvider extends ChangeNotifier {
  AuthUser? _user;

  Future<void> login(String username, String password);
  Future<void> logout();
  Future<void> refreshUserInfo();
}

// main.dart에서 사용
ChangeNotifierProvider(
  create: (_) => AuthProvider(),
  child: MyApp(),
)
```

### 사용 예시
```dart
// 1. 상태 읽기
final user = context.watch<AuthProvider>().user;

// 2. 메서드 호출
context.read<AuthProvider>().login(username, password);

// 3. 조건부 렌더링
if (user?.role == 'doctor') {
  // 의사 전용 UI
}
```

---

## API 통신

### 1. ApiClient (공통 HTTP 클라이언트)
**파일:** `core/service/api_client.dart`

**특징:**
- Dio 기반
- 자동 재시도 (network/timeout/server 에러)
- 에러 타입 분류
- 통일된 응답 형식 (ApiResponse)

```dart
final client = ApiClient();

// GET
final response = await client.get('/api/patients/');

// POST
final response = await client.post(
  '/api/ml/predict/',
  body: {'patient_id': 1, 'data': [...]},
);

// ApiResponse 구조
if (response.success) {
  final data = response.data;
} else {
  print(response.errorMessage); // 사용자 친화적 한글 메시지
}
```

### 2. Service Layer
각 도메인별 서비스 클래스 제공:

```dart
// ML 서비스
final mlService = MlService();
final result = await mlService.predict(
  patientId: 1,
  data: [inputData],
);

// 환자 서비스
final patientService = PatientService();
final result = await patientService.getPatientsByDoctor(doctorId);

// 진료 기록 서비스
final recordService = MedicalRecordService();
final result = await recordService.createMedicalRecord(
  patientId: 1,
  title: '진료 기록',
  contentHtml: '<p>내용</p>',
);
```

**Result 패턴:**
```dart
class MlPredictResult {
  final bool success;
  final String? message;
  final Map<String, dynamic>? result;
  final AppErrorType? errorType;
}

// 사용
if (result.success) {
  // 성공 처리
} else {
  // 에러 메시지 표시
  showSnackBar(result.message ?? '알 수 없는 오류');
}
```

---

## 에러 처리

### ErrorHandler
**파일:** `core/service/error_handler.dart`

**에러 타입 (9가지):**
```dart
enum AppErrorType {
  network,           // 네트워크 연결 실패
  timeout,           // 요청 시간 초과
  unauthorized,      // 인증 실패 (401)
  forbidden,         // 권한 없음 (403)
  notFound,          // 리소스 없음 (404)
  serverError,       // 서버 오류 (500)
  tokenExpired,      // 토큰 만료
  invalidResponse,   // 잘못된 응답 형식
  unknown,           // 알 수 없는 오류
}
```

**사용자 메시지:**
```dart
final appError = ErrorHandler.handleDioError(dioException);
print(appError.userMessage);
// → "네트워크 연결을 확인해주세요"
// → "요청 시간이 초과되었습니다"
// → "로그인이 필요합니다"
```

**재시도 가능 여부:**
```dart
if (ErrorHandler.isRetryable(appError)) {
  // network, timeout, serverError만 재시도
}
```

---

## UI/UX 컴포넌트

### Loading Indicators
**파일:** `core/widgets/loading_indicator.dart`

**10가지 로딩 위젯:**
```dart
// 1. 기본 로딩
LoadingIndicator(message: '로딩 중...')

// 2. 작은 로딩 (버튼용)
SmallLoadingIndicator()

// 3. 전체 화면 오버레이
LoadingOverlay(
  isLoading: _isLoading,
  message: '데이터 처리 중...',
  child: YourWidget(),
)

// 4. 로딩 버튼
LoadingButton(
  text: '예측 실행',
  onPressed: _predict,
  isLoading: _isLoading,
)

// 5. Shimmer 효과
ShimmerLoading(
  child: ListItemSkeleton(),
)

// 6. 다이얼로그
LoadingDialog.show(context, message: '저장 중...');
LoadingDialog.hide(context);
```

### Permission Widgets
**파일:** `core/middleware/permission_guard.dart`

```dart
// 1. 조건부 렌더링
PermissionWidget(
  allowedRoles: [UserRole.doctor, UserRole.admin],
  child: MLPredictionButton(),
  fallback: Text('권한이 없습니다'),
)

// 2. 라우트 가드
PermissionRoute(
  allowedRoles: [UserRole.doctor],
  page: MlPredictionPage(),
  unauthorizedRoute: '/unauthorized',
)

// 3. Mixin (StatefulWidget)
class MyPage extends StatefulWidget {}

class _MyPageState extends State<MyPage>
    with PermissionCheckMixin {
  @override
  Widget build(BuildContext context) {
    if (isDoctor) {
      return DoctorUI();
    }
    return PatientUI();
  }
}
```

---

## 설정 및 환경 변수

### API URL 설정
**파일:** `lib/config/base_config.dart`, `lib/core/service/api_config.dart`

```dart
// GCP 배포 서버 (현재)
static String baseUrl = 'http://34.61.113.204';

// 로컬 개발 서버 (개발 시)
// static String baseUrl = 'http://localhost:8000';
```

**두 파일 모두 동일한 URL을 사용해야 함!**

### 타임아웃 설정
```dart
// BaseConfig
connectTimeout: Duration(seconds: 10)
receiveTimeout: Duration(seconds: 15)

// ApiConfig
static const Duration timeout = Duration(seconds: 15);
```

---

## 빌드 및 실행

### 개발 환경
```bash
# 패키지 설치
flutter pub get

# Chrome 실행
flutter run -d chrome

# Android 실행
flutter run -d <device-id>

# Hot Reload
r

# Hot Restart (설정 변경 시 필수)
R
```

### 빌드
```bash
# Android APK
flutter build apk --release

# Web
flutter build web --release

# iOS (macOS 필요)
flutter build ios --release
```

### 환경별 빌드
```bash
# 개발 환경 (로컬 서버)
# base_config.dart에서 localhost로 변경 후
flutter run

# 프로덕션 환경 (GCP 서버)
# base_config.dart에서 GCP URL로 변경 후
flutter build apk --release
```

---

## 트러블슈팅

### 1. 로그인 타임아웃 에러
**원인:** `base_config.dart`와 `api_config.dart`의 baseUrl이 다름

**해결:**
```dart
// 두 파일 모두 동일한 URL 사용
static String baseUrl = 'http://34.61.113.204';
```

### 2. RenderFlex Overflow
**원인:** Column이 화면 높이를 초과

**해결:**
```dart
// LayoutBuilder + SingleChildScrollView + IntrinsicHeight
SafeArea(
  child: LayoutBuilder(
    builder: (context, constraints) {
      return SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: constraints.maxHeight,
          ),
          child: IntrinsicHeight(
            child: Column(
              children: [Spacer(), ...],
            ),
          ),
        ),
      );
    },
  ),
)
```

### 3. CORS 에러 (Web)
**증상:** Postman은 되는데 Flutter Web은 안됨

**원인:** 브라우저 CORS 정책

**해결 (Django):**
```python
# settings.py
CORS_ALLOWED_ORIGINS = [
    "http://localhost:59257",  # Flutter Web 포트
]
```

### 4. Hot Reload가 안먹힘
**원인:** `static` 변수 변경

**해결:** Hot Restart (R 키) 사용

### 5. 토큰 만료 에러
**원인:** Refresh 토큰 만료

**해결:**
```dart
// 자동 처리됨 (BaseConfig Interceptor)
// 만약 안되면 재로그인 필요
```

---

## 보안 고려사항

### 1. 토큰 저장
```dart
// ✅ 안전: FlutterSecureStorage 사용
final storage = FlutterSecureStorage();
await storage.write(key: 'access', value: token);

// ❌ 위험: SharedPreferences 사용 금지
// 토큰을 SharedPreferences에 저장하지 마세요!
```

### 2. HTTPS 사용
```dart
// 프로덕션에서는 반드시 HTTPS 사용
static const String baseUrl = 'https://your-domain.com';
```

### 3. API 키 노출 방지
```dart
// ❌ 코드에 하드코딩 금지
// const apiKey = 'sk-1234567890';

// ✅ 환경 변수 또는 백엔드에서 관리
```

### 4. 입력 검증
```dart
// 사용자 입력 검증
if (ageController.text.isEmpty) {
  return '나이를 입력해주세요';
}

final age = int.tryParse(ageController.text);
if (age == null || age < 0 || age > 120) {
  return '올바른 나이를 입력해주세요';
}
```

---

## 성능 최적화

### 1. 이미지 캐싱
```dart
// cached_network_image 패키지 사용 권장
CachedNetworkImage(
  imageUrl: 'https://...',
  placeholder: (context, url) => CircularProgressIndicator(),
)
```

### 2. 리스트 최적화
```dart
// ListView.builder 사용 (lazy loading)
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    return ListTile(title: Text(items[index]));
  },
)
```

### 3. 페이지네이션
```dart
// 현재 구현됨 (patient_management_list.dart)
final _itemsPerPage = 10;
```

### 4. 캐싱 활용
```dart
// CacheService 사용
final cached = await CacheService().get<List>('patients');
if (cached != null) {
  return cached;
}

final data = await api.getPatients();
await CacheService().set('patients', data, ttl: Duration(minutes: 5));
```

---

## 테스트

### Unit Test
```bash
# 전체 테스트 실행
flutter test

# 특정 파일 테스트
flutter test test/services/api_client_test.dart
```

### Widget Test
```dart
// test/widgets/loading_indicator_test.dart
testWidgets('LoadingIndicator shows message', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: LoadingIndicator(message: 'Loading...'),
    ),
  );

  expect(find.text('Loading...'), findsOneWidget);
});
```

---

## 배포

### Android
```bash
# 1. 빌드
flutter build apk --release

# 2. APK 위치
# build/app/outputs/flutter-apk/app-release.apk

# 3. Play Store 업로드용 (AAB)
flutter build appbundle --release
```

### iOS
```bash
# 1. 빌드 (macOS + Xcode 필요)
flutter build ios --release

# 2. Xcode에서 Archive 및 업로드
```

### Web
```bash
# 1. 빌드
flutter build web --release

# 2. 배포
# build/web/ 폴더를 웹 서버에 업로드
# Nginx, Apache, Firebase Hosting 등
```

---

## 향후 개선 사항

### 1. FCM 푸시 알림
```yaml
# pubspec.yaml 주석 해제
firebase_core: ^3.8.1
firebase_messaging: ^15.1.5
timezone: ^0.9.4
```

```dart
// notification_service.dart 주석 해제
// FCM 초기화 및 핸들러 구현
```

### 2. 오프라인 지원
- Hive 캐싱 확대
- Sync 큐 구현
- 오프라인 모드 UI

### 3. 다국어 지원
```yaml
# pubspec.yaml
flutter_localizations:
  sdk: flutter
intl: ^0.18.0
```

### 4. 테마 시스템
- Light/Dark 모드
- 커스텀 색상 팔레트
- 폰트 크기 조절

### 5. 접근성
- Screen Reader 지원
- 키보드 네비게이션
- 고대비 모드

---

## 팀 및 기여

### 개발 가이드라인
1. 코드 스타일: Dart 공식 스타일 가이드 준수
2. Commit: Conventional Commits 사용
3. Branch: feature/기능명, bugfix/버그명
4. PR: 리뷰 필수

### 파일 작성 규칙
```dart
// 1. 임포트 순서
import 'dart:...';          // Dart SDK
import 'package:flutter/...'; // Flutter
import 'package:...';        // 외부 패키지
import '../...';            // 프로젝트 내부

// 2. 네이밍
// 클래스: PascalCase
// 파일명: snake_case
// 변수/함수: camelCase
// 상수: UPPER_SNAKE_CASE
```

---

## 라이선스

이 프로젝트는 의료 목적으로만 사용되며, 상업적 이용을 금지합니다.

---

## 연락처

프로젝트 관련 문의: [담당자 이메일]

---

## 변경 이력

### v1.0.0 (2025-11-15)
- ✅ Phase 1: ML 예측 11개 입력 필드 구현
- ✅ Phase 2: Pagination 구현
- ✅ Phase 3: Django-Flask 연동 문서화
- ✅ Phase 4: 에러 처리 강화 (ErrorHandler)
- ✅ Phase 5: 3-tier 캐싱 시스템
- ✅ Phase 6: Loading UI 컴포넌트 (10종)
- ✅ Phase 7: 권한 관리 시스템 (RBAC)
- ✅ Phase 8: 알림 서비스 (Local + FCM 준비)
- ✅ Bug Fix: welcome_screen.dart overflow 수정
- ✅ Bug Fix: API URL 통일 (base_config.dart)

---

**마지막 업데이트:** 2025년 11월 15일
