
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../constants.dart';

import 'available_doctor_section.dart';
import 'category_section.dart';
import 'HeaderSection.dart';

import '../patient/page/DiseaseView.dart';
import '../patient/page/MyAppointments.dart';
import '../patient/page/PharmacyView.dart';
import '../patient/page/PredictionResult.dart';

class PatientMainPage extends StatefulWidget{
  static String url = '/patientMain';
  final void Function(String route)? onCategorySelected; // 부모에서 전달됨
  const PatientMainPage({super.key, this.onCategorySelected});

  @override
  _PatientMainPageState createState() => _PatientMainPageState();
}
class _PatientMainPageState extends State<PatientMainPage> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    // 초기 세팅되어야할 코드 기입
    // 로그인 정보 확인 같은 거
  }

  @override
  Widget build(BuildContext context){
    return Navigator(
        key: _navigatorKey,
        onGenerateRoute: (settings) {
          Widget page;
          switch (settings.name) {
            case '/pharmacy':
              page = const PharmacyView();
              break;
            case '/disease':
              page = const DiseaseView();
              break;
            case '/myAppointments':
              page = const MyAppointments();
              break;
            case '/predictionResult':
              page = const PredictionResult();
              break;
            default:
              page = _PatientMainBody(onCategorySelected : widget.onCategorySelected);
          }
          return MaterialPageRoute(builder: (_) => page);
        }
    );
  }

}

// 환자 메인 홈화면
class _PatientMainBody extends StatelessWidget{
  final void Function(String route)? onCategorySelected;
  const _PatientMainBody({super.key, this.onCategorySelected});


  @override
  Widget build(BuildContext context){
    return SingleChildScrollView(
      child:Column(
        children: [
          const HeaderSection(),
          CategorySection(onCategorySelected : onCategorySelected),
          const SizedBox(height: defaultPadding * 2),
          const AvailableDoctorSection(),
        ],
      ),
    );
  }
}