import 'package:flutter/material.dart';
import '../../../core/service/auth_service.dart';
import '../../../core/service/patient_service.dart';
import '../../../core/service/prescription_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/service/api_config.dart';

class PredictionResult extends StatefulWidget {
  final AuthUser? user;

  const PredictionResult({super.key, this.user});

  @override
  State<PredictionResult> createState() => _PredictionResultState();
}

class _PredictionResultState extends State<PredictionResult> {
  bool _isLoading = true;
  int? _patientId;
  List<Map<String, dynamic>> _predictions = [];
  List<Map<String, dynamic>> _prescriptions = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPatientData();
  }

  Future<void> _loadPatientData() async {
    try {
      // 1. 현재 사용자 이름으로 patient 찾기
      final userName = await _getUserName();
      final patientsResult = await PatientService().getAllPatients();

      if (!patientsResult.success || patientsResult.patients == null) {
        throw Exception('환자 목록 조회 실패');
      }

      final myPatient = patientsResult.patients!.firstWhere(
        (p) => p['name'] == widget.user?.username || p['name'] == userName,
        orElse: () => throw Exception('환자 정보를 찾을 수 없습니다'),
      );

      _patientId = myPatient['id'] as int;

      // 2. ML 예측 결과 조회
      try {
        final url = '${ApiConfig.baseUrl}${ApiConfig.predictionsEndpoint}?patient_id=$_patientId';
        debugPrint('[환자 ML 예측 조회] URL: $url');

        // 토큰 가져오기
        final token = await AuthService().getAccessToken();
        if (token == null) {
          debugPrint('[환자 ML 예측 조회] 토큰이 없습니다');
          throw Exception('인증 토큰이 없습니다');
        }

        final predictionResponse = await http.get(
          Uri.parse(url),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );

        debugPrint('[환자 ML 예측 조회] Status: ${predictionResponse.statusCode}');
        debugPrint('[환자 ML 예측 조회] Body: ${predictionResponse.body}');

        if (predictionResponse.statusCode == 200) {
          final dynamic responseData = json.decode(predictionResponse.body);
          debugPrint('[환자 ML 예측 조회] Response type: ${responseData.runtimeType}');

          // Handle different response structures
          if (responseData is List) {
            debugPrint('[환자 ML 예측 조회] List 형태, 개수: ${responseData.length}');
            _predictions = responseData.cast<Map<String, dynamic>>();
          } else if (responseData is Map) {
            debugPrint('[환자 ML 예측 조회] Map 형태, keys: ${responseData.keys}');
            // Check if it's a paginated response with 'results' key
            if (responseData.containsKey('results')) {
              final results = responseData['results'];
              if (results is List) {
                debugPrint('[환자 ML 예측 조회] Paginated response, 개수: ${results.length}');
                _predictions = results.cast<Map<String, dynamic>>();
              }
            } else {
              // Single object response - wrap in list
              debugPrint('[환자 ML 예측 조회] Single object, wrapping in list');
              _predictions = [responseData as Map<String, dynamic>];
            }
          }
        }
      } catch (e) {
        // ML 예측 결과 조회 실패해도 계속 진행 (진료기록은 표시)
        debugPrint('[ML 예측 조회 오류] $e');
      }

      // 3. 진료 기록 조회
      _prescriptions = await PrescriptionService()
          .getPrescriptionsByPatient(_patientId!);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<String?> _getUserName() async {
    try {
      final response = await AuthService().me();
      return response['name'] as String?;
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("내 진단 결과"),
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_errorMessage!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadPatientData,
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
                      _buildMLPredictions(),
                      const SizedBox(height: 24),
                      _buildPrescriptions(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildMLPredictions() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.analytics, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'ML 진단 결과',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            _predictions.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: Text('아직 진단 결과가 없습니다.'),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _predictions.length,
                    itemBuilder: (context, index) {
                      final prediction = _predictions[index];
                      final label = prediction['output_label'] ?? 0;
                      final probability = prediction['output_proba'] ?? 0.0;
                      final createdAt = prediction['created_at']?.toString() ?? '';

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
                              Text('진단일: ${createdAt.substring(0, createdAt.length > 10 ? 10 : createdAt.length)}'),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrescriptions() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.description, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  '진료 기록',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            _prescriptions.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: Text('아직 진료 기록이 없습니다.'),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _prescriptions.length,
                    itemBuilder: (context, index) {
                      final prescription = _prescriptions[index];
                      final createdAt = prescription['created_at']?.toString() ?? '';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ExpansionTile(
                          leading: const Icon(Icons.note_alt, color: Colors.blue),
                          title: Text(
                            prescription['title']?.toString() ?? '제목 없음',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('담당의: ${prescription['doctor_username']?.toString() ?? '알 수 없음'}'),
                              Text('작성일: ${createdAt.substring(0, createdAt.length > 10 ? 10 : createdAt.length)}'),
                            ],
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                prescription['content_delta']?.toString() ?? '내용 없음',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
