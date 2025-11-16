// 의사: 담당 환자 목록 페이지
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/service/patient_service.dart';
import '../../core/service/auth_service.dart';
import '../../core/service/ml_service.dart';
import '../../core/service/prescription_service.dart';
import '../../core/service/api_config.dart';

class DoctorPatientsList extends StatefulWidget {
  final AuthUser? user;
  final Future<void> Function()? onPatientsChanged;

  const DoctorPatientsList({super.key, this.user, this.onPatientsChanged});

  @override
  State<DoctorPatientsList> createState() => _DoctorPatientsListState();
}

class _DoctorPatientsListState extends State<DoctorPatientsList> {
  List<Map<String, dynamic>> _patients = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 담당 환자 목록 조회
      final patients = await PatientService().getMyPatients(widget.user?.userId);

      if (mounted) {
        setState(() {
          _patients = patients.map((p) => {
            'id': p.id,
            'name': p.name,
            'birth_year': p.birthYear,
            'phone': p.phone,
            'reservation_date': p.reservationDate,
            'created_by_username': p.createdByUsername,
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '환자 목록 로드 실패: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('환자 목록 로딩 중...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPatients,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    if (_patients.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('담당 환자가 없습니다'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPatients,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _patients.length,
        itemBuilder: (context, index) {
          final patient = _patients[index];
          final age = patient['birth_year'] != null
              ? DateTime.now().year - (patient['birth_year'] as int)
              : null;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue[100],
                child: Text(
                  patient['name']?.toString().substring(0, 1).toUpperCase() ?? '?',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
              title: Text(
                patient['name']?.toString() ?? '이름 없음',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  if (age != null)
                    Text('나이: $age세'),
                  if (patient['phone'] != null && patient['phone'].toString().isNotEmpty)
                    Text('연락처: ${patient['phone']}'),
                  if (patient['reservation_date'] != null)
                    Text('예약일: ${patient['reservation_date']}'),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.description, color: Colors.purple),
                    onPressed: () => _showPrescriptionListDialog(patient),
                    tooltip: '진료 기록 조회',
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_note, color: Colors.blue),
                    onPressed: () => _showPrescriptionDialog(patient),
                    tooltip: '진료 기록 작성',
                  ),
                  IconButton(
                    icon: const Icon(Icons.analytics, color: Colors.green),
                    onPressed: () => _showMLPredictionDialog(patient),
                    tooltip: 'ML 예측',
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showPrescriptionListDialog(Map<String, dynamic> patient) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('${patient['name']} - 진료 기록 목록'),
          content: SizedBox(
            width: 600,
            height: 400,
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: PrescriptionService().getPrescriptionsByPatient(patient['id'] as int),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('오류: ${snapshot.error}'),
                  );
                }

                final prescriptions = snapshot.data ?? [];

                if (prescriptions.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.description_outlined, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('작성된 진료 기록이 없습니다'),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: prescriptions.length,
                  itemBuilder: (context, index) {
                    final prescription = prescriptions[index];
                    final createdAt = prescription['created_at']?.toString() ?? '';
                    final doctorName = prescription['doctor_username']?.toString() ?? '알 수 없음';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.note_alt, color: Colors.blue),
                        title: Text(
                          prescription['title']?.toString() ?? '제목 없음',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('작성자: $doctorName'),
                            Text('작성일: ${createdAt.substring(0, createdAt.length > 10 ? 10 : createdAt.length)}'),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.visibility, color: Colors.green),
                          onPressed: () {
                            Navigator.pop(dialogContext);
                            _showPrescriptionDetailDialog(prescription);
                          },
                          tooltip: '상세보기',
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('닫기'),
            ),
          ],
        );
      },
    );
  }

  void _showPrescriptionDetailDialog(Map<String, dynamic> prescription) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(prescription['title']?.toString() ?? '제목 없음'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '작성자: ${prescription['doctor_username']?.toString() ?? '알 수 없음'}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '작성일: ${prescription['created_at']?.toString().substring(0, 10) ?? ''}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const Divider(height: 24),
                  const Text(
                    '내용:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    prescription['content_delta']?.toString() ?? '내용 없음',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('닫기'),
            ),
          ],
        );
      },
    );
  }

  void _showPrescriptionDialog(Map<String, dynamic> patient) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('${patient['name']} - 진료 기록 작성'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: '제목',
                    hintText: '예: 정기 검진, 진료 소견 등',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: contentController,
                  decoration: const InputDecoration(
                    labelText: '진료 내용',
                    hintText: '증상, 진단, 처방 등을 입력하세요',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 5,
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
              onPressed: () async {
                if (titleController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('제목을 입력하세요')),
                  );
                  return;
                }
                Navigator.pop(dialogContext);
                await _createPrescription(
                  patient,
                  titleController.text,
                  contentController.text,
                );
              },
              child: const Text('저장'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createPrescription(
    Map<String, dynamic> patient,
    String title,
    String content,
  ) async {
    try {
      // 로딩 인디케이터 표시
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('진료 기록 저장 중...'),
              ],
            ),
          );
        },
      );

      // Prescription API 호출
      final prescriptionService = PrescriptionService();
      final response = await prescriptionService.createPrescription(
        patientId: patient['id'] as int,
        doctorId: widget.user?.doctorId ?? 0,
        title: title,
        contentDelta: content, // 단순 텍스트를 그대로 전달
      );

      if (!mounted) return;
      Navigator.pop(context); // 로딩 다이얼로그 닫기

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${patient['name']}님의 진료 기록이 저장되었습니다'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('진료 기록 저장 실패: ${response.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      // 로딩 다이얼로그가 열려있으면 닫기
      Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('진료 기록 저장 실패: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showMLPredictionDialog(Map<String, dynamic> patient) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return _MLPredictionDialogContent(
          patient: patient,
          user: widget.user,
        );
      },
    );
  }
}

class _MLPredictionDialogContent extends StatefulWidget {
  final Map<String, dynamic> patient;
  final AuthUser? user;

  const _MLPredictionDialogContent({
    required this.patient,
    this.user,
  });

  @override
  State<_MLPredictionDialogContent> createState() => _MLPredictionDialogContentState();
}

class _MLPredictionDialogContentState extends State<_MLPredictionDialogContent> {
  late Future<List<Map<String, dynamic>>> _predictionsFuture;

  @override
  void initState() {
    super.initState();
    _loadPredictions();
  }

  void _loadPredictions() {
    if (mounted) {
      setState(() {
        _predictionsFuture = _fetchPredictionResults(widget.patient['id'] as int);
      });
    }
  }

  Future<List<Map<String, dynamic>>> _fetchPredictionResults(int patientId) async {
    try {
      final url = '${ApiConfig.baseUrl}${ApiConfig.predictionsEndpoint}?patient_id=$patientId';
      debugPrint('[ML 예측 조회] URL: $url');

      // 토큰 가져오기
      final token = await AuthService().getAccessToken();
      if (token == null) {
        debugPrint('[ML 예측 조회] 토큰이 없습니다');
        return [];
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('[ML 예측 조회] Status: ${response.statusCode}');
      debugPrint('[ML 예측 조회] Body: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);
        debugPrint('[ML 예측 조회] Response type: ${responseData.runtimeType}');

        if (responseData is List) {
          debugPrint('[ML 예측 조회] List 형태, 개수: ${responseData.length}');
          return responseData.cast<Map<String, dynamic>>();
        } else if (responseData is Map) {
          debugPrint('[ML 예측 조회] Map 형태, keys: ${responseData.keys}');
          if (responseData.containsKey('results')) {
            final results = responseData['results'];
            if (results is List) {
              debugPrint('[ML 예측 조회] Paginated response, 개수: ${results.length}');
              return results.cast<Map<String, dynamic>>();
            }
          } else {
            debugPrint('[ML 예측 조회] Single object, wrapping in list');
            return [responseData as Map<String, dynamic>];
          }
        }
      }
      debugPrint('[ML 예측 조회] 빈 배열 반환');
      return [];
    } catch (e) {
      debugPrint('[ML 예측 결과 조회 오류] $e');
      rethrow;
    }
  }

  void _runMLPrediction() {
    Navigator.pop(context); // 다이얼로그 닫기
    _showMLInputDialog();
  }

  void _showMLInputDialog() {
    // ML 모델에 필요한 11개 필드
    final controllers = {
      'age': TextEditingController(text: widget.patient['birth_year'] != null
          ? (DateTime.now().year - (widget.patient['birth_year'] as int)).toString()
          : ''),
      'duration_of_symptoms': TextEditingController(),
      'platelet_count': TextEditingController(),
      'cell_count': TextEditingController(),
      'blood_ldh': TextEditingController(),
      'pleural_ldh': TextEditingController(),
      'pleural_protein': TextEditingController(),
      'total_protein': TextEditingController(),
      'albumin': TextEditingController(),
      'crp': TextEditingController(),
      'asbestos_exposure': TextEditingController(),
    };

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('${widget.patient['name']} - ML 예측 데이터 입력'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: controllers['age'], decoration: const InputDecoration(labelText: '나이 (Age)'), keyboardType: TextInputType.number),
                TextField(controller: controllers['duration_of_symptoms'], decoration: const InputDecoration(labelText: '증상 지속 기간 (일)'), keyboardType: TextInputType.number),
                TextField(controller: controllers['platelet_count'], decoration: const InputDecoration(labelText: '혈소판 수 (PLT)'), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                TextField(controller: controllers['cell_count'], decoration: const InputDecoration(labelText: '백혈구 수 (WBC)'), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                TextField(controller: controllers['blood_ldh'], decoration: const InputDecoration(labelText: '혈액 LDH'), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                TextField(controller: controllers['pleural_ldh'], decoration: const InputDecoration(labelText: '흉막 LDH'), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                TextField(controller: controllers['pleural_protein'], decoration: const InputDecoration(labelText: '흉막 단백질'), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                TextField(controller: controllers['total_protein'], decoration: const InputDecoration(labelText: '총 단백질'), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                TextField(controller: controllers['albumin'], decoration: const InputDecoration(labelText: '알부민'), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                TextField(controller: controllers['crp'], decoration: const InputDecoration(labelText: 'CRP'), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                TextField(controller: controllers['asbestos_exposure'], decoration: const InputDecoration(labelText: '석면 노출 기간 (년)'), keyboardType: TextInputType.number),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('취소')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await _executeMLPrediction(controllers);
              },
              child: const Text('예측 실행'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _executeMLPrediction(Map<String, TextEditingController> controllers) async {
    showDialog(context: context, barrierDismissible: false, builder: (ctx) => const AlertDialog(content: Column(mainAxisSize: MainAxisSize.min, children: [CircularProgressIndicator(), SizedBox(height: 16), Text('ML 모델 실행 중...')])));

    try {
      final mlService = MlService();
      final result = await mlService.predictSingle(
        patientId: widget.patient['id'] as int,
        age: int.tryParse(controllers['age']!.text) ?? 0,
        durationOfSymptoms: int.tryParse(controllers['duration_of_symptoms']!.text) ?? 0,
        plateletCount: double.tryParse(controllers['platelet_count']!.text) ?? 0.0,
        cellCount: double.tryParse(controllers['cell_count']!.text) ?? 0.0,
        bloodLacticDehydrogenise: double.tryParse(controllers['blood_ldh']!.text) ?? 0.0,
        pleuralLacticDehydrogenise: double.tryParse(controllers['pleural_ldh']!.text) ?? 0.0,
        pleuralProtein: double.tryParse(controllers['pleural_protein']!.text) ?? 0.0,
        totalProtein: double.tryParse(controllers['total_protein']!.text) ?? 0.0,
        albumin: double.tryParse(controllers['albumin']!.text) ?? 0.0,
        cReactiveProtein: double.tryParse(controllers['crp']!.text) ?? 0.0,
        durationOfAsbestosExposure: int.tryParse(controllers['asbestos_exposure']!.text) ?? 0,
      );

      if (!mounted) return;
      Navigator.pop(context); // 로딩 닫기

      if (result.success) {
        final label = result.firstLabel;
        final proba = result.firstProbability;

        // 예측 성공 - 목록 새로고침
        if (mounted) {
          _loadPredictions();
        }

        // 결과 다이얼로그 표시 후 다시 예측 목록 다이얼로그 열기
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('ML 예측 결과'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(label == 1 ? Icons.warning : Icons.check_circle, size: 64, color: label == 1 ? Colors.orange : Colors.green),
                const SizedBox(height: 16),
                Text('${widget.patient['name']}님의 예측 결과'),
                const SizedBox(height: 8),
                Text('예측: ${label == 1 ? "악성 (Malignant)" : "양성 (Benign)"}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('확률: ${(proba! * 100).toStringAsFixed(2)}%', style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 16),
                const Text('결과가 저장되었습니다.', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('확인'))],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ML 예측 실패: ${result.message}'), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ML 예측 실행 실패: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.patient['name']} - ML 예측'),
      content: SizedBox(
        width: 600,
        height: 450,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _predictionsFuture,
          builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('오류: ${snapshot.error}'),
                      ],
                    ),
                  );
                }

                final predictions = snapshot.data ?? [];

                return Column(
                  children: [
                    // 기존 예측 결과 목록
                    Expanded(
                      child: predictions.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.analytics_outlined, size: 64, color: Colors.grey),
                                  SizedBox(height: 16),
                                  Text('저장된 예측 결과가 없습니다'),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: predictions.length,
                              itemBuilder: (context, index) {
                                final pred = predictions[index];
                                final label = pred['output_label'] ?? 0;
                                final probability = pred['output_proba'] ?? 0.0;
                                final createdAt = pred['created_at']?.toString() ?? '';

                                // requested_by_doctor는 객체이므로 중첩 접근
                                String doctorName = '알 수 없음';
                                if (pred['requested_by_doctor'] != null) {
                                  final doctor = pred['requested_by_doctor'];
                                  if (doctor is Map && doctor.containsKey('username')) {
                                    doctorName = doctor['username']?.toString() ?? '알 수 없음';
                                  }
                                }

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  color: label == 1 ? Colors.orange[50] : Colors.green[50],
                                  child: ListTile(
                                    leading: Icon(
                                      label == 1 ? Icons.warning : Icons.check_circle,
                                      color: label == 1 ? Colors.orange : Colors.green,
                                      size: 36,
                                    ),
                                    title: Text(
                                      label == 1 ? '악성 (Malignant)' : '양성 (Benign)',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('확률: ${(probability * 100).toStringAsFixed(2)}%'),
                                        Text('진단의: $doctorName'),
                                        Text('진단일: ${createdAt.substring(0, createdAt.length > 10 ? 10 : createdAt.length)}'),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    const Divider(height: 24),
                    // 새 예측 실행 버튼
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.add_chart),
                        label: const Text('새 예측 실행'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: _runMLPrediction,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('닫기'),
            ),
          ],
        );
  }
}
