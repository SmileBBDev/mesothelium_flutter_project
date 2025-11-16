import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/base_config.dart';
import '../../constants.dart';
import '../../core/provider/auth_provider.dart';
import 'components/sign_in_form.dart';
import '../home/home_page.dart';
import 'package:flutter_diease_app/features/auth/sign_up_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({Key? key}) : super(key: key);

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}
class _SignInScreenState extends State<SignInScreen>{
  final formKey = GlobalKey<FormState>();
  final idController = TextEditingController();
  final pwController = TextEditingController();

  bool _loading = false;
  String? _err;

  @override
  void dispose() {
    idController.dispose();
    pwController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true, // 키보드가 올라올 때 화면 조정
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: defaultPadding,
            right: defaultPadding,
            top: MediaQuery.of(context).size.height * 0.1,
            bottom: MediaQuery.of(context).viewInsets.bottom + defaultPadding,
          ),
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
                    onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SignUpScreen(),
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
              SignInForm(
                formKey: formKey,
                idController: idController,
                pwController: pwController,
              ),
              const SizedBox(height: defaultPadding * 2),

              // 에러 메시지 표시
              if (_err != null) ...[
                Container(
                  padding: EdgeInsets.all(defaultPadding),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _err!,
                          style: TextStyle(color: Colors.red.shade900),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: defaultPadding),
              ],

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF4A90E2),
                    foregroundColor: Colors.white,
                    shadowColor: Colors.blueAccent,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  ),
                  onPressed: _loading
                    ? null
                    : () async {
                      if (!formKey.currentState!.validate()) return;

                      setState(() {
                        _loading = true;
                        _err = null;
                      });

                      try {
                        final authProvider = context.read<AuthProvider>();
                        await authProvider.login(
                          idController.text.trim(),
                          pwController.text.trim(),
                        );

                        if (!mounted) return;
                        await BaseConfig().init();

                        final user = authProvider.user!;

                        // 로그인 성공 → 메인 페이지로 이동
                        if (mounted) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => HomePage(user: user)
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          setState(() {
                            _err = '로그인 실패: ${e.toString()}';
                          });
                        }
                      } finally {
                        if (mounted) {
                          setState(() {
                            _loading = false;
                          });
                        }
                      }
                    },
                  child: Text(
                    _loading ? '로그인 중...' : '로그인',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              // 하단 여백 추가 (스마트폰 하단바 대응)
              const SizedBox(height: defaultPadding * 2),
            ],
          ),
        ),
      ),
    );
  }
}
