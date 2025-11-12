
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../constants.dart';

import 'available_doctor_section.dart';
import 'category_section.dart';
import 'HeaderSection.dart';

class PatientMainPage extends StatefulWidget{
  static String url = '/patientMain';

  @override
  _PatientMainPageState createState() => _PatientMainPageState();
}
class _PatientMainPageState extends State<PatientMainPage> {
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
    return Column(
      children: const [
        HeaderSection(),
        CategorySection(),
        SizedBox(height: defaultPadding * 2),
        AvailableDoctorSection(),
      ],
    );
  }

}
