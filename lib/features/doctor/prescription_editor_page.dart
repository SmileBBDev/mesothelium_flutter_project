// 의사용 처방전 작성/수정 페이지
import 'package:flutter/material.dart';
import '../../core/service/prescription_service.dart';

class PrescriptionEditorPage extends StatefulWidget {
  final int? prescriptionId; // null이면 새 처방전 작성
  final int? patientId;
  final int? doctorId;
  final Map<String, dynamic>? patientInfo;

  const PrescriptionEditorPage({
    super.key,
    this.prescriptionId,
    this.patientId,
    this.doctorId,
    this.patientInfo,
  });

  @override
  State<PrescriptionEditorPage> createState() => _PrescriptionEditorPageState();
}

class _PrescriptionEditorPageState extends State<PrescriptionEditorPage> {
  final PrescriptionService _prescriptionService = PrescriptionService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  bool _isLoading = false;
  bool _isSaving = false;
  Map<String, dynamic>? _patientInfo;

  @override
  void initState() {
    super.initState();
    if (widget.prescriptionId != null) {
      _loadPrescription();
    } else if (widget.patientInfo != null) {
      // 새 처방전 작성 시, 환자 정보 설정
      _patientInfo = widget.patientInfo;
    }
  }

  Future<void> _loadPrescription() async {
    setState(() => _isLoading = true);

    final result = await _prescriptionService.getPrescription(widget.prescriptionId!);

    if (mounted) {
      setState(() => _isLoading = false);

      if (result.success && result.prescription != null) {
        final prescription = result.prescription!;
        _titleController.text = prescription['title'] ?? '';
        _contentController.text = prescription['content_delta'] ?? '';

        // 환자 정보도 로드
        final patientData = prescription['patient'];
        if (patientData != null && patientData is Map<String, dynamic>) {
          setState(() {
            _patientInfo = patientData;
          });
        }
      } else {
        _showSnackBar(result.message ?? '처방전을 불러오는데 실패했습니다', isError: true);
      }
    }
  }

  Future<void> _savePrescription() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty) {
      _showSnackBar('제목을 입력해주세요', isError: true);
      return;
    }

    if (content.isEmpty) {
      _showSnackBar('처방 내용을 입력해주세요', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      PrescriptionResult result;

      if (widget.prescriptionId == null) {
        // 새 처방전 생성
        result = await _prescriptionService.createPrescription(
          title: title,
          contentDelta: content,
          patientId: widget.patientId,
          doctorId: widget.doctorId,
        );
      } else {
        // 기존 처방전 수정
        result = await _prescriptionService.updatePrescription(
          prescriptionId: widget.prescriptionId!,
          title: title,
          contentDelta: content,
        );
      }

      if (mounted) {
        setState(() => _isSaving = false);

        if (result.success) {
          _showSnackBar(result.message ?? '처방전이 저장되었습니다.');
          Navigator.pop(context, true);
        } else {
          _showSnackBar(result.message ?? '저장 실패', isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        _showSnackBar('저장 중 오류 발생: $e', isError: true);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('처방전 작성'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.prescriptionId == null ? '처방전 작성' : '처방전 수정'),
        actions: [
          IconButton(
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.save),
            onPressed: _isSaving ? null : _savePrescription,
            tooltip: '저장',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 환자 정보 카드
              if (_patientInfo != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.blue,
                        child: Text(
                          (_patientInfo!['name'] ?? _patientInfo!['username'] ?? '?')[0].toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.person, size: 16, color: Colors.blue),
                                const SizedBox(width: 4),
                                Text(
                                  '환자: ${_patientInfo!['name'] ?? _patientInfo!['username'] ?? '이름 없음'}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            if (_patientInfo!['email'] != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                _patientInfo!['email'],
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              // 제목 입력
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: '제목 *',
                  hintText: '처방전 제목을 입력하세요',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                ),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // 내용 입력
              const Text(
                '처방 내용 *',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _contentController,
                maxLines: 15,
                decoration: const InputDecoration(
                  hintText: '처방 내용을 입력하세요...\n\n예시:\n- 약물명: 타이레놀 500mg\n- 용법: 1일 3회, 식후 30분\n- 기간: 7일\n- 주의사항: ...',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.all(16),
                ),
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 20),

              // 작성 안내
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue, size: 20),
                        SizedBox(width: 8),
                        Text(
                          '작성 팁',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• 약물명, 용법, 용량, 기간을 명확히 기록하세요.\n'
                      '• 환자가 이해하기 쉽게 작성하는 것이 좋습니다.\n'
                      '• 저장된 처방전은 환자도 조회할 수 있습니다.',
                      style: TextStyle(fontSize: 13, height: 1.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isSaving ? null : _savePrescription,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _isSaving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  widget.prescriptionId == null ? '처방전 작성' : '처방전 수정',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
        ),
      ),
    );
  }
}
