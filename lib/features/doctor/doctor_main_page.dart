
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../constants.dart';
import '../../core/model/patient.dart';
import '../../core/service/auth_service.dart';
import '../../core/service/patient_service.dart';
import 'ai_prediction_summary.dart';
import 'header_section.dart';
import 'my_schedule_card.dart';
class DoctorMainPage extends StatefulWidget{
  static String url = '/doctorMain';
  final AuthUser? user;
  const DoctorMainPage({super.key, this.user});

  @override
  _DoctorMainPageState createState() => _DoctorMainPageState();
}
class _DoctorMainPageState extends State<DoctorMainPage> {
  List<Patient> myPatients = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    try {
      final patients = await PatientService().getMyPatients(
        widget.user?.userId,
      );
      print("이걸 받았다.");
      print(patients);
      setState(() {
        myPatients = patients;
        isLoading = false;
      });
    } catch (e) {
      print("환자 조회 오류: $e");
    }
  }

  @override
  Widget build(BuildContext context){
    return SingleChildScrollView(
      child:Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DoctorHeaderSection(username : widget.user?.username),
          isLoading
            ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    "진료 일정 로딩 중입니다...",
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            )
            : MyScheduleCard(userId: widget.user?.userId, patients: myPatients,),

          const SizedBox(height: defaultPadding * 2),
          const AiPredictSummary(),
          const SizedBox(height: defaultPadding * 2),
          //AiPredictSection(),
        ],
      ),
    );
  }

}
