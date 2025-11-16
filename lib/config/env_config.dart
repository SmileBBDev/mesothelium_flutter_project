/// 환경 변수 설정
/// 보안을 위해 민감한 정보는 이 파일에서 관리합니다.
/// 프로덕션 환경에서는 환경 변수나 보안 저장소에서 로드하도록 수정하세요.
class EnvConfig {
  // 환경 설정
  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'production',
  );

  // API 설정
  // 개발 환경에서는 flutter run --dart-define=API_BASE_URL=http://localhost:8000
  // 프로덕션에서는 flutter build apk --dart-define=API_BASE_URL=https://api.example.com
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://34.61.113.204',  // 개발용 기본값 (프로덕션 키는 제외)
  );

  // vWorld API 키 (지도 서비스)
  // 🔒 보안: 빌드 시 반드시 환경 변수로 제공해야 합니다!
  // flutter run --dart-define=VWORLD_API_KEY=실제키값
  // CI/CD에서는 Secret으로 관리하세요
  static const String vWorldApiKey = String.fromEnvironment(
    'VWORLD_API_KEY',
    defaultValue: '',  // 🔴 기본값 제거 - 빌드 시 필수로 제공해야 함
  );

  // vWorld API 키 검증
  static bool get isVWorldKeyConfigured => vWorldApiKey.isNotEmpty;

  // vWorld URL 템플릿
  static String get vWorldUrl =>
      'https://api.vworld.kr/req/wmts/1.0.0/$vWorldApiKey/Base/{z}/{y}/{x}.png';

  // 개발 모드 여부
  static bool get isDevelopment => environment == 'development';
  static bool get isProduction => environment == 'production';

  // 로깅 활성화 여부
  static bool get enableLogging => !isProduction;
}
