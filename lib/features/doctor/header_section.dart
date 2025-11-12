import 'package:flutter/material.dart';
class DoctorHeaderSection extends StatelessWidget {
  const DoctorHeaderSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, // 텍스트와 이미지 양끝 정렬
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 왼쪽 텍스트
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              const Text("안녕하세요", style: TextStyle(fontSize: 16, color: Colors.black54)),
              const Text("ooo 의사님", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            ],
          ),

          // 오른쪽 프로필 이미지
          const CircleAvatar(
            radius: 30,
            backgroundImage: AssetImage('assets/images/search_doc_4.png'),
          ),
        ],
      ),
    );
  }
}
