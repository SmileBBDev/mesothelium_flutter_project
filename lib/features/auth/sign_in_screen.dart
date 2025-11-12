import 'package:flutter_diease_app/features/auth/sign_up_screen.dart';
import 'package:flutter/material.dart';

import '../../constants.dart';
import 'components/sign_in_form.dart';
import '../home/HomePage.dart';

class SignInScreen extends StatelessWidget {
  // It's time to validat the text field
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    // But still same problem, let's fixed it
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // SvgPicture.asset(
          //   "assets/icons/Sign_Up_bg.svg",
          //   height: MediaQuery.of(context).size.height,
          //   // Now it takes 100% of our height
          // ),

          Padding(
            padding:
                EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.1),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "로그인",
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium!
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        Text("계정이 없으신가요?"),
                        TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SignUpScreen(), // 회원가입 화면
                            ),
                          ),
                          child: Text(
                            "회원가입",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: defaultPadding * 2),
                    // 로그인 폼
                    SignInForm(formKey: _formKey),
                    const SizedBox(height: defaultPadding * 2),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF4A90E2), // 배경색
                          foregroundColor: Colors.white,      // 글자색
                          shadowColor: Colors.blueAccent,     // 그림자색 (선택)
                          elevation: 4,                       // 그림자 높이
                          shape: RoundedRectangleBorder(      // 버튼 둥근 모서리
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                        ),
                        onPressed: () {
                          // 로그인 버튼 클릭시 역할에 따라서 메인 페이지 구분해서 보여주기
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => HomePage(role: 'user')), // 로그인 결과 메인 화면으로 => 'role: 'doctor', 'patient', 'admin', 'manager'
                          );
                        },
                        child: Text("로그인", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),),
                      ),
                    ),



                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
