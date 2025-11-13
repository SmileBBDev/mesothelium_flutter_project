
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'constants.dart';
import 'core/provider/auth_provider.dart';
import 'features/admin/ApprovalPage.dart';
import 'features/admin/UserListPage.dart';
import 'features/admin/admin_main_page.dart';
import 'features/auth/sign_in_screen.dart';
import 'features/auth/sign_up_screen.dart';
import 'features/common/pages/my_info.dart';
import 'features/common/welcome_screen.dart';
import 'features/doctor/doctor_main_page.dart';
import 'features/patient/Patient_main_page.dart';




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
        '/myInfo': (context) => MyInfoPage(),
        '/approval' : (context) => ApprovalPage(),
        '/allUser' : (context) => UserListPage(),
      },

    );
  }
}
