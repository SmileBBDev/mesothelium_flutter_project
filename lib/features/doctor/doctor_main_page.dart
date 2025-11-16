
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../constants.dart';
import '../../core/model/patient.dart';
import '../../core/service/auth_service.dart';
import '../../core/service/patient_service.dart';
import 'ai_prediction_summary.dart';
import 'header_section.dart';
import 'my_schedule_card.dart';
import 'doctor_patients_list.dart';

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
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('${widget.user?.username ?? "의사"} 님'),
          bottom: const TabBar(
            tabs: [
              Tab(text: '진료 일정', icon: Icon(Icons.calendar_today)),
              Tab(text: '담당 환자', icon: Icon(Icons.people)),
              Tab(text: 'ML 예측', icon: Icon(Icons.analytics)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // 1. 진료 일정 탭
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  isLoading
                    ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
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
                      ),
                    )
                    : MyScheduleCard(userId: widget.user?.userId, patients: myPatients),
                ],
              ),
            ),
            // 2. 담당 환자 탭
            DoctorPatientsList(user: widget.user),
            // 3. ML 예측 탭
            const AiPredictSummary(),
          ],
        ),
      ),
    );
  }

}
