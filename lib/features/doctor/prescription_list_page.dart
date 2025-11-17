// 의사용 처방전 목록 페이지 (CRUD)
import 'package:flutter/material.dart';
import '../../core/service/prescription_service.dart';
import '../../core/service/auth_service.dart';
import '../../core/service/patient_service.dart';
import 'prescription_editor_page.dart';

class PrescriptionListPage extends StatefulWidget {
  const PrescriptionListPage({super.key});

  @override
  State<PrescriptionListPage> createState() => _PrescriptionListPageState();
}

class _PrescriptionListPageState extends State<PrescriptionListPage> {
  final PrescriptionService _prescriptionService = PrescriptionService();
  final AuthService _authService = AuthService();
  final PatientService _patientService = PatientService();

  List<Map<String, dynamic>> _prescriptions = [];
  bool _isLoading = true;
  String? _errorMessage;
  int? _currentDoctorId;

  @override
  void initState() {
    super.initState();
    _loadPrescriptions();
  }

  Future<void> _loadPrescriptions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await _authService.loadFromStorage();

      if (user == null || user.userId == null) {
        setState(() {
          _errorMessage = '로그인이 필요합니다.';
          _isLoading = false;
        });
        return;
      }

      _currentDoctorId = user.userId;

      // 의사별 처방전 조회
      final result = await _prescriptionService.getPrescriptionsByDoctor(user.userId!);

      if (result.success && result.prescriptions != null) {
        setState(() {
          _prescriptions = result.prescriptions!;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result.message ?? '처방전을 불러오는데 실패했습니다.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '오류가 발생했습니다: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _deletePrescription(int prescriptionId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('처방전 삭제'),
        content: const Text('이 처방전을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final result = await _prescriptionService.deletePrescription(prescriptionId);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? (result.success ? '삭제되었습니다' : '삭제 실패')),
          backgroundColor: result.success ? Colors.green : Colors.red,
        ),
      );

      if (result.success) {
        _loadPrescriptions();
      }
    }
  }

  void _navigateToEditor({int? prescriptionId, int? patientId, Map<String, dynamic>? patientInfo}) async {
    int? selectedPatientId = patientId;
    Map<String, dynamic>? selectedPatientInfo = patientInfo;

    // 새 처방전 작성 시 환자 선택
    if (prescriptionId == null && patientId == null) {
      final result = await _showPatientSelectionDialog();
      if (result == null) {
        // 환자 선택 취소
        return;
      }
      selectedPatientId = result['id'];
      selectedPatientInfo = result;
    }

    if (!mounted) return;

    final navigateResult = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => PrescriptionEditorPage(
          prescriptionId: prescriptionId,
          patientId: selectedPatientId,
          doctorId: _currentDoctorId,
          patientInfo: selectedPatientInfo,
        ),
      ),
    );

    if (navigateResult == true) {
      _loadPrescriptions();
    }
  }

  Future<Map<String, dynamic>?> _showPatientSelectionDialog() async {
    // 환자 목록 불러오기
    final result = await _patientService.getAllPatients();

    if (!result.success || result.patients == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? '환자 목록을 불러올 수 없습니다.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }

    final patients = result.patients!;

    if (patients.isEmpty) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('등록된 환자가 없습니다.'),
          backgroundColor: Colors.orange,
        ),
      );
      return null;
    }

    return await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('환자 선택'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: patients.length,
            itemBuilder: (context, index) {
              final patient = patients[index];
              final name = patient['name'] ?? patient['username'] ?? '이름 없음';
              final email = patient['email'] ?? '';

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(name),
                subtitle: email.isNotEmpty ? Text(email) : null,
                onTap: () => Navigator.pop(context, patient),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('취소'),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null) return 'N/A';
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('처방전 관리'),
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPrescriptions,
            tooltip: '새로고침',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(_errorMessage!, style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loadPrescriptions,
                        icon: const Icon(Icons.refresh),
                        label: const Text('다시 시도'),
                      ),
                    ],
                  ),
                )
              : _prescriptions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.medical_services_outlined, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          const Text('작성한 처방전이 없습니다.', style: TextStyle(fontSize: 16)),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () => _navigateToEditor(),
                            icon: const Icon(Icons.add),
                            label: const Text('처방전 작성하기'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadPrescriptions,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _prescriptions.length,
                        itemBuilder: (context, index) {
                          final prescription = _prescriptions[index];
                          final title = prescription['title'] ?? '제목 없음';
                          final createdAt = prescription['created_at'];
                          final patientData = prescription['patient'] as Map<String, dynamic>?;
                          final patientName = patientData?['name'] ?? '환자 정보 없음';
                          final prescriptionId = prescription['id'];

                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Colors.blue,
                                child: Icon(Icons.medical_services, color: Colors.white),
                              ),
                              title: Text(
                                title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.person_outline, size: 14, color: Colors.grey[600]),
                                      const SizedBox(width: 4),
                                      Text(
                                        patientName,
                                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                                      const SizedBox(width: 4),
                                      Text(
                                        _formatDateTime(createdAt),
                                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: PopupMenuButton(
                                icon: const Icon(Icons.more_vert),
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit, size: 20),
                                        SizedBox(width: 8),
                                        Text('수정'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete, size: 20, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('삭제', style: TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ],
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _navigateToEditor(prescriptionId: prescriptionId);
                                  } else if (value == 'delete') {
                                    _deletePrescription(prescriptionId);
                                  }
                                },
                              ),
                              onTap: () => _navigateToEditor(prescriptionId: prescriptionId),
                            ),
                          );
                        },
                      ),
                    ),
      floatingActionButton: _prescriptions.isNotEmpty
          ? FloatingActionButton(
              onPressed: () => _navigateToEditor(),
              backgroundColor: Colors.blue,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}
