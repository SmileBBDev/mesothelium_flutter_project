import 'package:flutter/material.dart';

class UserListPage extends StatefulWidget {
  const UserListPage({Key? key}) : super(key: key);

  @override
  _UserListPageState createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  List<Map<String, dynamic>> allUsers = [
    {'id': 1, 'name': '김의사', 'role': '의사', 'email': 'doctor1@test.com', 'active': true},
    {'id': 2, 'name': '이환자', 'role': '환자', 'email': 'patient2@test.com', 'active': true},
    {'id': 3, 'name': '박의사', 'role': '의사', 'email': 'doctor3@test.com', 'active': false},
  ];

  String searchQuery = '';
  String selectedRole = '전체';

  @override
  Widget build(BuildContext context) {
    final filteredUsers = allUsers.where((user) {
      final matchesSearch =
      user['name'].toLowerCase().contains(searchQuery.toLowerCase());
      final matchesRole = selectedRole == '전체' || user['role'] == selectedRole;
      return matchesSearch && matchesRole;
    }).toList();

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '전체 회원 조회',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),

            // 검색창 + 역할 필터
            Row(
              children: [
                // 검색창
                Expanded(
                  child: Material(
                    elevation: 2,
                    borderRadius: BorderRadius.circular(12),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: "이름 검색",
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      onChanged: (value) {
                        setState(() => searchQuery = value);
                      },
                    ),
                  ),
                ),
                SizedBox(width: 10),

                // 역할 드롭다운
                Material(
                  elevation: 2,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedRole,
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedRole = newValue!;
                          });
                        },
                        items: ['전체', '의사', '환자']
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            // 👇 스크롤 부분 수정 (HomePage Scroll에 맞게)
            filteredUsers.isEmpty
                ? Padding(
              padding: const EdgeInsets.only(top: 40.0),
              child: Center(child: Text('회원이 없습니다.')),
            )
                : ListView.builder(
              shrinkWrap: true, // ✅ 스크롤 중첩 방지
              physics: NeverScrollableScrollPhysics(), // ✅ HomePage 스크롤 사용
              itemCount: filteredUsers.length,
              itemBuilder: (context, index) {
                final user = filteredUsers[index];
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    title: Text("${user['name']} (${user['role']})"),
                    subtitle: Text(user['email']),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            user['active']
                                ? Icons.check_circle
                                : Icons.pause_circle_filled,
                            color: user['active']
                                ? Colors.green
                                : Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              user['active'] = !user['active'];
                            });
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            _deleteUser(user);
                          },
                        ),
                      ],
                    ),
                    onTap: () => _showUserDetail(context, user),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _deleteUser(Map<String, dynamic> user) {
    setState(() {
      allUsers.remove(user);
    });
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("${user['name']} 님이 삭제되었습니다.")));
  }

  void _showUserDetail(BuildContext context, Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("${user['name']} 상세 정보"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("이메일: ${user['email']}"),
            Text("역할: ${user['role']}"),
            Text("상태: ${user['active'] ? '활성' : '비활성'}"),
            SizedBox(height: 12),
            Text("가입일: 2025-11-01"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('닫기'),
          ),
        ],
      ),
    );
  }
}
