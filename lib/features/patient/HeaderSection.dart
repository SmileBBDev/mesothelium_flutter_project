import 'package:flutter/material.dart';
class HeaderSection extends StatelessWidget {
  const HeaderSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("내게 맞는", style: TextStyle(fontSize: 22, color: Colors.black54)),
          const Text("의료진 찾기", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF4A90E2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "Looking For Your Desire Specialist Doctor?",
                        style: TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Dr. Asma Khan",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Image.asset(
                  "assets/images/search_doc_1.png",
                  height: 80,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
