
import 'package:flutter/material.dart';
import '../../core/model/patient.dart';
import '../../core/service/auth_service.dart';
import 'ai_prediction_summary.dart';
import 'my_schedule_card.dart';
import 'doctor_patients_list.dart';

class DoctorMainPage extends StatefulWidget{
  static String url = '/doctorMain';
  final AuthUser? user;
  final List<Patient>? patients;
  final bool? isLoading;
  final Future<void> Function()? onPatientsChanged;

  const DoctorMainPage({
    super.key,
    this.user,
    this.patients,
    this.isLoading,
    this.onPatientsChanged,
  });

  @override
  _DoctorMainPageState createState() => _DoctorMainPageState();
}

class _DoctorMainPageState extends State<DoctorMainPage> {

  @override
  void initState() {
    super.initState();

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
                  (widget.isLoading ?? false)
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
                    : MyScheduleCard(userId: widget.user?.userId, patients: widget.patients ?? [], user: widget.user),
                ],
              ),
            ),
            // 2. 담당 환자 탭
            DoctorPatientsList(
              user: widget.user,
              onPatientsChanged: widget.onPatientsChanged,
            ),
            // 3. ML 예측 탭
            const AiPredictSummary(),
          ],
        ),
      ),
    );
  }

}
