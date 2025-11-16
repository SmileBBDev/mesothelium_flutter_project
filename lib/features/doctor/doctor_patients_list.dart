// 의사: 담당 환자 목록 페이지
import 'package:flutter/material.dart';
import '../../core/service/patient_service.dart';
import '../../core/service/auth_service.dart';
import '../../core/service/ml_service.dart';

class DoctorPatientsList extends StatefulWidget {
  final AuthUser? user;

  const DoctorPatientsList({super.key, this.user});

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
                    icon: const Icon(Icons.calendar_today, color: Colors.blue),
                    onPressed: () => _showScheduleDialog(patient),
                    tooltip: '진료 일정 등록',
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

  void _showScheduleDialog(Map<String, dynamic> patient) {
    final nameController = TextEditingController(text: patient['name']?.toString() ?? '');
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('진료 일정 등록'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: '환자 이름',
                        border: OutlineInputBorder(),
                      ),
                      enabled: false,
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: const Text('날짜'),
                      subtitle: Text('${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}'),
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (pickedDate != null) {
                          setDialogState(() {
                            selectedDate = pickedDate;
                          });
                        }
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.access_time),
                      title: const Text('시간'),
                      subtitle: Text('${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}'),
                      onTap: () async {
                        final pickedTime = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                        );
                        if (pickedTime != null) {
                          setDialogState(() {
                            selectedTime = pickedTime;
                          });
                        }
                      },
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
                    Navigator.pop(dialogContext);
                    await _createSchedule(patient, selectedDate, selectedTime);
                  },
                  child: const Text('등록'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _createSchedule(Map<String, dynamic> patient, DateTime date, TimeOfDay time) async {
    try {
      // 날짜와 시간을 결합하여 문자열로 변환
      final reservationDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );

      // ISO 8601 형식으로 변환: "2025-11-16T14:30:00"
      final reservationDateStr = reservationDateTime.toIso8601String();

      print('[진료일정] 환자 ID: ${patient['id']}, 예약일시: $reservationDateStr');

      // 환자 정보 업데이트 - reservation_date 설정
      final result = await PatientService().updatePatient(
        patientId: patient['id'] as int,
        reservationDate: reservationDateStr,
      );

      if (!mounted) return;

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${patient['name']}님의 진료 일정이 등록되었습니다'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadPatients();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('일정 등록 실패: ${result.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('일정 등록 중 오류: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showMLPredictionDialog(Map<String, dynamic> patient) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('${patient['name']} - ML 예측'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.analytics, size: 64, color: Colors.blue),
              SizedBox(height: 16),
              Text('ML 예측 기능을 실행하시겠습니까?'),
              SizedBox(height: 8),
              Text(
                '환자의 의료 데이터를 분석하여 예측 결과를 생성합니다.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _runMLPrediction(patient);
              },
              child: const Text('실행'),
            ),
          ],
        );
      },
    );
  }

  void _runMLPrediction(Map<String, dynamic> patient) {
    // ML 입력 데이터 입력 다이얼로그 먼저 표시
    _showMLInputDialog(patient);
  }

  void _showMLInputDialog(Map<String, dynamic> patient) {
    // ML 모델에 필요한 11개 필드
    final controllers = {
      'age': TextEditingController(text: patient['birth_year'] != null
          ? (DateTime.now().year - (patient['birth_year'] as int)).toString()
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
          title: Text('${patient['name']} - ML 예측 데이터 입력'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controllers['age'],
                  decoration: const InputDecoration(labelText: '나이 (Age)'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: controllers['duration_of_symptoms'],
                  decoration: const InputDecoration(labelText: '증상 지속 기간 (일)'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: controllers['platelet_count'],
                  decoration: const InputDecoration(labelText: '혈소판 수 (PLT)'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                TextField(
                  controller: controllers['cell_count'],
                  decoration: const InputDecoration(labelText: '백혈구 수 (WBC)'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                TextField(
                  controller: controllers['blood_ldh'],
                  decoration: const InputDecoration(labelText: '혈액 LDH'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                TextField(
                  controller: controllers['pleural_ldh'],
                  decoration: const InputDecoration(labelText: '흉막 LDH'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                TextField(
                  controller: controllers['pleural_protein'],
                  decoration: const InputDecoration(labelText: '흉막 단백질'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                TextField(
                  controller: controllers['total_protein'],
                  decoration: const InputDecoration(labelText: '총 단백질'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                TextField(
                  controller: controllers['albumin'],
                  decoration: const InputDecoration(labelText: '알부민'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                TextField(
                  controller: controllers['crp'],
                  decoration: const InputDecoration(labelText: 'CRP'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                TextField(
                  controller: controllers['asbestos_exposure'],
                  decoration: const InputDecoration(labelText: '석면 노출 기간 (년)'),
                  keyboardType: TextInputType.number,
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
                Navigator.pop(dialogContext);
                await _executeMLPrediction(patient, controllers);
              },
              child: const Text('예측 실행'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _executeMLPrediction(
    Map<String, dynamic> patient,
    Map<String, TextEditingController> controllers,
  ) async {
    // ML 예측 로딩 다이얼로그 표시
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
              Text('ML 모델 실행 중...'),
            ],
          ),
        );
      },
    );

    try {
      // ML API 호출
      final mlService = MlService();
      final result = await mlService.predictSingle(
        patientId: patient['id'] as int,
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
      Navigator.pop(context); // 로딩 다이얼로그 닫기

      if (result.success) {
        final label = result.firstLabel;
        final proba = result.firstProbability;

        // 결과 표시
        showDialog(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('ML 예측 결과'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    label == 1 ? Icons.warning : Icons.check_circle,
                    size: 64,
                    color: label == 1 ? Colors.orange : Colors.green,
                  ),
                  const SizedBox(height: 16),
                  Text('${patient['name']}님의 예측 결과'),
                  const SizedBox(height: 8),
                  Text(
                    '예측: ${label == 1 ? "악성 (Malignant)" : "양성 (Benign)"}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '확률: ${(proba! * 100).toStringAsFixed(2)}%',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '자세한 결과는 예측 결과 탭에서 확인하세요.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('확인'),
                ),
              ],
            );
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ML 예측 실패: ${result.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // 로딩 다이얼로그 닫기

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ML 예측 실행 실패: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
