import 'package:flutter/material.dart';
import '../../../core/model/patient.dart';

class MyAllPatientView extends StatelessWidget {
  final List<Patient>? patients;
  final bool? isLoading;

  const MyAllPatientView({
    super.key,
    this.patients,
    this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final safePatients = patients ?? [];        // null 방지
    final loading = isLoading ?? false;         // null이면 false

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        automaticallyImplyLeading: false, // 자동 뒤로가기 불가
        title: const Text("환자 전체 조회"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,

      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : safePatients.isEmpty
          ? const Center(child: Text("등록된 환자가 없습니다."))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: safePatients.length,
        itemBuilder: (context, index) {
          final p = safePatients[index];
          return _buildPatientCard(p);
        },
      ),
    );
  }

  Widget _buildPatientCard(Patient p) {
    return Container(
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 26,
            backgroundColor: Colors.indigoAccent,
            child: Icon(Icons.person, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.name ?? "이름 없음",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "생년: ${p.birthYear ?? '미입력'}",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
                Text(
                  "성별: ${p.gender ?? '미입력'}",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),

          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        ],
      ),
    );
  }
}
