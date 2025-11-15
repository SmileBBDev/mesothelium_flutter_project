// 환자용 ML 예측 결과 조회 페이지
import 'package:flutter/material.dart';

class MlPredictionResultPage extends StatefulWidget {
  final int patientId;

  const MlPredictionResultPage({
    super.key,
    required this.patientId,
  });

  @override
  State<MlPredictionResultPage> createState() => _MlPredictionResultPageState();
}

class _MlPredictionResultPageState extends State<MlPredictionResultPage> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _predictions = [];

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

    // TODO: API 연동 - 환자의 예측 결과 목록 조회
    // prediction_service.dart에서 getPredictionsByPatient() 메서드 구현 필요

    // 임시 목 데이터
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() {
        _isLoading = false;
        // 임시 데이터
        _predictions = [
          {
            'id': 1,
            'created_at': '2025-11-15 10:30:00',
            'model_name': 'meso_xgb',
            'output_label': 0,
            'output_proba': 0.23,
            'requested_by_doctor': '김의사',
          },
          {
            'id': 2,
            'created_at': '2025-11-10 14:20:00',
            'model_name': 'meso_xgb',
            'output_label': 0,
            'output_proba': 0.18,
            'requested_by_doctor': '김의사',
          },
        ];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('내 검사 결과'),
        backgroundColor: Colors.blue[700],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(fontSize: 16),
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
                            Icons.description_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '아직 검사 결과가 없습니다',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '담당 의사에게 문의하세요',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
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
                          return _buildPredictionCard(prediction);
                        },
                      ),
                    ),
    );
  }

  Widget _buildPredictionCard(Map<String, dynamic> prediction) {
    final label = prediction['output_label'] as int;
    final proba = prediction['output_proba'] as double;
    final isPositive = label == 1;
    final createdAt = prediction['created_at'] as String;
    final doctor = prediction['requested_by_doctor'] as String?;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showDetailDialog(prediction),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더 - 날짜와 상태
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatDate(createdAt),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isPositive ? Colors.orange[100] : Colors.green[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isPositive ? '양성' : '음성',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isPositive ? Colors.orange[800] : Colors.green[800],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 결과 요약
              Row(
                children: [
                  Icon(
                    isPositive ? Icons.warning_amber : Icons.check_circle,
                    size: 48,
                    color: isPositive ? Colors.orange : Colors.green,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isPositive ? '중피종 양성' : '중피종 음성',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isPositive ? Colors.orange[800] : Colors.green[800],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '예측 확률: ${(proba * 100).toStringAsFixed(2)}%',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 의사 정보
              if (doctor != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.person, size: 16, color: Colors.blue[700]),
                      const SizedBox(width: 6),
                      Text(
                        '담당 의사: $doctor',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue[900],
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 12),

              // 안내 메시지
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'AI 예측 결과이며, 최종 진단은 의사의 종합적인 판단이 필요합니다.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // 상세보기 버튼
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _showDetailDialog(prediction),
                  icon: const Icon(Icons.arrow_forward, size: 16),
                  label: const Text('상세보기'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetailDialog(Map<String, dynamic> prediction) {
    final label = prediction['output_label'] as int;
    final proba = prediction['output_proba'] as double;
    final isPositive = label == 1;
    final createdAt = prediction['created_at'] as String;
    final doctor = prediction['requested_by_doctor'] as String?;
    final modelName = prediction['model_name'] as String;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isPositive ? Icons.warning_amber : Icons.check_circle,
              color: isPositive ? Colors.orange : Colors.green,
            ),
            const SizedBox(width: 8),
            const Expanded(child: Text('검사 결과 상세')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 예측 결과
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isPositive ? Colors.orange[50] : Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
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
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isPositive ? Colors.orange[800] : Colors.green[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '예측 확률: ${(proba * 100).toStringAsFixed(2)}%',
                      style: TextStyle(
                        fontSize: 16,
                        color: isPositive ? Colors.orange[700] : Colors.green[700],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 검사 정보
              _buildDetailRow('검사 일시', _formatDateTime(createdAt)),
              const Divider(height: 24),
              _buildDetailRow('담당 의사', doctor ?? '정보 없음'),
              const Divider(height: 24),
              _buildDetailRow('사용 모델', modelName),
              const SizedBox(height: 20),

              // 안내 사항
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue[700], size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          '안내 사항',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• 이 결과는 AI 모델의 예측입니다.\n'
                      '• 최종 진단은 의사의 종합적인 판단이 필요합니다.\n'
                      '• 검사 결과에 대해 궁금한 점이 있으시면 담당 의사에게 문의하세요.',
                      style: TextStyle(fontSize: 13, height: 1.5),
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

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(String dateTimeStr) {
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return '${dateTime.year}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeStr.split(' ').first;
    }
  }

  String _formatDateTime(String dateTimeStr) {
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return '${dateTime.year}년 ${dateTime.month}월 ${dateTime.day}일 ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeStr;
    }
  }
}
