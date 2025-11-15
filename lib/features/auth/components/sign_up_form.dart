import 'package:flutter/material.dart';
import 'package:form_field_validator/form_field_validator.dart';

import '../../../constants.dart';

class SignUpForm extends StatefulWidget {
  const SignUpForm({
    super.key,
    required this.formKey,
    required this.userIdController,
    required this.passwordController,
    required this.userNameController,
    required this.emailController,
    required this.phoneNumberController,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController userIdController;
  final TextEditingController passwordController;
  final TextEditingController userNameController;
  final TextEditingController emailController;
  final TextEditingController phoneNumberController;

  @override
  State<SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm> {
  String _password = '';

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFieldName(text: "아이디"),
          TextFormField(
            controller: widget.userIdController,
            decoration: InputDecoration(hintText: "userId"),
            validator: RequiredValidator(errorText: "Id를 입력해주세요").call,
          ),

          const SizedBox(height: defaultPadding),
          TextFieldName(text: "패스워드"),
          TextFormField(
            controller: widget.passwordController,
            obscureText: true,
            decoration: InputDecoration(hintText: "******"),
            validator: passwordValidator.call,
            onChanged: (pass) => _password = pass,
          ),
          const SizedBox(height: defaultPadding),
          TextFieldName(text: "패스워드 확인"),
          TextFormField(
            obscureText: true,
            decoration: InputDecoration(hintText: "*****"),
            validator: (pass) => MatchValidator(errorText: "비밀번호가 일치하지 않습니다").validateMatch(pass!, _password),
          ),
          const SizedBox(height: defaultPadding),
          TextFieldName(text: "이름"),
          TextFormField(
            controller: widget.userNameController,
            decoration: InputDecoration(hintText: "홍길동"),
            validator: RequiredValidator(errorText: "성함을 입력해주세요").call,
          ),
          const SizedBox(height: defaultPadding),
          TextFieldName(text: "Email"),
          TextFormField(
            controller: widget.emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(hintText: "mesodr@email.com"),
            validator: EmailValidator(errorText: "올바른 이메일을 입력해주세요!").call,
          ),
          const SizedBox(height: defaultPadding),
          TextFieldName(text: "Phone"),
          TextFormField(
            controller: widget.phoneNumberController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(hintText: "01012341234"),
            validator: RequiredValidator(errorText: "전화번호를 입력해주세요").call,
          ),
        ],
      ),
    );
  }
}

class TextFieldName extends StatelessWidget {
  const TextFieldName({
    super.key,
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: defaultPadding / 3),
      child: Text(
        text,
        style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black54),
      ),
    );
  }
}
