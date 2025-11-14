import 'package:flutter/material.dart';
import 'package:form_field_validator/form_field_validator.dart';

import '../../../constants.dart';

class SignUpForm extends StatelessWidget {
   SignUpForm({
    super.key,
    required this.formKey,
  });

  final GlobalKey formKey;

  late String _userId, _password, _userName, _email, _phoneNumber;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFieldName(text: "아이디"),
          TextFormField(
            decoration: InputDecoration(hintText: "userId"),
            validator: RequiredValidator(errorText: "Id를 입력해주세요").call,
            onSaved: (userId) => _userId = userId!,
          ),


          const SizedBox(height: defaultPadding),
          TextFieldName(text: "패스워드"),
          TextFormField(
            // We want to hide our password
            obscureText: true,
            decoration: InputDecoration(hintText: "******"),
            validator: passwordValidator.call,
            onSaved: (password) => _password = password!,
            // We also need to validate our password
            // Now if we type anything it adds that to our password
            onChanged: (pass) => _password = pass,
          ),
          const SizedBox(height: defaultPadding),
          TextFieldName(text: "패스워드 확인"),
          TextFormField(
            obscureText: true,
            decoration: InputDecoration(hintText: "*****"),
            validator: (pass) => MatchValidator(errorText: "Password do not  match").validateMatch(pass!, _password),
          ),
          const SizedBox(height: defaultPadding),
          TextFieldName(text: "이름"),
          TextFormField(
            decoration: InputDecoration(hintText: "홍길동"),
            validator: RequiredValidator(errorText: "성함을 입력해주세요").call,
            // Let's save our username
            onSaved: (username) => _userName = username!,
          ),
          const SizedBox(height: defaultPadding),
          // We will fixed the error soon
          // As you can see, it's a email field
          // But no @ on keybord
          TextFieldName(text: "Email"),
          TextFormField(
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(hintText: "mesodr@email.com"),
            validator: EmailValidator(errorText: "Use a valid email!").call,
            onSaved: (email) => _email = email!,
          ),
          const SizedBox(height: defaultPadding),
          TextFieldName(text: "Phone"),
          // Same for phone number
          TextFormField(
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(hintText: "01012341234"),
            validator: RequiredValidator(errorText: "Phone number is required").call,
            onSaved: (phoneNumber) => _phoneNumber = phoneNumber!,
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
