
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../constants.dart';
import '../../core/widgets/botton_nav_bar.dart';
import 'ai_prediction_summary.dart';
import 'header_section.dart';
import 'my_schedule_card.dart';
import 'patient_card.dart';

class DoctorMainPage extends StatefulWidget{
  static String url = '/doctorMain';

  @override
  _DoctorMainPageState createState() => _DoctorMainPageState();
}
class _DoctorMainPageState extends State<DoctorMainPage> {
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
    return SingleChildScrollView(
      child:Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          DoctorHeaderSection(),
          MyScheduleCard(),
          SizedBox(height: defaultPadding * 2),
          AiPredictSummary(),
          SizedBox(height: defaultPadding * 2),
          //AiPredictSection(),
        ],
      ),
    );
  }

}
