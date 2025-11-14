import '../../config/base_config.dart';
import '../model/patient.dart';

class PatientService {
  final BaseConfig _api = BaseConfig();

  /**
   * 의사에 맞는 환자 조회 api
   */
  Future<List<Patient>> getMyPatients(int? doctorId) async {

    final resp = await _api.dio.get('/api/patients/?doctor_id=$doctorId');
    return (resp.data as List)
        .map((e) => Patient.fromJson(e))
        .toList();
  }
}
