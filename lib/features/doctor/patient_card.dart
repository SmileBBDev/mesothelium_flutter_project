// 환자 조회 페이지
import 'package:flutter/material.dart';
import '../../constants.dart';
import 'medical_document_editor.dart';

class PatientCard extends StatelessWidget {
  final List<Map<String, String>> patients; // 환자 데이터 정보 받기
  const PatientCard({super.key, required this.patients});

  @override
  Widget build(BuildContext context) {
    if (patients.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: Text("진료 예정 환자가 없습니다.", style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text("진료 예정 환자 ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              Text("See All", style: TextStyle(color: Colors.blue)),
            ],
          ),
        ),
        const SizedBox(height: defaultPadding),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child:Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.grey.shade200, blurRadius: 8),
              ],
            ),
            child: Column(
              children: patients.map((p) {
                
              final name = p["name"]?.toString() ?? "이름 없음";
              final birthYear = p["birth_year"];
              final age = birthYear != null ? (DateTime.now().year - (birthYear as int)) : null;
              final phone = p["phone"]?.toString() ?? "";
              final patientId = p["id"] as int? ?? 0;

              return Column(
                children: [
                  ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text("${p["name"]} (${p["age"]}세, ${p["gender"]})"),
                    subtitle: Text("진료 시간: ${p["time"]}"),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // 진료 문서 작성 페이지로 이동
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MedicalDocumentEditor(
                            patientId: patientId,
                            patientName: name,
                            patientInfo: age != null ? "$name ($age세)" : name,
                          ),
                        ),
                      );
                    },
                  ),
                  if (p != patients.last) const Divider(),
                ],
              );
             }).toList(),
            ),
          )
        )
      ],
    );
  }
}
