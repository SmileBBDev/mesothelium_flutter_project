// 의사용 진료 문서 작성 페이지 (flutter_quill 사용 + Django API 연동)
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import '../../core/service/medical_record_service.dart';

class MedicalDocumentEditor extends StatefulWidget {
  final int patientId;
  final String patientName;
  final String patientInfo;
  final int? recordId; // 기존 기록 수정 시 전달

  const MedicalDocumentEditor({
    super.key,
    required this.patientId,
    required this.patientName,
    required this.patientInfo,
    this.recordId,
  });

  @override
  State<MedicalDocumentEditor> createState() => _MedicalDocumentEditorState();
}

class _MedicalDocumentEditorState extends State<MedicalDocumentEditor> {
  late QuillController _controller;
  final FocusNode _focusNode = FocusNode();
  final MedicalRecordService _service = MedicalRecordService();
  final TextEditingController _titleController = TextEditingController();

  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller = QuillController.basic();
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
    final result = await _service.getMedicalRecord(widget.recordId!);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (result.success && result.record != null) {
        final record = result.record!;
        _titleController.text = record['title'] ?? '';

        // Delta JSON 로드
        try {
          final deltaJson = record['content_delta_json'];
          if (deltaJson != null) {
            dynamic ops;

            // String 타입이면 파싱, Map 타입이면 그대로 사용
            if (deltaJson is String) {
              final parsed = jsonDecode(deltaJson);
              ops = parsed is Map ? parsed['ops'] : null;
            } else if (deltaJson is Map) {
              ops = deltaJson['ops'];
            }

            if (ops != null) {
              _controller = QuillController(
                document: Document.fromJson(ops),
                selection: const TextSelection.collapsed(offset: 0),
              );
            }
          }
        } catch (e) {
          print('Delta 로드 오류: $e');
        }
      } else {
        _showSnackBar(result.message ?? '문서 로드 실패', isError: true);
      }
    }
  }

  Future<void> _saveDocument() async {
    setState(() {
      _isSaving = true;
    });

    try {
      // Delta를 JSON으로 변환
      final delta = _controller.document.toDelta().toJson();
      final deltaMap = {'ops': delta};

      // 제목
      final title = _titleController.text.trim();

      // HTML 변환 (선택사항)
      final plainText = _controller.document.toPlainText();

      MedicalRecordResult result;

      if (widget.recordId == null) {
        // 새 기록 생성
        result = await _service.createMedicalRecord(
          patientId: widget.patientId,
          title: title.isNotEmpty
              ? title
              : '진료 기록 ${DateTime.now().toString().substring(0, 10)}',
          contentDeltaJson: deltaMap,
          contentHtml: plainText,
        );
      } else {
        // 기존 기록 수정
        result = await _service.updateMedicalRecord(
          recordId: widget.recordId!,
          title: title.isNotEmpty ? title : null,
          contentDeltaJson: deltaMap,
          contentHtml: plainText,
        );
      }

      if (mounted) {
        setState(() {
          _isSaving = false;
        });

        if (result.success) {
          _showSnackBar(result.message ?? '진료 문서가 저장되었습니다.');
          // 저장 후 뒤로가기
          Navigator.pop(context, true);
        } else {
          _showSnackBar(result.message ?? '저장 실패', isError: true);
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

  // 색상 메뉴 아이템 생성 헬퍼
  PopupMenuItem<Color> _buildColorMenuItem(Color color, String label) {
    return PopupMenuItem<Color>(
      value: color,
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color,
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _titleController.dispose();
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
      body: Column(
        children: [
          // 제목 입력
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: '제목을 입력하세요',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
          ),
          const Divider(height: 1),

          // 툴바
          Container(
            color: Colors.grey[100],
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  // 텍스트 스타일
                  IconButton(
                    icon: const Icon(Icons.format_bold),
                    onPressed: () {
                      _controller.formatSelection(Attribute.bold);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.format_italic),
                    onPressed: () {
                      _controller.formatSelection(Attribute.italic);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.format_underline),
                    onPressed: () {
                      _controller.formatSelection(Attribute.underline);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.strikethrough_s),
                    onPressed: () {
                      _controller.formatSelection(Attribute.strikeThrough);
                    },
                  ),
                  const VerticalDivider(),

                  // 글꼴 크기
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.text_fields),
                    tooltip: '글꼴 크기',
                    onSelected: (value) {
                      _controller.formatSelection(
                        Attribute.fromKeyValue(
                          'size',
                          value == 'normal' ? null : value,
                        ),
                      );
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'small', child: Text('작게')),
                      const PopupMenuItem(value: 'normal', child: Text('보통')),
                      const PopupMenuItem(value: 'large', child: Text('크게')),
                      const PopupMenuItem(value: 'huge', child: Text('매우 크게')),
                    ],
                  ),

                  // 텍스트 색상
                  PopupMenuButton<Color>(
                    icon: const Icon(Icons.format_color_text),
                    tooltip: '텍스트 색상',
                    onSelected: (color) {
                      final colorValue = color.value;
                      final hexColor =
                          '#${colorValue.toRadixString(16).padLeft(8, '0').substring(2)}';
                      _controller.formatSelection(
                        Attribute.fromKeyValue('color', hexColor),
                      );
                    },
                    itemBuilder: (context) => [
                      _buildColorMenuItem(Colors.black, '검정'),
                      _buildColorMenuItem(Colors.red, '빨강'),
                      _buildColorMenuItem(Colors.blue, '파랑'),
                      _buildColorMenuItem(Colors.green, '초록'),
                      _buildColorMenuItem(Colors.orange, '주황'),
                      _buildColorMenuItem(Colors.purple, '보라'),
                    ],
                  ),

                  // 형광펜 (배경색)
                  PopupMenuButton<Color>(
                    icon: const Icon(Icons.highlight),
                    tooltip: '형광펜',
                    onSelected: (color) {
                      if (color == Colors.transparent) {
                        _controller.formatSelection(
                          Attribute.fromKeyValue('background', null),
                        );
                      } else {
                        final colorValue = color.value;
                        final hexColor =
                            '#${colorValue.toRadixString(16).padLeft(8, '0').substring(2)}';
                        _controller.formatSelection(
                          Attribute.fromKeyValue('background', hexColor),
                        );
                      }
                    },
                    itemBuilder: (context) => [
                      _buildColorMenuItem(Colors.yellow, '노랑 형광펜'),
                      _buildColorMenuItem(Colors.greenAccent, '초록 형광펜'),
                      _buildColorMenuItem(Colors.pinkAccent, '핑크 형광펜'),
                      _buildColorMenuItem(Colors.orangeAccent, '주황 형광펜'),
                      _buildColorMenuItem(Colors.transparent, '제거'),
                    ],
                  ),

                  const VerticalDivider(),

                  // 헤더
                  IconButton(
                    icon: const Icon(Icons.title),
                    onPressed: () {
                      _controller.formatSelection(Attribute.h1);
                    },
                  ),

                  // 리스트
                  IconButton(
                    icon: const Icon(Icons.format_list_bulleted),
                    onPressed: () {
                      _controller.formatSelection(Attribute.ul);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.format_list_numbered),
                    onPressed: () {
                      _controller.formatSelection(Attribute.ol);
                    },
                  ),

                  const VerticalDivider(),

                  // 실행취소/다시실행
                  IconButton(
                    icon: const Icon(Icons.undo),
                    onPressed: () {
                      _controller.undo();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.redo),
                    onPressed: () {
                      _controller.redo();
                    },
                  ),

                  // 포맷 제거
                  IconButton(
                    icon: const Icon(Icons.format_clear),
                    tooltip: '서식 지우기',
                    onPressed: () {
                      final selection = _controller.selection;
                      final text = _controller.document.getPlainText(
                        selection.start,
                        selection.end - selection.start,
                      );
                      _controller.replaceText(
                        selection.start,
                        selection.end - selection.start,
                        text,
                        null,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),

          // 에디터
          Expanded(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: QuillEditor.basic(
                controller: _controller,
                focusNode: _focusNode,
              ),
            ),
          ),
        ],
      ),

      // 하단 저장 버튼
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
