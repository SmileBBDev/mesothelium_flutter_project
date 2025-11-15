import 'package:flutter/material.dart';

class UserListPage extends StatefulWidget {
  const UserListPage({super.key});

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

  // 페이지네이션 상태
  int _currentPage = 0;
  final int _itemsPerPage = 10;

  int get _totalPages => (_filteredUsers.length / _itemsPerPage).ceil().clamp(1, 9999);

  List<Map<String, dynamic>> get _filteredUsers {
    return allUsers.where((user) {
      final matchesSearch =
          user['name'].toLowerCase().contains(searchQuery.toLowerCase());
      final matchesRole = selectedRole == '전체' || user['role'] == selectedRole;
      return matchesSearch && matchesRole;
    }).toList();
  }

  List<Map<String, dynamic>> get _paginatedUsers {
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, _filteredUsers.length);
    if (startIndex >= _filteredUsers.length) return [];
    return _filteredUsers.sublist(startIndex, endIndex);
  }

  void _goToPage(int page) {
    setState(() {
      _currentPage = page.clamp(0, _totalPages - 1);
    });
  }

  @override
  Widget build(BuildContext context) {

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
                        setState(() {
                          searchQuery = value;
                          _currentPage = 0; // 검색 시 첫 페이지로 리셋
                        });
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
                            _currentPage = 0; // 필터 변경 시 첫 페이지로 리셋
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

            // 페이지 정보
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '총 ${_filteredUsers.length}명',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${_currentPage + 1} / $_totalPages 페이지',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),

            // 사용자 목록
            _paginatedUsers.isEmpty
                ? Padding(
              padding: const EdgeInsets.only(top: 40.0),
              child: Center(child: Text('회원이 없습니다.')),
            )
                : ListView.builder(
              shrinkWrap: true, // ✅ 스크롤 중첩 방지
              physics: NeverScrollableScrollPhysics(), // ✅ HomePage 스크롤 사용
              itemCount: _paginatedUsers.length,
              itemBuilder: (context, index) {
                final user = _paginatedUsers[index];
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

            // 페이지네이션 컨트롤
            if (_filteredUsers.length > _itemsPerPage)
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: _currentPage > 0 ? () => _goToPage(_currentPage - 1) : null,
                      icon: const Icon(Icons.chevron_left),
                      tooltip: '이전 페이지',
                    ),
                    ..._buildPageButtons(),
                    IconButton(
                      onPressed: _currentPage < _totalPages - 1 ? () => _goToPage(_currentPage + 1) : null,
                      icon: const Icon(Icons.chevron_right),
                      tooltip: '다음 페이지',
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPageButtons() {
    List<Widget> buttons = [];
    int start = (_currentPage - 2).clamp(0, (_totalPages - 5).clamp(0, _totalPages));
    int end = (start + 5).clamp(0, _totalPages);

    if (start > 0) {
      start = (end - 5).clamp(0, _totalPages);
    }

    for (int i = start; i < end; i++) {
      buttons.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: ElevatedButton(
            onPressed: () => _goToPage(i),
            style: ElevatedButton.styleFrom(
              backgroundColor: i == _currentPage ? Colors.blue : Colors.grey[300],
              foregroundColor: i == _currentPage ? Colors.white : Colors.black87,
              minimumSize: const Size(40, 40),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: Text('${i + 1}'),
          ),
        ),
      );
    }

    return buttons;
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
