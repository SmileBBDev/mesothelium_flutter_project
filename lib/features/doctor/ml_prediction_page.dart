// 의사용 ML 예측 페이지 - 환자 선택 및 검사 데이터 입력 (11개 base_features)
import 'package:flutter/material.dart';
import '../../core/service/ml_service.dart';
import '../../core/service/patient_service.dart';
import '../../core/model/patient.dart';

class MlPredictionPage extends StatefulWidget {
  final int? preselectedPatientId;
  final String? preselectedPatientName;

  const MlPredictionPage({
    super.key,
    this.preselectedPatientId,
    this.preselectedPatientName,
  });

  @override
  State<MlPredictionPage> createState() => _MlPredictionPageState();
}

class _MlPredictionPageState extends State<MlPredictionPage> {
  final _formKey = GlobalKey<FormState>();
  final _mlService = MlService();
  final _patientService = PatientService();

  // 선택된 환자 정보
  int? _selectedPatientId;
  String? _selectedPatientName;

  // 폼 컨트롤러들 (11개 base_features)
  final _ageController = TextEditingController();
  final _symptomsDurationController = TextEditingController();
  final _plateletController = TextEditingController();
  final _cellCountController = TextEditingController();
  final _bloodLdhController = TextEditingController();
  final _pleuralLdhController = TextEditingController();
  final _pleuralProteinController = TextEditingController();
  final _totalProteinController = TextEditingController();
  final _albuminController = TextEditingController();
  final _crpController = TextEditingController();
  final _exposureDurationController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.preselectedPatientId != null) {
      _selectedPatientId = widget.preselectedPatientId;
      _selectedPatientName = widget.preselectedPatientName;
    }
  }

  @override
  void dispose() {
    _ageController.dispose();
    _symptomsDurationController.dispose();
    _plateletController.dispose();
    _cellCountController.dispose();
    _bloodLdhController.dispose();
    _pleuralLdhController.dispose();
    _pleuralProteinController.dispose();
    _totalProteinController.dispose();
    _albuminController.dispose();
    _crpController.dispose();
    _exposureDurationController.dispose();
    super.dispose();
  }

  Future<void> _runPrediction() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedPatientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('환자를 선택해주세요'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _mlService.predictSingle(
        patientId: _selectedPatientId!,
        age: int.parse(_ageController.text),
        durationOfSymptoms: int.parse(_symptomsDurationController.text),
        plateletCount: double.parse(_plateletController.text),
        cellCount: double.parse(_cellCountController.text),
        bloodLacticDehydrogenise: double.parse(_bloodLdhController.text),
        pleuralLacticDehydrogenise: double.parse(_pleuralLdhController.text),
        pleuralProtein: double.parse(_pleuralProteinController.text),
        totalProtein: double.parse(_totalProteinController.text),
        albumin: double.parse(_albuminController.text),
        cReactiveProtein: double.parse(_crpController.text),
        durationOfAsbestosExposure: int.parse(_exposureDurationController.text),
      );

      if (mounted) {
        setState(() => _isLoading = false);

        if (result.success) {
          _showPredictionResult(result);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message ?? 'ML 예측 실패'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('예측 중 오류 발생: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showPredictionResult(MlPredictResult result) {
    final probability = result.firstProbability ?? 0.0;
    final label = result.firstLabel ?? 0;
    final isPositive = label == 1;
    final percentageText = (probability * 100).toStringAsFixed(2);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isPositive ? Icons.warning_amber : Icons.check_circle,
              size: 32,
              color: isPositive ? Colors.orange : Colors.green,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('중피종 예측 결과'),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 환자 정보
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
                      '환자 정보',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('이름: $_selectedPatientName'),
                    Text('환자 ID: $_selectedPatientId'),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 예측 결과
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isPositive ? Colors.orange[50] : Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isPositive ? Colors.orange : Colors.green,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        isPositive ? '중피종 양성' : '중피종 음성',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isPositive ? Colors.orange[800] : Colors.green[800],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '예측 확률: $percentageText%',
                        style: TextStyle(
                          fontSize: 18,
                          color: isPositive ? Colors.orange[700] : Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 경고 메시지
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[800], size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        '이 결과는 AI 모델의 예측이며, 최종 진단은 의사의 종합적인 판단이 필요합니다.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 저장 안내
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle_outline, color: Colors.green[800], size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        '예측 결과가 자동으로 환자 기록에 저장되었습니다.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('중피종 ML 예측'),
        backgroundColor: Colors.blue[700],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 환자 선택 섹션
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.person, color: Colors.blue[700]),
                                const SizedBox(width: 8),
                                const Text(
                                  '환자 선택',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (_selectedPatientId != null)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _selectedPatientName ?? '환자',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'ID: $_selectedPatientId',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (widget.preselectedPatientId == null)
                                      TextButton(
                                        onPressed: () {
                                          setState(() {
                                            _selectedPatientId = null;
                                            _selectedPatientName = null;
                                          });
                                        },
                                        child: const Text('변경'),
                                      ),
                                  ],
                                ),
                              )
                            else
                              ElevatedButton.icon(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('환자 목록에서 선택하는 기능은 추후 구현됩니다'),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.search),
                                label: const Text('환자 검색'),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 검사 데이터 입력 섹션 (11개 필드)
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.science, color: Colors.blue[700]),
                                const SizedBox(width: 8),
                                const Text(
                                  '검사 데이터 입력',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // 1. 기본 정보
                            const Text(
                              '기본 정보',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(height: 12),

                            TextFormField(
                              controller: _ageController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: '나이 *',
                                hintText: '예: 65',
                                suffixText: '세',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) return '나이를 입력해주세요';
                                final age = int.tryParse(value);
                                if (age == null || age < 0 || age > 120) return '올바른 나이를 입력해주세요 (0-120)';
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),

                            TextFormField(
                              controller: _symptomsDurationController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: '증상 지속 기간 *',
                                hintText: '예: 3',
                                suffixText: '개월',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) return '증상 지속 기간을 입력해주세요';
                                final duration = int.tryParse(value);
                                if (duration == null || duration < 0) return '올바른 기간을 입력해주세요';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // 2. 석면 노출 정보
                            const Text(
                              '석면 노출 정보',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(height: 12),

                            TextFormField(
                              controller: _exposureDurationController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: '석면 노출 기간 *',
                                hintText: '예: 10',
                                suffixText: '년',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) return '노출 기간을 입력해주세요';
                                final duration = int.tryParse(value);
                                if (duration == null || duration < 0) return '올바른 기간을 입력해주세요';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // 3. 혈액 검사 수치
                            const Text(
                              '혈액 검사 수치',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(height: 12),

                            TextFormField(
                              controller: _plateletController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: '혈소판 수치 (PLT) *',
                                hintText: '예: 250.0',
                                suffixText: '10³/µL',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) return '혈소판 수치를 입력해주세요';
                                final count = double.tryParse(value);
                                if (count == null || count < 0) return '올바른 수치를 입력해주세요';
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),

                            TextFormField(
                              controller: _cellCountController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: '백혈구 수치 (WBC) *',
                                hintText: '예: 7000.0',
                                suffixText: '/µL',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) return '백혈구 수치를 입력해주세요';
                                final count = double.tryParse(value);
                                if (count == null || count < 0) return '올바른 수치를 입력해주세요';
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),

                            TextFormField(
                              controller: _bloodLdhController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: '혈중 LDH 수치 *',
                                hintText: '예: 180.0',
                                suffixText: 'U/L',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'LDH 수치를 입력해주세요';
                                final ldh = double.tryParse(value);
                                if (ldh == null || ldh < 0) return '올바른 수치를 입력해주세요';
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),

                            TextFormField(
                              controller: _crpController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'C-반응성 단백질 (CRP) *',
                                hintText: '예: 1.2',
                                suffixText: 'mg/dL',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'CRP 수치를 입력해주세요';
                                final crp = double.tryParse(value);
                                if (crp == null || crp < 0) return '올바른 수치를 입력해주세요';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // 4. 단백질 수치
                            const Text(
                              '단백질 수치',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(height: 12),

                            TextFormField(
                              controller: _totalProteinController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: '총 단백질 *',
                                hintText: '예: 7.0',
                                suffixText: 'g/dL',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) return '총 단백질 수치를 입력해주세요';
                                final protein = double.tryParse(value);
                                if (protein == null || protein < 0) return '올바른 수치를 입력해주세요';
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),

                            TextFormField(
                              controller: _albuminController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: '알부민 *',
                                hintText: '예: 3.8',
                                suffixText: 'g/dL',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) return '알부민 수치를 입력해주세요';
                                final albumin = double.tryParse(value);
                                if (albumin == null || albumin < 0) return '올바른 수치를 입력해주세요';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // 5. 늑막 검사 수치
                            const Text(
                              '늑막 검사 수치',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(height: 12),

                            TextFormField(
                              controller: _pleuralLdhController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: '늑막 LDH 수치 *',
                                hintText: '예: 200.0',
                                suffixText: 'U/L',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) return '늑막 LDH 수치를 입력해주세요';
                                final ldh = double.tryParse(value);
                                if (ldh == null || ldh < 0) return '올바른 수치를 입력해주세요';
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),

                            TextFormField(
                              controller: _pleuralProteinController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: '늑막 단백질 *',
                                hintText: '예: 4.5',
                                suffixText: 'g/dL',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) return '늑막 단백질 수치를 입력해주세요';
                                final protein = double.tryParse(value);
                                if (protein == null || protein < 0) return '올바른 수치를 입력해주세요';
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 예측 실행 버튼
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _runPrediction,
                        icon: const Icon(Icons.psychology),
                        label: const Text(
                          'ML 예측 실행',
                          style: TextStyle(fontSize: 18),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
