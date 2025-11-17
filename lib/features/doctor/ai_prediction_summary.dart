// AI 예측 모델로 진단하는 페이지
import 'package:flutter/material.dart';
import '../../constants.dart';

class AiPredictSummary extends StatelessWidget {
  final Function(String)? onTap;

  const AiPredictSummary({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text("환자 진단 예측", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: InkWell(
            onTap: () {
              // 진단 결과 페이지로 이동
              if (onTap != null) {
                onTap!('/predictionResult');
              } else {
                Navigator.pushNamed(context, '/predictionResult');
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(defaultPadding),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.grey.shade200, blurRadius: 8),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Icon(Icons.analytics_outlined, color: Colors.green, size: 32),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "AI 기반 환자 진단 예측을 통해 빠른 판단을 지원합니다.",
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 16),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
