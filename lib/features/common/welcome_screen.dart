import 'package:flutter_diease_app/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // SvgPicture.asset("assets/icons/splash_bg.svg"),
          SvgPicture.asset("assets/icons/sky_blue_background.svg"),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Spacer(flex: 2),
                            SvgPicture.asset(
                              //"assets/icons/gerda_logo.svg",
                              "assets/icons/meso_dr_logo.svg",
                            ),
                            const Spacer(flex: 3),
                            // As you can see we need more paddind on our btn
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pushNamed(context, '/login');
                                },
                                // onPressed: () => Navigator.push(
                                //   context,
                                //   MaterialPageRoute(
                                //     builder: (context) =>  SignInScreen(), // 로그인 페이지
                                //   ),
                                // ),
                                style: TextButton.styleFrom(
                                  backgroundColor: Color(0xFF4A90E2)//Color(0xFF4DB6AC),     //Color(0xFF6CD8D1),
                                ),
                                child: Text("로그인", style: TextStyle(fontSize: 16, color : Color(0xFFE1F5FE), fontWeight: FontWeight.bold),),
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: defaultPadding),
                              child: SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.pushNamed(context, '/signup');
                                  },
                                  // onPressed: () => Navigator.push(
                                  //     context,
                                  //     MaterialPageRoute(
                                  //       builder: (context) => SignUpScreen(), // 회원가입 페이지
                                  //     )),
                                  style: TextButton.styleFrom(
                                    // backgroundColor: Color(0xFF6CD8D1),
                                    elevation: 0,
                                    backgroundColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      side: BorderSide(color: Color(0xFF4DB6AC)),
                                    ),
                                  ),
                                  child: Text("회원가입", style: TextStyle(fontSize: 16, color : Color(0xFF006064), fontWeight: FontWeight.bold),),
                                ),
                              ),
                            ),
                            const SizedBox(height: defaultPadding),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
