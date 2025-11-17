import 'package:flutter/material.dart';
import '../../core/service/user_management_service.dart';

class UserListPage extends StatefulWidget {
  const UserListPage({super.key});

  @override
  _UserListPageState createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  final UserManagementService _userService = UserManagementService();

  List<Map<String, dynamic>> allUsers = [];
  bool isLoading = true;
  String? errorMessage;

  String searchQuery = '';
  String selectedRole = '전체';

  // 페이지네이션 상태
  int _currentPage = 0;
  final int _itemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await _userService.getUsers();
      if (result.success && result.users != null) {
        setState(() {
          allUsers = result.users!;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = result.message ?? '회원 목록을 불러올 수 없습니다.';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = '오류가 발생했습니다: $e';
        isLoading = false;
      });
    }
  }

  int get _totalPages => (_filteredUsers.length / _itemsPerPage).ceil().clamp(1, 9999);

  List<Map<String, dynamic>> get _filteredUsers {
    return allUsers.where((user) {
      final name = user['username'] ?? user['name'] ?? '';
      final matchesSearch = name.toLowerCase().contains(searchQuery.toLowerCase());

      // role 필터링: '전체', '의사'(doctor), '환자'(patient), '직원'(staff)
      bool matchesRole = true;
      if (selectedRole != '전체') {
        final userRole = user['role'] ?? '';
        if (selectedRole == '의사') {
          matchesRole = userRole == 'doctor';
        } else if (selectedRole == '환자') {
          matchesRole = userRole == 'patient';
        } else if (selectedRole == '직원') {
          matchesRole = userRole == 'staff';
        }
      }

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

  String _getRoleDisplayName(String? role) {
    switch (role) {
      case 'doctor':
        return '의사';
      case 'patient':
        return '환자';
      case 'staff':
        return '직원';
      case 'admin':
        return '관리자';
      default:
        return '미지정';
    }
  }

  Future<void> _toggleUserActive(Map<String, dynamic> user) async {
    final userId = user['id'];
    final currentStatus = user['is_active'] ?? true;

    try {
      final response = await _userService.toggleUserActive(userId, !currentStatus);

      if (!mounted) return;

      if (response.success) {
        setState(() {
          user['is_active'] = !currentStatus;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${user['username'] ?? '회원'}의 상태가 ${!currentStatus ? '활성화' : '비활성화'}되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message ?? '상태 변경에 실패했습니다.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('오류가 발생했습니다: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('회원 정보를 불러오는 중...'),
            ],
          ),
        ),
      );
    }

    if (errorMessage != null) {
      return SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                errorMessage!,
                style: TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadUsers,
                icon: Icon(Icons.refresh),
                label: Text('다시 시도'),
              ),
            ],
          ),
        ),
      );
    }

    return SafeArea(
      child: SingleChildScrollView(
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
                        items: ['전체', '의사', '환자', '직원']
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
                : RefreshIndicator(
              onRefresh: _loadUsers,
              child: ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: _paginatedUsers.length,
                itemBuilder: (context, index) {
                  final user = _paginatedUsers[index];
                  final userName = user['username'] ?? user['name'] ?? '이름 없음';
                  final userEmail = user['email'] ?? '이메일 없음';
                  final userRole = _getRoleDisplayName(user['role']);
                  final isActive = user['is_active'] ?? true;
                  final isApproved = user['is_approved'] ?? true;

                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isActive ? Colors.blue : Colors.grey,
                        child: Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Row(
                        children: [
                          Expanded(child: Text("$userName ($userRole)")),
                          if (!isApproved)
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '미승인',
                                style: TextStyle(color: Colors.white, fontSize: 10),
                              ),
                            ),
                        ],
                      ),
                      subtitle: Text(userEmail),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _showEditUserDialog(user),
                            tooltip: '편집',
                          ),
                          IconButton(
                            icon: Icon(
                              isActive ? Icons.check_circle : Icons.pause_circle_filled,
                              color: isActive ? Colors.green : Colors.grey,
                            ),
                            onPressed: () => _toggleUserActive(user),
                            tooltip: isActive ? '활성화됨' : '비활성화됨',
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteUser(user),
                            tooltip: '삭제',
                          ),
                        ],
                      ),
                      onTap: () => _showUserDetail(context, user),
                    ),
                  );
                },
              ),
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

  Future<void> _deleteUser(Map<String, dynamic> user) async {
    final userName = user['username'] ?? user['name'] ?? '회원';
    final userId = user['id'];

    // 삭제 확인 다이얼로그
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('회원 삭제'),
        content: Text('정말로 $userName 님을 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final response = await _userService.deleteUser(userId);

      if (!mounted) return;

      if (response.success) {
        setState(() {
          allUsers.removeWhere((u) => u['id'] == userId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$userName 님이 삭제되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message ?? '삭제에 실패했습니다.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('오류가 발생했습니다: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showUserDetail(BuildContext context, Map<String, dynamic> user) {
    final userName = user['username'] ?? user['name'] ?? '이름 없음';
    final userEmail = user['email'] ?? '이메일 없음';
    final userRole = _getRoleDisplayName(user['role']);
    final isActive = user['is_active'] ?? true;
    final isApproved = user['is_approved'] ?? true;
    final createdAt = user['created_at'] ?? user['date_joined'] ?? '정보 없음';
    final phone = user['phone'] ?? user['phone_number'] ?? '전화번호 없음';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: isActive ? Colors.blue : Colors.grey,
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                style: TextStyle(color: Colors.white),
              ),
            ),
            SizedBox(width: 12),
            Expanded(child: Text("$userName 상세 정보")),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('이름', userName),
              _buildDetailRow('이메일', userEmail),
              _buildDetailRow('전화번호', phone),
              _buildDetailRow('역할', userRole),
              _buildDetailRow('상태', isActive ? '활성' : '비활성'),
              _buildDetailRow('승인 여부', isApproved ? '승인됨' : '미승인'),
              _buildDetailRow('가입일', createdAt.toString().split('T')[0]),
              SizedBox(height: 12),
              if (!isApproved)
                ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    await _approveUser(user);
                  },
                  icon: Icon(Icons.check),
                  label: Text('승인하기'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    minimumSize: Size(double.infinity, 40),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showEditUserDialog(user);
            },
            child: Text('편집'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('닫기'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Future<void> _approveUser(Map<String, dynamic> user) async {
    final userId = user['id'];
    final userName = user['username'] ?? user['name'] ?? '회원';

    try {
      final response = await _userService.approveUser(userId);

      if (!mounted) return;

      if (response.success) {
        setState(() {
          user['is_approved'] = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$userName 님이 승인되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message ?? '승인에 실패했습니다.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('오류가 발생했습니다: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showEditUserDialog(Map<String, dynamic> user) {
    final userNameController = TextEditingController(text: user['username'] ?? user['name'] ?? '');
    final emailController = TextEditingController(text: user['email'] ?? '');
    final phoneController = TextEditingController(text: user['phone'] ?? user['phone_number'] ?? '');

    // role 값 검증 및 기본값 설정
    String userRole = user['role'] ?? 'patient';
    final validRoles = ['doctor', 'patient', 'staff', 'admin'];
    String selectedEditRole = validRoles.contains(userRole) ? userRole : 'patient';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('회원 정보 편집'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: userNameController,
                  decoration: InputDecoration(
                    labelText: '이름',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: '이메일',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  decoration: InputDecoration(
                    labelText: '전화번호',
                    prefixIcon: Icon(Icons.phone),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedEditRole,
                  decoration: InputDecoration(
                    labelText: '역할',
                    prefixIcon: Icon(Icons.badge),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: [
                    DropdownMenuItem(value: 'doctor', child: Text('의사')),
                    DropdownMenuItem(value: 'patient', child: Text('환자')),
                    DropdownMenuItem(value: 'staff', child: Text('직원')),
                    DropdownMenuItem(value: 'admin', child: Text('관리자')),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      selectedEditRole = value!;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('취소'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _updateUser(
                  user,
                  userNameController.text,
                  emailController.text,
                  phoneController.text,
                  selectedEditRole,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: Text('저장'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateUser(
    Map<String, dynamic> user,
    String newName,
    String newEmail,
    String newPhone,
    String newRole,
  ) async {
    final userId = user['id'];

    try {
      // 사용자 정보 업데이트 데이터 준비
      Map<String, dynamic> updateData = {};

      // 변경사항이 있는 경우에만 추가
      final currentName = user['username'] ?? user['name'] ?? '';
      final currentEmail = user['email'] ?? '';
      final currentPhone = user['phone'] ?? user['phone_number'] ?? '';

      if (newName.isNotEmpty && newName != currentName) {
        updateData['username'] = newName;
      }
      if (newEmail.isNotEmpty && newEmail != currentEmail) {
        updateData['email'] = newEmail;
      }
      if (newPhone.isNotEmpty && newPhone != currentPhone) {
        updateData['phone'] = newPhone;
      }

      print('🔍 업데이트 데이터: $updateData');
      print('🔍 사용자 ID: $userId');

      // 기본 정보 업데이트
      if (updateData.isNotEmpty) {
        print('📤 사용자 정보 업데이트 요청 중...');
        final updateResponse = await _userService.updateUser(userId, updateData);

        print('📥 업데이트 응답: success=${updateResponse.success}, message=${updateResponse.message}');
        print('📥 응답 데이터: ${updateResponse.data}');

        if (!updateResponse.success) {
          if (!mounted) return;

          // 더 상세한 에러 메시지 표시
          String errorMsg = updateResponse.errorMessage;
          if (updateResponse.data != null) {
            errorMsg += '\n상세: ${updateResponse.data}';
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMsg),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
            ),
          );
          return;
        }
      }

      // 역할 변경이 있는 경우 별도 처리
      if (newRole != user['role']) {
        print('📤 역할 변경 요청 중: ${user['role']} -> $newRole');
        final roleResponse = await _userService.changeUserRole(userId, newRole);

        print('📥 역할 변경 응답: success=${roleResponse.success}, message=${roleResponse.message}');

        if (!roleResponse.success) {
          if (!mounted) return;

          String errorMsg = roleResponse.errorMessage;
          if (roleResponse.data != null) {
            errorMsg += '\n상세: ${roleResponse.data}';
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMsg),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
            ),
          );
          return;
        }
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$newName 님의 정보가 수정되었습니다.'),
          backgroundColor: Colors.green,
        ),
      );

      // 서버에서 최신 데이터 다시 불러오기
      await _loadUsers();
    } catch (e) {
      print('❌ 사용자 업데이트 오류: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('오류가 발생했습니다: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }
}
