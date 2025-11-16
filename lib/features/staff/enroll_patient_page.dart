import 'package:flutter/material.dart';

class EnrollPatientPage extends StatefulWidget {
  const EnrollPatientPage({super.key});

  @override
  State<EnrollPatientPage> createState() => _EnrollPatientPageState();
}

class _EnrollPatientPageState extends State<EnrollPatientPage> {
  final _formKey = GlobalKey<FormState>();

  String selectedDoctor = "김의사";
  String patientName = "";
  String gender = "남성";
  DateTime? birthDate;
  DateTime? reservationDate;
  String phoneNumber = "";

  String formatDate(DateTime? date) {
    if (date == null) return "선택해주세요";
    return "${date.year}-${date.month}-${date.day}";
  }

  Future<void> pickDate(BuildContext context, bool isBirth) async {
    final now = DateTime.now();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      locale: const Locale('ko'),
    );

    if (picked != null) {
      setState(() {
        if (isBirth) {
          birthDate = picked;
        } else {
          reservationDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("환자 예약 등록"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// ------------------ 이름 ------------------
              const Text("이름", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextFormField(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "환자 이름",
                ),
                validator: (v) =>
                v == null || v.isEmpty ? "이름을 입력해주세요" : null,
                onChanged: (v) => patientName = v,
              ),

              const SizedBox(height: 20),

              /// ------------------ 성별 ------------------
              const Text("성별", style: TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Radio(
                    value: "남성",
                    groupValue: gender,
                    onChanged: (value) {
                      setState(() => gender = value.toString());
                    },
                  ),
                  const Text("남성"),
                  Radio(
                    value: "여성",
                    groupValue: gender,
                    onChanged: (value) {
                      setState(() => gender = value.toString());
                    },
                  ),
                  const Text("여성"),
                ],
              ),

              const SizedBox(height: 20),

              /// ------------------ 생년월일 ------------------
              const Text("생년월일", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              InkWell(
                onTap: () => pickDate(context, true),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 15, horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(formatDate(birthDate)),
                ),
              ),

              const SizedBox(height: 20),

              /// ------------------ 연락처 ------------------
              const Text("연락처", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: "전화번호",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                onChanged: (v) => phoneNumber = v,
                validator: (v) =>
                v == null || v.isEmpty ? "연락처를 입력해주세요" : null,
              ),

              const SizedBox(height: 20),

              /// ------------------ 의사 선택 ------------------
              const Text("의사 선택", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                value: selectedDoctor,
                items: const [
                  DropdownMenuItem(value: '김의사', child: Text('김의사')),
                  DropdownMenuItem(value: '박의사', child: Text('박의사')),
                  DropdownMenuItem(value: '최의사', child: Text('최의사')),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedDoctor = value!;
                  });
                },
              ),

              const SizedBox(height: 20),


              /// ------------------ 예약 날짜 ------------------
              const Text("예약 날짜", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              InkWell(
                onTap: () => pickDate(context, false),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 15, horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(formatDate(reservationDate)),
                ),
              ),

              const SizedBox(height: 30),



              /// ------------------ 등록 버튼 ------------------
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2), // 🔵 버튼 색
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      if (birthDate == null || reservationDate == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("날짜를 모두 선택해주세요.")),
                        );
                        return;
                      }

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("예약 등록 완료!")),
                      );
                    }
                  },
                  child: const Text(
                    "예약 등록하기",
                    style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
