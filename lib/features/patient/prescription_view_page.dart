// 환자용 처방전 조회 페이지 (읽기 전용)
import 'package:flutter/material.dart';
import '../../core/service/prescription_service.dart';
import '../../core/service/auth_service.dart';

class PrescriptionViewPage extends StatefulWidget {
  const PrescriptionViewPage({super.key});

  @override
  State<PrescriptionViewPage> createState() => _PrescriptionViewPageState();
}

class _PrescriptionViewPageState extends State<PrescriptionViewPage> {
  final PrescriptionService _prescriptionService = PrescriptionService();
  final AuthService _authService = AuthService();

  List<Map<String, dynamic>> _prescriptions = [];
  bool _isLoading = true;
  String? _errorMessage;

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

      // 환자별 처방전 조회
      final result = await _prescriptionService.getPrescriptionsByPatient(user.userId!);

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

  void _showPrescriptionDetail(Map<String, dynamic> prescription) {
    final title = prescription['title'] ?? '제목 없음';
    final content = prescription['content_delta'] ?? '';
    final createdAt = prescription['created_at'];
    final doctorData = prescription['doctor'] as Map<String, dynamic>?;

    String doctorName = '의사 정보 없음';
    if (doctorData != null) {
      final userData = doctorData['user'] as Map<String, dynamic>?;
      if (userData != null) {
        doctorName = userData['username'] ?? '의사 정보 없음';
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.medical_services, color: Colors.blue),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 의사 정보
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '담당 의사',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(doctorName),
                    if (createdAt != null)
                      Text(
                        '처방 일시: ${_formatDateTime(createdAt)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 처방 내용
              const Text(
                '처방 내용',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Text(
                  content.isNotEmpty ? content : '처방 내용 없음',
                  style: const TextStyle(fontSize: 14, height: 1.5),
                ),
              ),
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

  String _formatDateTime(String dateTimeStr) {
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
        title: const Text('내 처방전'),
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
                          const Text('처방전이 없습니다.', style: TextStyle(fontSize: 16)),
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
                          final doctorData = prescription['doctor'] as Map<String, dynamic>?;

                          String doctorName = '의사 정보 없음';
                          if (doctorData != null) {
                            final userData = doctorData['user'] as Map<String, dynamic>?;
                            if (userData != null) {
                              doctorName = userData['username'] ?? '의사 정보 없음';
                            }
                          }

                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              onTap: () => _showPrescriptionDetail(prescription),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const CircleAvatar(
                                          backgroundColor: Colors.blue,
                                          child: Icon(Icons.medical_services, color: Colors.white, size: 20),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                title,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '담당 의사: $doctorName',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey[700],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    const Divider(),
                                    const SizedBox(height: 4),
                                    if (createdAt != null)
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
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
