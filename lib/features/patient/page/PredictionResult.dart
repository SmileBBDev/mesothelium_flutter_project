import 'package:flutter/material.dart';

class PredictionResult extends StatelessWidget {
  const PredictionResult({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // 자동 뒤로가기 불가
        title: const Text("진단 결과"),
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: const Center(
        child: Text(
          "진단결과 조회 화면입니다.",
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
