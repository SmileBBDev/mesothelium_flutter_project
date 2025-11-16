// 원무과: 일반 사용자 승인 페이지 (역할별 승인 처리)
import 'package:flutter/material.dart';
import '../../core/service/user_management_service.dart';
import '../../core/service/user_service.dart';
import '../../core/service/doctor_service.dart';

class UserApprovalList extends StatefulWidget {
  const UserApprovalList({super.key});

  @override
  State<UserApprovalList> createState() => _UserApprovalListState();
}

class _UserApprovalListState extends State<UserApprovalList> {
  final _userManagementService = UserManagementService();

  // 데이터 상태
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _allUsers = [];

  // 페이지네이션 상태
  int _currentPage = 0;
  final int _itemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _userManagementService.getPendingUsers();

      if (mounted) {
        setState(() {
          _isLoading = false;
          if (result.success && result.users != null) {
            _allUsers = result.users!;
          } else {
            _errorMessage = result.message ?? '데이터를 불러올 수 없습니다';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = '오류: $e';
        });
      }
    }
  }

  // 일반 사용자만 필터링 (의사, 관리자, 원무과 제외)
  List<Map<String, dynamic>> get _filteredUsers {
    return _allUsers.where((user) {
      final userRole = user['role']?.toString() ?? 'general';
      // general만 표시 (doctor, admin, staff 제외)
      return userRole == 'general';
    }).toList();
  }

  int get _totalPages => (_filteredUsers.length / _itemsPerPage).ceil().clamp(1, 9999);

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
    return Scaffold(
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _loadData,
                    icon: const Icon(Icons.refresh),
                    label: const Text('다시 시도'),
                  ),
                ],
              ),
            )
          : _filteredUsers.isEmpty
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
                    SizedBox(height: 16),
                    Text(
                      '승인 대기 중인 사용자가 없습니다',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  // 페이지 정보
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.grey[100],
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

                  // 사용자 목록
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _paginatedUsers.length,
                      itemBuilder: (context, index) {
                        final user = _paginatedUsers[index];
                        final userRole = user['role']?.toString() ?? 'general';

                        return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.blue[100],
                            child: Text(
                              (user['name'] != null && user['name'].toString().isNotEmpty)
                                  ? user['name'].toString().substring(0, 1).toUpperCase()
                                  : '?',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user['name']?.toString() ?? user['username']?.toString() ?? '이름 없음',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'ID: ${user['id']} | 역할: ${_getRoleLabel(userRole)}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              '승인 대기',
                              style: TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.email, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Text(
                            user['email'] ?? '이메일 없음',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Text(
                            user['phone'] ?? '전화번호 없음',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // general은 환자로 승인 가능
                      userRole == 'general'
                        ? Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _approveAsPatient(user),
                                  icon: const Icon(Icons.person_add),
                                  label: const Text('환자로 승인'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _rejectUser(user['id'] as int),
                                  icon: const Icon(Icons.delete),
                                  label: const Text('삭제'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _approveUser(user),
                                  icon: const Icon(Icons.check),
                                  label: Text(_getApprovalButtonLabel(userRole)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _rejectUser(user['id'] as int),
                                  icon: const Icon(Icons.close),
                                  label: const Text('거부'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
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

        // 페이지네이션 컨트롤
        if (_filteredUsers.length > _itemsPerPage)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.2),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, -3),
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

  String _getRoleLabel(String role) {
    switch (role) {
      case 'patient':
        return '환자';
      case 'doctor':
        return '의사';
      case 'staff':
        return '직원';
      default:
        return '일반';
    }
  }

  String _getApprovalButtonLabel(String role) {
    switch (role) {
      case 'patient':
        return '환자로 승인';
      case 'doctor':
        return '의사로 승인';
      case 'staff':
        return '직원으로 승인';
      default:
        return '일반 회원 승인';
    }
  }

  Future<void> _approveUser(Map<String, dynamic> user) async {
    final userId = user['id'] as int;
    final userName = user['name']?.toString() ?? user['username']?.toString() ?? '사용자';
    final userRole = user['role']?.toString() ?? 'general';

    final result = await _userManagementService.approveUser(userId);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.success
          ? '$userName님이 ${_getRoleLabel(userRole)}(으)로 승인되었습니다'
          : '승인 실패: ${result.message}'),
        backgroundColor: result.success ? Colors.green : Colors.red,
      ),
    );

    if (result.success) {
      await _loadData();
    }
  }

  Future<void> _approveAsPatient(Map<String, dynamic> user) async {
    final userId = user['id'] as int;
    final userName = user['name']?.toString() ?? user['username']?.toString() ?? '사용자';

    // 의사 목록 로드
    final doctorService = DoctorService();
    final doctorsResult = await doctorService.getDoctors();

    if (!doctorsResult.success || doctorsResult.doctors == null || doctorsResult.doctors!.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('의사 목록을 불러올 수 없습니다'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final doctors = doctorsResult.doctors!;

    // 의사 선택 다이얼로그 표시
    if (!mounted) return;

    final selectedDoctorIds = <int>[];

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('$userName을(를) 환자로 승인'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '담당 의사를 선택하세요 (복수 선택 가능)',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: doctors.length,
                        itemBuilder: (context, index) {
                          final doctor = doctors[index];
                          final doctorId = doctor['id'] as int;
                          final doctorName = doctor['user']?['username'] ?? '알 수 없음';
                          final department = doctor['department']?.toString() ?? '';
                          final isSelected = selectedDoctorIds.contains(doctorId);

                          return CheckboxListTile(
                            title: Text(doctorName),
                            subtitle: Text(department.isNotEmpty ? '진료과: $department' : ''),
                            value: isSelected,
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
                        },
                      ),
                    ),
                    if (selectedDoctorIds.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '${selectedDoctorIds.length}명의 의사가 선택됨',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('취소'),
                ),
                ElevatedButton(
                  onPressed: selectedDoctorIds.isEmpty
                      ? null
                      : () async {
                          Navigator.pop(dialogContext);
                          await _performPatientApproval(userId, userName, selectedDoctorIds);
                        },
                  child: const Text('승인'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _performPatientApproval(int userId, String userName, List<int> doctorIds) async {
    try {
      final userService = UserService();

      // 사용자 상세 정보 조회
      String name = userName;
      String phone = '';

      try {
        final userDetail = await userService.getUserById(userId);
        if (userDetail.containsKey('name') && userDetail['name'] != null) {
          name = userDetail['name'];
        }
        if (userDetail.containsKey('phone') && userDetail['phone'] != null) {
          phone = userDetail['phone'];
        }
      } catch (e) {
        // 실패해도 username 사용
      }

      // Patient 생성
      final response = await userService.createPatient(
        name: name,
        phone: phone,
        assignedDoctorIds: doctorIds,
      );

      if (!mounted) return;

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$userName님이 환자로 등록되었습니다'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('환자 등록 실패: ${response.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('등록 중 오류 발생: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _rejectUser(int userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('승인 거부'),
        content: const Text('정말 이 사용자의 승인을 거부하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              final result = await _userManagementService.deleteUser(userId);

              if (!context.mounted) return;

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(result.success ? '승인이 거부되었습니다' : '거부 실패: ${result.message}'),
                  backgroundColor: result.success ? Colors.red : Colors.orange,
                ),
              );

              if (result.success && context.mounted) {
                await _loadData();
              }
            },
            child: const Text('거부', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
