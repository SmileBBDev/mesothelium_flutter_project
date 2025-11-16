// 의사용 간단한 진료 문서 작성 페이지
import 'package:flutter/material.dart';
import '../../core/service/prescription_service.dart';
import '../../core/service/auth_service.dart';

class MedicalDocumentEditor extends StatefulWidget {
  final int patientId;
  final String patientName;
  final String patientInfo;
  final int? recordId; // 기존 기록 수정 시 전달
  final AuthUser? user; // 의사 정보

  const MedicalDocumentEditor({
    super.key,
    required this.patientId,
    required this.patientName,
    required this.patientInfo,
    this.recordId,
    this.user,
  });

  @override
  State<MedicalDocumentEditor> createState() => _MedicalDocumentEditorState();
}

class _MedicalDocumentEditorState extends State<MedicalDocumentEditor> {
  final PrescriptionService _service = PrescriptionService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  Future<void> _loadDocument() async {
    if (widget.recordId == null) {
      // 새 문서 작성
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // 기존 문서 불러오기
    final record = await _service.getPrescriptionDetail(widget.recordId!);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (record != null) {
        _titleController.text = record['title'] ?? '';
        _contentController.text = record['content_delta'] ?? '';
      } else {
        _showSnackBar('문서 로드 실패', isError: true);
      }
    }
  }

  Future<void> _saveDocument() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (content.isEmpty) {
      _showSnackBar('내용을 입력해주세요', isError: true);
      return;
    }

    // 의사 ID 확인
    final doctorId = widget.user?.doctorId;
    if (doctorId == null) {
      _showSnackBar('의사 정보를 찾을 수 없습니다', isError: true);
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      if (widget.recordId == null) {
        // 새 기록 생성
        final response = await _service.createPrescription(
          patientId: widget.patientId,
          doctorId: doctorId,
          title: title.isNotEmpty
              ? title
              : '진료 기록 ${DateTime.now().toString().substring(0, 10)}',
          contentDelta: content,
        );

        if (mounted) {
          setState(() {
            _isSaving = false;
          });

          if (response.success) {
            _showSnackBar('진료 문서가 저장되었습니다.');
            Navigator.pop(context, true);
          } else {
            _showSnackBar(response.message ?? '저장 실패', isError: true);
          }
        }
      } else {
        // 기존 기록 수정
        final response = await _service.updatePrescription(
          prescriptionId: widget.recordId!,
          title: title.isNotEmpty ? title : null,
          contentDelta: content,
        );

        if (mounted) {
          setState(() {
            _isSaving = false;
          });

          if (response.success) {
            _showSnackBar('진료 문서가 수정되었습니다.');
            Navigator.pop(context, true);
          } else {
            _showSnackBar(response.message ?? '수정 실패', isError: true);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        _showSnackBar('저장 중 오류 발생: $e', isError: true);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
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
        appBar: AppBar(title: const Text('진료 문서 작성')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '진료 문서 작성',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              widget.patientInfo,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
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
            onPressed: _isSaving ? null : _saveDocument,
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
              // 제목 입력
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: '제목',
                  hintText: '제목을 입력하세요 (선택사항)',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                ),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // 내용 입력
              const Text(
                '진료 내용',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _contentController,
                maxLines: 15,
                decoration: const InputDecoration(
                  hintText: '진료 내용을 입력하세요...\n\n예시:\n- 주소: 복부 통증\n- 진단: 급성 위염\n- 처방: 제산제 복용\n- 추가 소견: ...',
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
                  border: Border.all(color: Colors.blue[200]!),
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
                      '• 환자의 증상, 진단 결과, 처방 내용을 명확히 기록하세요.\n'
                      '• 추후 참고를 위해 상세히 작성하는 것이 좋습니다.\n'
                      '• 저장된 문서는 환자의 진료 이력에 기록됩니다.',
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
          onPressed: _isSaving ? null : _saveDocument,
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
              : const Text(
                  '진료 문서 저장',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
        ),
      ),
    );
  }
}
