// 원무과: 환자 관리 및 담당 의사 배정 페이지
import 'package:flutter/material.dart';
import '../../core/service/patient_service.dart';
import '../../core/service/doctor_service.dart';

class PatientManagementList extends StatefulWidget {
  const PatientManagementList({super.key});

  @override
  State<PatientManagementList> createState() => _PatientManagementListState();
}

class _PatientManagementListState extends State<PatientManagementList> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _allPatients = [];
  List<Map<String, dynamic>> _filteredPatients = [];
  List<Map<String, dynamic>> _doctors = [];
  bool _isLoading = true;
  String? _errorMessage;

  // 페이지네이션
  int _currentPage = 0;
  final int _itemsPerPage = 10;

  int get _totalPages => (_filteredPatients.length / _itemsPerPage).ceil().clamp(1, 9999);

  List<Map<String, dynamic>> get _paginatedPatients {
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, _filteredPatients.length);
    if (startIndex >= _filteredPatients.length) return [];
    return _filteredPatients.sublist(startIndex, endIndex);
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // 환자 목록과 의사 목록을 동시에 가져오기
    final patientsResult = await PatientService().getAllPatients();
    final doctorsResult = await DoctorService().getDoctors();

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (patientsResult.success && patientsResult.patients != null) {
          _allPatients = patientsResult.patients!;
          _filteredPatients = _allPatients;

          // DEBUG: 환자 데이터 확인
          print('[환자목록] 총 환자 수: ${_allPatients.length}');
          if (_allPatients.isNotEmpty) {
            print('[환자목록] 첫 번째 환자 데이터: ${_allPatients.first}');
            // assigned_doctors 필드 상세 확인
            if (_allPatients.first.containsKey('assigned_doctors')) {
              print('[환자목록] assigned_doctors 타입: ${_allPatients.first['assigned_doctors'].runtimeType}');
              print('[환자목록] assigned_doctors 값: ${_allPatients.first['assigned_doctors']}');
            }
            if (_allPatients.first.containsKey('assigned_doctors_info')) {
              print('[환자목록] assigned_doctors_info: ${_allPatients.first['assigned_doctors_info']}');
            }
          }
        } else {
          _errorMessage = patientsResult.message ?? '환자 목록을 불러올 수 없습니다.';
        }

        if (doctorsResult.success && doctorsResult.doctors != null) {
          _doctors = doctorsResult.doctors!;
          print('[환자목록] 총 의사 수: ${_doctors.length}');
        }
      });
    }
  }

  void _searchPatients(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredPatients = _allPatients;
      } else {
        _filteredPatients = _allPatients.where((patient) {
          final name = patient['name']?.toString().toLowerCase() ?? '';
          final id = patient['id']?.toString() ?? '';
          final searchQuery = query.toLowerCase();
          return name.contains(searchQuery) || id.contains(searchQuery);
        }).toList();
      }
      _currentPage = 0; // 검색 시 첫 페이지로
    });
  }

  void _goToPage(int page) {
    setState(() {
      _currentPage = page.clamp(0, _totalPages - 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // 검색창
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: '환자 이름 또는 ID 검색',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
            onChanged: _searchPatients,
          ),
        ),

        // 페이지 정보
        if (_filteredPatients.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '총 ${_filteredPatients.length}명',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${_currentPage + 1} / $_totalPages 페이지',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

        // 환자 목록
        Expanded(
          child: _paginatedPatients.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_off, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        '등록된 환자가 없습니다',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _paginatedPatients.length,
                    itemBuilder: (context, index) {
                      final patient = _paginatedPatients[index];
                      final name = patient['name']?.toString() ?? '이름 없음';
                      final id = patient['id']?.toString() ?? '';
                      final phone = patient['phone']?.toString() ?? '전화번호 없음';

                      // 담당 의사 목록 처리
                      final assignedDoctors = patient['assigned_doctors'] as List?;
                      String doctorNames = '미배정';
                      if (assignedDoctors != null && assignedDoctors.isNotEmpty) {
                        doctorNames = assignedDoctors.map((d) {
                          if (d is Map) {
                            return d['user']?['username'] ?? d['user']?['first_name'] ?? '의사';
                          }
                          return '의사';
                        }).join(', ');
                      }

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
                                    backgroundColor: Colors.green[100],
                                    child: Text(
                                      name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'ID: $id',
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
                                      color: Colors.green[100],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      '활성',
                                      style: TextStyle(
                                        color: Colors.green,
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
                                  Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                                  const SizedBox(width: 8),
                                  Text(
                                    phone,
                                    style: TextStyle(color: Colors.grey[700]),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.medical_services, size: 16, color: Colors.grey[600]),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '담당 의사: $doctorNames',
                                      style: TextStyle(
                                        color: Colors.grey[700],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () => _showChangeDoctorDialog(patient),
                                  icon: const Icon(Icons.person_add),
                                  label: const Text('담당 의사 변경'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),

        // 페이지네이션 컨트롤
        if (_filteredPatients.isNotEmpty && _totalPages > 1)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, -1),
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
                const SizedBox(width: 8),
                ..._buildPageButtons(),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _currentPage < _totalPages - 1
                      ? () => _goToPage(_currentPage + 1)
                      : null,
                  icon: const Icon(Icons.chevron_right),
                  tooltip: '다음 페이지',
                ),
              ],
            ),
          ),
      ],
    );
  }

  List<Widget> _buildPageButtons() {
    final List<Widget> buttons = [];
    final int maxButtons = 5;
    int startPage, endPage;

    if (_totalPages <= maxButtons) {
      startPage = 0;
      endPage = _totalPages - 1;
    } else if (_currentPage < 2) {
      startPage = 0;
      endPage = maxButtons - 1;
    } else if (_currentPage >= _totalPages - 3) {
      startPage = _totalPages - maxButtons;
      endPage = _totalPages - 1;
    } else {
      startPage = _currentPage - 2;
      endPage = _currentPage + 2;
    }

    for (int i = startPage; i <= endPage; i++) {
      buttons.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Material(
            color: _currentPage == i ? Colors.blue : Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: () => _goToPage(i),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                child: Text(
                  '${i + 1}',
                  style: TextStyle(
                    color: _currentPage == i ? Colors.white : Colors.black87,
                    fontWeight: _currentPage == i ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return buttons;
  }

  void _showChangeDoctorDialog(Map<String, dynamic> patient) {
    final patientId = patient['id'] as int;
    final patientName = patient['name']?.toString() ?? '환자';

    // 현재 담당 의사 ID 목록
    // API 응답에서는 'assigned_doctors_info'로 담당의사 정보가 옴
    final assignedDoctors = patient['assigned_doctors_info'] as List? ?? patient['assigned_doctors'] as List?;
    final currentDoctorIds = assignedDoctors?.map((d) {
      if (d is Map) return d['id'] as int?;
      return null;
    }).whereType<int>().toSet() ?? <int>{};

    // DEBUG: 데이터 구조 확인
    print('[담당의사변경] 환자 ID: $patientId, 이름: $patientName');
    print('[담당의사변경] assigned_doctors 원본: $assignedDoctors');
    print('[담당의사변경] currentDoctorIds: $currentDoctorIds');
    print('[담당의사변경] 전체 의사 수: ${_doctors.length}');

    // 현재 담당의사와 그 외 의사를 분리
    final currentDoctors = <Map<String, dynamic>>[];
    final otherDoctors = <Map<String, dynamic>>[];

    for (final doctor in _doctors) {
      final doctorId = doctor['id'] as int;
      if (currentDoctorIds.contains(doctorId)) {
        currentDoctors.add(doctor);
      } else {
        otherDoctors.add(doctor);
      }
    }

    // DEBUG: 분류 결과 확인
    print('[담당의사변경] 현재 담당의사 수: ${currentDoctors.length}');
    print('[담당의사변경] 다른 의사 수: ${otherDoctors.length}');
    if (currentDoctors.isNotEmpty) {
      print('[담당의사변경] 현재 담당의사 목록: ${currentDoctors.map((d) => d['id']).toList()}');
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$patientName 환자의 담당 의사 변경'),
        content: SizedBox(
          width: double.maxFinite,
          child: _doctors.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('등록된 의사가 없습니다'),
                )
              : ListView(
                  shrinkWrap: true,
                  children: [
                    // 현재 담당의사 섹션
                    if (currentDoctors.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            '현재 담당의사',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...currentDoctors.map((doctor) => _buildDoctorTile(
                        doctor,
                        patientId,
                        currentDoctorIds,
                        isCurrentDoctor: true,
                      )),
                      const SizedBox(height: 16),
                    ],

                    // 기타 의사 섹션
                    if (otherDoctors.isNotEmpty) ...[
                      if (currentDoctors.isNotEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Text(
                            '다른 의사',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ...otherDoctors.map((doctor) => _buildDoctorTile(
                        doctor,
                        patientId,
                        currentDoctorIds,
                        isCurrentDoctor: false,
                      )),
                    ],
                  ],
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorTile(
    Map<String, dynamic> doctor,
    int patientId,
    Set<int> currentDoctorIds, {
    required bool isCurrentDoctor,
  }) {
    final doctorId = doctor['id'] as int;
    final doctorName = doctor['user']?['username']?.toString() ??
                      doctor['user']?['first_name']?.toString() ?? '의사';
    final department = doctor['department']?.toString() ?? '진료과 미지정';

    return Card(
      elevation: isCurrentDoctor ? 3 : 1,
      color: isCurrentDoctor ? Colors.blue[50] : null,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isCurrentDoctor ? Colors.blue[300] : Colors.blue[100],
          child: Text(
            doctorName.isNotEmpty ? doctorName.substring(0, 1).toUpperCase() : '?',
            style: TextStyle(
              fontWeight: isCurrentDoctor ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        title: Text(
          doctorName,
          style: TextStyle(
            fontWeight: isCurrentDoctor ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(department),
        trailing: isCurrentDoctor
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, color: Colors.blue),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.remove_circle, color: Colors.red),
                    onPressed: () {
                      Navigator.pop(context);
                      _changeDoctor(patientId, doctorId, doctorName, currentDoctorIds);
                    },
                    tooltip: '제거',
                  ),
                ],
              )
            : IconButton(
                icon: const Icon(Icons.add_circle, color: Colors.green),
                onPressed: () {
                  Navigator.pop(context);
                  _changeDoctor(patientId, doctorId, doctorName, currentDoctorIds);
                },
                tooltip: '추가',
              ),
      ),
    );
  }

  Future<void> _changeDoctor(
    int patientId,
    int doctorId,
    String doctorName,
    Set<int> currentDoctorIds,
  ) async {
    // 이미 선택된 의사를 다시 선택하면 제거, 아니면 추가
    final newDoctorIds = Set<int>.from(currentDoctorIds);
    final isRemoving = newDoctorIds.contains(doctorId);

    if (isRemoving) {
      newDoctorIds.remove(doctorId);
    } else {
      newDoctorIds.add(doctorId);
    }

    // API 호출로 담당 의사 업데이트
    final result = await PatientService().updatePatient(
      patientId: patientId,
      assignedDoctors: newDoctorIds.toList(),
    );

    if (mounted) {
      if (result.success) {
        // 성공 시 목록 새로고침
        await _loadData();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isRemoving
                  ? '담당 의사 $doctorName이(가) 제거되었습니다'
                  : '담당 의사가 $doctorName(으)로 추가되었습니다',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? '담당 의사 변경에 실패했습니다'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
