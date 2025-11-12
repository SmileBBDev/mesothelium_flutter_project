import 'package:flutter/material.dart';

class ApprovalPage extends StatefulWidget {
  const ApprovalPage({Key? key}) : super(key: key);

  @override
  _ApprovalPageState createState() => _ApprovalPageState();
}

class _ApprovalPageState extends State<ApprovalPage> {
  // 임시 데이터 (DB 연동 전)
  List<Map<String, dynamic>> pendingUsers = [
    {'id': 1, 'name': '김의사', 'role': '의사', 'email': 'doctor1@test.com'},
    {'id': 2, 'name': '이환자', 'role': '환자', 'email': 'patient2@test.com'},
    {'id': 3, 'name': '박의사', 'role': '의사', 'email': 'doctor3@test.com'},
  ];

  // 승인된 사용자 리스트 (DB 연동 시 별도 저장)
  List<Map<String, dynamic>> approvedUsers = [];

  void _approveUser(Map<String, dynamic> user) {
    setState(() {
      pendingUsers.remove(user);
      approvedUsers.add(user);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("${user['name']} 님을 승인했습니다.")),
    );
  }

  void _rejectUser(Map<String, dynamic> user) {
    setState(() {
      pendingUsers.remove(user);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("${user['name']} 님의 요청을 거절했습니다.")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '회원 승인 관리',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),

            // 대기중인 사용자 목록
            Flexible(
              fit: FlexFit.loose, // unbounded 부모 안에서도 정상 작동
              child: pendingUsers.isEmpty
                  ? Center(
                child: Text(
                  '승인 대기 중인 사용자가 없습니다.',
                  style: TextStyle(color: Colors.grey),
                ),
              )
                  : ListView.builder(
                shrinkWrap: true, // 추가: 내부 높이를 스스로 계산하도록
                physics: NeverScrollableScrollPhysics(), // 부모 스크롤과 충돌 방지
                itemCount: pendingUsers.length,
                itemBuilder: (context, index) {
                  final user = pendingUsers[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${user['name']} (${user['role']})",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            user['email'],
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // 승인 버튼
                              ElevatedButton(
                                onPressed: () => _approveUser(user),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFA8E6CF),
                                  foregroundColor: const Color(0xFF2E7D32),
                                  minimumSize: const Size(70, 32),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  elevation: 3,
                                ),
                                child: const Text(
                                  '승인',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // 거절 버튼
                              ElevatedButton(
                                onPressed: () => _rejectUser(user),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFFD6D6),
                                  foregroundColor: const Color(0xFFC62828),
                                  minimumSize: const Size(70, 32),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  elevation: 3,
                                ),
                                child: const Text(
                                  '거절',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
