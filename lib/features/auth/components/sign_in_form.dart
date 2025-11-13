import 'package:flutter/material.dart';
import 'package:form_field_validator/form_field_validator.dart';

import '../../../constants.dart';
import 'sign_up_form.dart';

//로그인 폼 클래스
class SignInForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController idController;
  final TextEditingController pwController;

  const SignInForm({
    Key? key,
    required this.formKey,
    required this.idController,
    required this.pwController,
  }) : super(key: key);

  @override
  State<SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends State<SignInForm>{

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFieldName(text: "아이디"),
          TextFormField(
            keyboardType: TextInputType.text,
            decoration: InputDecoration(hintText: "userId"),
            controller: widget.idController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '아이디를 입력해주세요';
              }
              return null;
            },

          ),
          const SizedBox(height: defaultPadding),
          TextFieldName(text: "패스워드"),
          TextFormField(
            // We want to hide our password
            obscureText: true,
            decoration: InputDecoration(hintText: "******"),
            controller: widget.pwController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '비밀번호를 입력해주세요';
              } else if (value.length < 2) {
                return '비밀번호는 최소 2자 이상이어야 합니다';
              }
              return null;
            },
          ),
          const SizedBox(height: defaultPadding),

        ],
      ),
    );
  }
}
