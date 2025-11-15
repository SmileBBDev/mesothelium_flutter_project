// 관리자용 ML 모델 관리 페이지
import 'package:flutter/material.dart';
import '../../core/service/ml_service.dart';

class MLManagementPage extends StatefulWidget {
  const MLManagementPage({super.key});

  @override
  State<MLManagementPage> createState() => _MLManagementPageState();
}

class _MLManagementPageState extends State<MLManagementPage> {
  final _mlService = MlService();
  Map<String, dynamic>? _schema;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSchema();
  }

  Future<void> _loadSchema() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _mlService.getSchema();

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success && result.schema != null) {
          _schema = result.schema;
        } else {
          _errorMessage = result.message ?? 'ML 스키마를 불러올 수 없습니다.';
        }
      });
    }
  }

  Future<void> _reloadModel() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    final result = await _mlService.reloadModel();

    if (mounted) {
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: result.success ? Colors.green : Colors.red,
        ),
      );

      if (result.success) {
        _loadSchema();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ML 모델 관리'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _reloadModel,
            tooltip: '모델 리로드',
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
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadSchema,
                        child: const Text('다시 시도'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 모델 정보 카드
                      Card(
                        elevation: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.memory, size: 32, color: Colors.blue),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '중피종 예측 모델',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'XGBoost 기반 분류 모델',
                                          style: TextStyle(color: Colors.grey),
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
                              const SizedBox(height: 20),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  children: [
                                    _buildInfoRow(
                                      '피처 프리셋',
                                      _schema?['feature_preset']?.toString() ?? 'N/A',
                                    ),
                                    const Divider(height: 16),
                                    _buildInfoRow(
                                      '피처 개수',
                                      _schema?['features_count']?.toString() ??
                                      (_schema?['features_used'] as List?)?.length.toString() ?? 'N/A',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 사용된 피처 목록
                      const Text(
                        '모델 입력 피처',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: _buildFeaturesList(),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 관리 버튼
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _reloadModel,
                          icon: const Icon(Icons.refresh),
                          label: const Text('모델 리로드'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _showTestPredictionDialog,
                          icon: const Icon(Icons.science),
                          label: const Text('테스트 예측 실행'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        Text(
          value,
          style: const TextStyle(color: Colors.blue),
        ),
      ],
    );
  }

  Widget _buildFeaturesList() {
    final features = _schema?['features_used'] as List?;

    if (features == null || features.isEmpty) {
      return const Text('피처 정보를 불러올 수 없습니다.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: features.map((feature) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              const Icon(Icons.check_circle, size: 16, color: Colors.green),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  feature.toString(),
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _showTestPredictionDialog() {
    // 테스트 데이터
    final testData = {
      'asbestos_exposure': 1,
      'duration_of_asbestos_exposure': 10,
      'age': 65,
      'duration_of_symptoms': 3,
      'platelet_count_(PLT)': 250.0,
      'blood_lactic_dehydrogenise_(LDH)': 180.0,
      'pleural_glucose': 90.0,
      'pleural_thickness_on_tomography': 7.5,
      'C-reactive_protein_(CRP)': 1.2,
      'keep_side': 'left',
    };

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('테스트 예측 실행'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('샘플 데이터로 예측을 실행하시겠습니까?'),
            const SizedBox(height: 12),
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
                    '샘플 환자 정보:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('나이: ${testData['age']}세'),
                  Text('석면 노출: ${testData['asbestos_exposure']}'),
                  Text('노출 기간: ${testData['duration_of_asbestos_exposure']}년'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _runTestPrediction(testData);
            },
            child: const Text('실행'),
          ),
        ],
      ),
    );
  }

  Future<void> _runTestPrediction(Map<String, dynamic> testData) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // 테스트용 임시 patientId 사용 (실제로는 선택된 환자 ID 사용)
    final result = await _mlService.predict(
      patientId: 0,  // 테스트용 (0은 저장하지 않음)
      data: [testData],
    );

    if (mounted) {
      Navigator.pop(context);

      if (result.success) {
        _showPredictionResult(result);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? '예측 실패'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showPredictionResult(result) {
    final probability = result.firstProbability;
    final label = result.firstLabel;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('예측 결과'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              label == 1 ? Icons.warning : Icons.check_circle,
              size: 64,
              color: label == 1 ? Colors.orange : Colors.green,
            ),
            const SizedBox(height: 16),
            Text(
              '예측: ${label == 1 ? "중피종 양성" : "중피종 음성"}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '확률: ${(probability * 100).toStringAsFixed(2)}%',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}
