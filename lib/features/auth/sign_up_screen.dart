import 'package:flutter_diease_app/constants.dart';
import 'package:flutter_diease_app/features/auth/sign_in_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/provider/auth_provider.dart';
import '../home/HomePage.dart';
import 'components/sign_up_form.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _userNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneNumberController = TextEditingController();

  bool _loading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _userIdController.dispose();
    _passwordController.dispose();
    _userNameController.dispose();
    _emailController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      // 회원가입 수행 (AuthProvider를 통해 자동으로 토큰 저장 및 사용자 설정)
      await context.read<AuthProvider>().register(
        _userIdController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text.trim(),
        name: _userNameController.text.trim(),
        phone: _phoneNumberController.text.trim(),
        role: 'general', // 기본 역할
      );

      if (!mounted) return;

      // 회원가입 성공 후 사용자 정보 가져오기
      final user = context.read<AuthProvider>().user;

      if (user != null) {
        // 자동 로그인 성공 → Home 화면으로 이동
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomePage(user: user),
          ),
        );
      } else {
        // 토큰이 없는 경우 (회원가입은 성공했지만 자동 로그인 실패)
        // 로그인 화면으로 이동
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('회원가입이 완료되었습니다. 로그인해주세요.'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => SignInScreen()),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '회원가입 실패: ${e.toString()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
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
            top: defaultPadding,
            bottom: MediaQuery.of(context).viewInsets.bottom + defaultPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "회원가입",
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium!
                    .copyWith(fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  Text("이미 계정이 있으신가요?"),
                  TextButton(
                    onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SignInScreen(),
                      ),
                    ),
                    child: Text(
                      "로그인",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: defaultPadding * 2),
              // 회원가입 입력 폼
              SignUpForm(
                formKey: _formKey,
                userIdController: _userIdController,
                passwordController: _passwordController,
                userNameController: _userNameController,
                emailController: _emailController,
                phoneNumberController: _phoneNumberController,
              ),
              const SizedBox(height: defaultPadding * 2),

              // 에러 메시지 표시
              if (_errorMessage != null) ...[
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
                          _errorMessage!,
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
                  onPressed: _loading ? null : _handleSignUp,
                  child: Text(
                    _loading ? '가입 중...' : '가입 완료',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
