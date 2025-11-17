import 'package:flutter/material.dart';
import '../../../core/service/prediction_service.dart';
import '../../../core/service/auth_service.dart';

class PredictionResult extends StatefulWidget {
  const PredictionResult({super.key});

  @override
  State<PredictionResult> createState() => _PredictionResultState();
}

class _PredictionResultState extends State<PredictionResult> {
  final PredictionService _predictionService = PredictionService();
  final AuthService _authService = AuthService();

  List<Map<String, dynamic>> _predictions = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPredictions();
  }

  Future<void> _loadPredictions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await _authService.loadFromStorage();

      if (user == null) {
        setState(() {
          _errorMessage = '로그인이 필요합니다.';
          _isLoading = false;
        });
        return;
      }

      // userId 체크
      if (user.userId == null) {
        setState(() {
          _errorMessage = '사용자 ID를 찾을 수 없습니다.';
          _isLoading = false;
        });
        return;
      }

      PredictionsResult result;

      // 권한에 따라 다른 API 호출
      if (user.role == 'DOCTOR' || user.role == 'ADMIN') {
        // 의사/관리자: 의사별 예측 결과 조회
        result = await _predictionService.getPredictionsByDoctor(user.userId!);
      } else if (user.role == 'PATIENT') {
        // 환자: 환자별 예측 결과 조회
        result = await _predictionService.getPredictionsByPatient(user.userId!);
      } else {
        setState(() {
          _errorMessage = '권한이 없습니다.';
          _isLoading = false;
        });
        return;
      }

      if (result.success && result.predictions != null) {
        setState(() {
          _predictions = result.predictions!;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result.message ?? '예측 결과를 불러오는데 실패했습니다.';
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

  void _showPredictionDetail(Map<String, dynamic> prediction) {
    final outputLabel = prediction['output_label'] as int?;
    final outputProba = prediction['output_proba'] as num?;
    final inputData = prediction['input_data'] as Map<String, dynamic>?;
    final createdAt = prediction['created_at'] as String?;
    final patientId = prediction['patient_id'];
    final patientName = prediction['patient_name'];

    final isPositive = outputLabel == 1;
    final percentageText = outputProba != null
        ? (outputProba * 100).toStringAsFixed(2)
        : 'N/A';

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
              child: Text('중피종 예측 결과 상세'),
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
                    if (patientName != null) Text('이름: $patientName'),
                    Text('환자 ID: $patientId'),
                    if (createdAt != null)
                      Text(
                        '예측 일시: ${_formatDateTime(createdAt)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
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

              // 입력 데이터 정보
              if (inputData != null) ...[
                const Text(
                  '입력 데이터',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDataRow('나이', inputData['age']?.toString()),
                      _buildDataRow('증상 지속 기간', inputData['duration_of_symptoms']?.toString(), unit: '개월'),
                      _buildDataRow('혈소판', inputData['platelet_count_(PLT)']?.toString(), unit: '10³/µL'),
                      _buildDataRow('백혈구', inputData['cell_count_(WBC)']?.toString(), unit: '/µL'),
                      _buildDataRow('혈중 LDH', inputData['blood_lactic_dehydrogenise_(LDH)']?.toString(), unit: 'U/L'),
                      _buildDataRow('늑막 LDH', inputData['pleural_lactic_dehydrogenise']?.toString(), unit: 'U/L'),
                      _buildDataRow('늑막 단백질', inputData['pleural_protein']?.toString(), unit: 'g/dL'),
                      _buildDataRow('총 단백질', inputData['total_protein']?.toString(), unit: 'g/dL'),
                      _buildDataRow('알부민', inputData['albumin']?.toString(), unit: 'g/dL'),
                      _buildDataRow('CRP', inputData['C-reactive_protein_(CRP)']?.toString(), unit: 'mg/dL'),
                      _buildDataRow('석면 노출 기간', inputData['duration_of_asbestos_exposure']?.toString(), unit: '년'),
                    ],
                  ),
                ),
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

  Widget _buildDataRow(String label, String? value, {String? unit}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value != null ? '$value${unit != null ? ' $unit' : ''}' : 'N/A',
            style: const TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(String dateTimeStr) {
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      // Format: 2025-11-17 14:30
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
        title: const Text("진단 결과"),
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPredictions,
            tooltip: '새로고침',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loadPredictions,
                        icon: const Icon(Icons.refresh),
                        label: const Text('다시 시도'),
                      ),
                    ],
                  ),
                )
              : _predictions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            '예측 결과가 없습니다.',
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadPredictions,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _predictions.length,
                        itemBuilder: (context, index) {
                          final prediction = _predictions[index];
                          final outputLabel = prediction['output_label'] as int?;
                          final outputProba = prediction['output_proba'] as num?;
                          final createdAt = prediction['created_at'] as String?;
                          final patientId = prediction['patient_id'];
                          final patientName = prediction['patient_name'];

                          final isPositive = outputLabel == 1;
                          final percentageText = outputProba != null
                              ? (outputProba * 100).toStringAsFixed(1)
                              : 'N/A';

                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              onTap: () => _showPredictionDetail(prediction),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          isPositive
                                              ? Icons.warning_amber_rounded
                                              : Icons.check_circle_outline,
                                          color: isPositive
                                              ? Colors.orange
                                              : Colors.green,
                                          size: 32,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                isPositive ? '중피종 양성' : '중피종 음성',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: isPositive
                                                      ? Colors.orange[800]
                                                      : Colors.green[800],
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '확률: $percentageText%',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey[700],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(
                                          Icons.arrow_forward_ios,
                                          size: 16,
                                          color: Colors.grey,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    const Divider(),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.person_outline,
                                          size: 16,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          patientName != null
                                              ? '$patientName (ID: $patientId)'
                                              : '환자 ID: $patientId',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (createdAt != null) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.access_time,
                                            size: 16,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            _formatDateTime(createdAt),
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
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
