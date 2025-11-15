import 'package:flutter/material.dart';
import '../../core/service/user_service.dart';

class UserListPage extends StatefulWidget {
  const UserListPage({super.key});

  @override
  _UserListPageState createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  final UserService _userService = UserService();

  List<Map<String, dynamic>> allUsers = [];
  List<Map<String, dynamic>> allDoctors = [];
  bool _isLoading = false;

  String searchQuery = '';
  String selectedRole = '전체';

  // 페이지네이션 상태
  int _currentPage = 0;
  final int _itemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _loadDoctors();
  }

  int get _totalPages => (_filteredUsers.length / _itemsPerPage).ceil().clamp(1, 9999);

  /// 사용자 목록 로드
  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await _userService.getUserList();
      setState(() {
        allUsers = users;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('사용자 목록 로드 실패: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 의사 목록 로드
  Future<void> _loadDoctors() async {
    try {
      // ignore: avoid_print
      print('[DEBUG] 의사 목록 로딩 시작...');
      final doctors = await _userService.getDoctorList();
      // ignore: avoid_print
      print('[DEBUG] 의사 목록 로딩 완료: ${doctors.length}명');
      // ignore: avoid_print
      print('[DEBUG] 의사 데이터 구조: ${doctors.isNotEmpty ? doctors.first : "없음"}');
      setState(() {
        allDoctors = doctors;
      });
    } catch (e) {
      // ignore: avoid_print
      print('[ERROR] 의사 목록 로딩 실패: $e');
      // 의사 목록은 선택사항이므로 에러 무시
    }
  }

  /// 역할 변환 함수 (API role → 한국어)
  String _getRoleText(String? role) {
    switch (role) {
      case 'general':
        return '일반';
      case 'patient':
        return '환자';
      case 'doctor':
        return '의사';
      case 'staff':
        return '원무과';
      case 'admin':
        return '관리자';
      default:
        return role ?? '일반';
    }
  }

  /// 역할 변환 함수 (한국어 → API role)
  String? _getRoleValue(String roleText) {
    switch (roleText) {
      case '일반':
        return 'general';
      case '환자':
        return 'patient';
      case '의사':
        return 'doctor';
      case '원무과':
        return 'staff';
      case '관리자':
        return 'admin';
      default:
        return null;
    }
  }

  List<Map<String, dynamic>> get _filteredUsers {
    return allUsers.where((user) {
      final username = user['username'] ?? '';
      final email = user['email'] ?? '';
      final matchesSearch =
          username.toLowerCase().contains(searchQuery.toLowerCase()) ||
          email.toLowerCase().contains(searchQuery.toLowerCase());

      final userRole = _getRoleText(user['role']);
      final matchesRole = selectedRole == '전체' || userRole == selectedRole;
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
      child: SingleChildScrollView(
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
                        items: ['전체', '일반', '환자', '의사', '원무과', '관리자']
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

            // 사용자 목록 (ListView.builder를 Column children으로 변경)
            _isLoading
                ? const Padding(
                    padding: EdgeInsets.only(top: 40.0),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _paginatedUsers.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.only(top: 40.0),
                        child: Center(child: Text('회원이 없습니다.')),
                      )
                    : Column(
                        children: _paginatedUsers.map((user) {
                          final roleText = _getRoleText(user['role']);
                          final username = user['username'] ?? '';
                          final email = user['email'] ?? '';
                          final isGeneral = user['role'] == 'general';

                          return Card(
                            margin: EdgeInsets.symmetric(vertical: 8),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              title: Text("$username ($roleText)"),
                              subtitle: Text(email),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // 일반 회원인 경우 환자 승인 버튼 표시
                                  if (isGeneral)
                                    IconButton(
                                      icon: Icon(Icons.person_add, color: Colors.blue),
                                      tooltip: '환자 승인',
                                      onPressed: () {
                                        _showApprovalDialog(context, user);
                                      },
                                    ),
                                  IconButton(
                                    icon: Icon(Icons.info_outline, color: Colors.grey),
                                    tooltip: '상세 정보',
                                    onPressed: () => _showUserDetail(context, user),
                                  ),
                                ],
                              ),
                              onTap: () => _showUserDetail(context, user),
                            ),
                          );
                        }).toList(),
                      ),

            // 페이지네이션 컨트롤
            if (_filteredUsers.length > _itemsPerPage)
              Container(
                margin: const EdgeInsets.only(top: 16, bottom: 16),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.2),
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

  /// 환자 승인 다이얼로그 (담당 의사 선택)
  void _showApprovalDialog(BuildContext context, Map<String, dynamic> user) {
    final List<int> selectedDoctorIds = [];
    bool isProcessing = false;

    showDialog(
      context: context,
      barrierDismissible: false, // 처리 중에는 다이얼로그 밖 클릭 방지
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text("${user['username']} 님을 환자로 승인"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("담당 의사를 선택해주세요 (필수):"),
                  SizedBox(height: 12),
                  if (allDoctors.isEmpty)
                    Text("등록된 의사가 없습니다.", style: TextStyle(color: Colors.red))
                  else
                    ...allDoctors.map((doctor) {
                      final doctorId = doctor['id'] as int;

                      // user 필드에서 username 안전하게 추출
                      String doctorName = '알 수 없음';
                      if (doctor['user'] != null) {
                        if (doctor['user'] is Map) {
                          doctorName = doctor['user']['username'] ?? '알 수 없음';
                        }
                      }

                      final licenseNumber = doctor['license_number']?.toString() ?? '';
                      final isSelected = selectedDoctorIds.contains(doctorId);

                      return CheckboxListTile(
                        title: Text(doctorName),
                        subtitle: Text("면허번호: $licenseNumber"),
                        value: isSelected,
                        enabled: !isProcessing,
                        onChanged: (bool? checked) {
                          setDialogState(() {
                            if (checked == true) {
                              selectedDoctorIds.add(doctorId);
                            } else {
                              selectedDoctorIds.remove(doctorId);
                            }
                          });
                        },
                      );
                    }),
                  if (isProcessing)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text("승인 처리 중...", style: TextStyle(color: Colors.blue)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isProcessing ? null : () => Navigator.pop(dialogContext),
                child: Text('취소'),
              ),
              ElevatedButton(
                onPressed: (selectedDoctorIds.isEmpty || isProcessing)
                    ? null
                    : () async {
                        setDialogState(() {
                          isProcessing = true;
                        });

                        await _approveAsPatient(user['id'], selectedDoctorIds);

                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                        }
                      },
                child: Text(isProcessing ? '처리 중...' : '승인'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 환자 승인 API 호출
  Future<void> _approveAsPatient(int userId, List<int> doctorIds) async {
    try {
      print('[DEBUG] 환자 승인 시작 - userId: $userId, doctorIds: $doctorIds');

      final response = await _userService.changeRole(
        userId: userId,
        role: 'patient',
        patientPayload: {
          'assigned_doctor_ids': doctorIds,
        },
      );

      print('[DEBUG] 승인 응답 - success: ${response.success}, statusCode: ${response.statusCode}');
      print('[DEBUG] 응답 데이터: ${response.data}');
      print('[DEBUG] 응답 메시지: ${response.message}');

      if (!mounted) return;

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('환자 승인이 완료되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );
        // 목록 새로고침
        _loadUsers();
      } else {
        // Django 에러 응답 처리: {"detail": "error message"}
        String errorMsg = '승인 실패';

        if (response.data != null && response.data is Map) {
          final detail = response.data['detail'];
          if (detail != null) {
            errorMsg = '승인 실패: $detail';
          }
        } else if (response.message != null) {
          errorMsg = '승인 실패: ${response.message}';
        }

        if (response.statusCode != null) {
          errorMsg += ' (상태코드: ${response.statusCode})';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e, stackTrace) {
      print('[ERROR] 승인 중 예외 발생: $e');
      print('[ERROR] 스택 트레이스: $stackTrace');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('승인 중 오류 발생: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  void _showUserDetail(BuildContext context, Map<String, dynamic> user) {
    final roleText = _getRoleText(user['role']);
    final username = user['username'] ?? '';
    final email = user['email'] ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("$username 상세 정보"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("사용자명: $username"),
            SizedBox(height: 8),
            Text("이메일: $email"),
            SizedBox(height: 8),
            Text("역할: $roleText"),
            SizedBox(height: 8),
            Text("ID: ${user['id']}"),
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
