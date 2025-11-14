import 'dart:io';

// API 설정 및 상수
class ApiConfig {
  // 플랫폼별 자동 URL 선택
  // Android 에뮬레이터에서는 10.0.2.2 사용 (호스트 머신)
  // Windows 데스크톱에서는 localhost 사용
  // static const String baseUrl = 'http://127.0.0.1:8000';
  // 실제 디바이스나 다른 머신에서 접속 시: 'http://192.168.41.126:8000'
  static const String baseUrl = 'http://192.168.41.126:8000';


  // Flutter는 Django API만 호출합니다
  // Django가 내부적으로 Flask ML 서버(포트 9000)를 호출하므로
  // Flutter에서는 Flask 서버 주소를 직접 사용하지 않습니다

  // API 엔드포인트
  static const String loginEndpoint = '/api/auth/token/';
  static const String registerEndpoint = '/api/auth/register/';
  static const String doctorRegisterEndpoint = '/api/auth/register-doctor/';
  static const String refreshTokenEndpoint = '/api/auth/token/refresh/';
  static const String meEndpoint = '/api/auth/me/';
  static const String updateProfileEndpoint = '/api/auth/update-profile/';
  static const String usersEndpoint = '/api/auth/users/';
  static const String changeRoleEndpoint = '/api/auth/change-role/';
  static const String bulkRegisterEndpoint = '/api/auth/register-bulk/';
  static const String bulkApproveEndpoint = '/api/auth/bulk-approve/';

  static const String doctorsEndpoint = '/api/doctors/';
  static const String patientsEndpoint = '/api/patients/';
  static const String assignDoctorsEndpoint = '/api/patients/assign-doctors/';
  static const String bulkAssignDoctorEndpoint =
      '/api/patients/bulk-assign-doctor/';
  static const String patientsAllEndpoint = '/api/patients/all/';
  static const String patientsByDoctorEndpoint = '/api/patients/by-doctor/';
  static const String patientsMineEndpoint = '/api/patients/mine/';

  // 진료 기록 엔드포인트
  static const String medicalRecordsEndpoint = '/api/patients/records/';

  // ML 엔드포인트 (Django 프록시를 통해 Flask ML 서버 호출)
  static const String mlSchemaEndpoint = '/api/ml/schema/';
  static const String mlPredictEndpoint = '/api/ml/predict/';
  static const String mlReloadEndpoint = '/api/ml/reload/';

  // 타임아웃 설정
  static const Duration timeout = Duration(seconds: 15);

  // 전체 URL 생성
  static String getUrl(String endpoint) => '$baseUrl$endpoint';
}
