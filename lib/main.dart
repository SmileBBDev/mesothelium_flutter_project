
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'constants.dart';
import 'core/provider/auth_provider.dart';
import 'features/admin/ApprovalPage.dart';
import 'features/admin/UserListPage.dart';
import 'features/admin/admin_main_page.dart';
import 'features/admin/ml_management_page.dart';
import 'features/auth/sign_in_screen.dart';
import 'features/auth/sign_up_screen.dart';
import 'features/common/pages/my_info.dart';
import 'features/common/welcome_screen.dart';
import 'features/doctor/doctor_main_page.dart';
import 'features/doctor/medical_document_editor.dart';
import 'features/patient/Patient_main_page.dart';
import 'features/staff/staff_main_page.dart';
import 'features/staff/user_approval_list.dart';
import 'features/staff/patient_management_list.dart';
import 'features/staff/bulk_register_page.dart';
import 'features/doctor/ml_prediction_page.dart';
import 'features/patient/ml_prediction_result_page.dart';
import 'features/common/pages/edit_profile_page.dart';




void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'mesothelium_flutter_app',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: primaryColor,
        textTheme: Theme.of(context).textTheme.apply(displayColor: textColor),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: TextButton.styleFrom(
            backgroundColor: primaryColor,
            padding: EdgeInsets.all(defaultPadding),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: textFieldBorder,
          enabledBorder: textFieldBorder,
          focusedBorder: textFieldBorder,
        ),
      ),
      locale: const Locale('ko', 'KR'),
      supportedLocales: const [
        Locale('ko', 'KR'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // home: WelcomeScreen(),
      initialRoute: '/welcome',
      routes: {
        '/welcome': (context) => WelcomeScreen(),
        '/login': (context) => SignInScreen(),
        '/signup': (context) => SignUpScreen(),
        '/patientMain': (context) => PatientMainPage(),
        '/doctorMain': (context) => DoctorMainPage(),
        '/adminMain': (context) => AdminMainPage(),
        '/staffMain': (context) => StaffMainPage(),
        '/myInfo': (context) => MyInfoPage(),
        '/approval': (context) => ApprovalPage(),
        '/allUser': (context) => UserListPage(),
        '/mlManagement': (context) => MLManagementPage(),
        '/userApproval': (context) => UserApprovalList(),
        '/patientManagement': (context) => PatientManagementList(),
        '/bulkRegister': (context) => BulkRegisterPage(),
      },
      onGenerateRoute: (settings) {
        // 동적 라우팅 - 파라미터가 필요한 페이지들

        // 프로필 수정 페이지
        if (settings.name == '/editProfile') {
          final args = settings.arguments as Map<String, dynamic>?;
          return MaterialPageRoute(
            builder: (context) => EditProfilePage(userInfo: args),
          );
        }

        if (settings.name == '/medicalDocumentEditor') {
          final args = settings.arguments as Map<String, dynamic>?;
          if (args != null) {
            return MaterialPageRoute(
              builder: (context) => MedicalDocumentEditor(
                patientId: args['patientId'] as int,
                patientName: args['patientName'] as String,
                patientInfo: args['patientInfo'] as String,
                recordId: args['recordId'] as int?,
              ),
            );
          }
        }

        // ML 예측 페이지 (의사용)
        if (settings.name == '/mlPrediction') {
          final args = settings.arguments as Map<String, dynamic>?;
          return MaterialPageRoute(
            builder: (context) => MlPredictionPage(
              preselectedPatientId: args?['patientId'] as int?,
              preselectedPatientName: args?['patientName'] as String?,
            ),
          );
        }

        // ML 예측 결과 페이지 (환자용)
        if (settings.name == '/mlPredictionResult') {
          final args = settings.arguments as Map<String, dynamic>?;
          if (args != null && args['patientId'] != null) {
            return MaterialPageRoute(
              builder: (context) => MlPredictionResultPage(
                patientId: args['patientId'] as int,
              ),
            );
          }
        }

        // 기본 404 페이지
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(title: const Text('페이지를 찾을 수 없습니다')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('요청하신 페이지를 찾을 수 없습니다: ${settings.name}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pushReplacementNamed('/welcome'),
                    child: const Text('홈으로 돌아가기'),
                  ),
                ],
              ),
            ),
          ),
        );
      },

    );
  }
}
