import 'package:flutter/material.dart';

class MyAppointments extends StatelessWidget {
  const MyAppointments({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // 자동 뒤로가기 불가
        title: const Text("진료 예약"),
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: const Center(
        child: Text(
          "진료예약 화면입니다.",
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
