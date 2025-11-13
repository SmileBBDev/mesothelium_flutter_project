import 'package:flutter/material.dart';

class DiseaseView extends StatelessWidget {
  const DiseaseView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("질병안내"),
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: const Center(
        child: Text(
          "질병 안내 화면입니다.",
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
