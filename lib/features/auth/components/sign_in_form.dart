import 'package:flutter/material.dart';
import 'package:form_field_validator/form_field_validator.dart';

import '../../../constants.dart';
import 'sign_up_form.dart';

class SignInForm extends StatelessWidget {
  SignInForm({
    Key? key,
    required this.formKey,
  }) : super(key: key);

  final GlobalKey formKey;

  late String _id, _password;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFieldName(text: "아이디"),
          TextFormField(
            keyboardType: TextInputType.text,
            decoration: InputDecoration(hintText: "userId"),
            // validator: EmailValidator(errorText: "Use a valid email!"),
            onSaved: (id) => _id = id!,
          ),
          const SizedBox(height: defaultPadding),
          TextFieldName(text: "패스워드"),
          TextFormField(
            // We want to hide our password
            obscureText: true,
            decoration: InputDecoration(hintText: "******"),
            //validator: passwordValidator,
            onSaved: (password) => _password = password!,
          ),
          const SizedBox(height: defaultPadding),

        ],
      ),
    );
  }
}
