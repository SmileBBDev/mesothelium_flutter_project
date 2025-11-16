import 'package:flutter/material.dart';
import '../../core/constants/MenuCategory.dart';
import '../../core/model/patient.dart';
import '../../core/service/auth_service.dart';
import '../../core/service/patient_service.dart';
import '../admin/ApprovalPage.dart';
import '../admin/UserListPage.dart';
import '../../core/widgets/botton_nav_bar.dart';
import '../admin/admin_main_page.dart';
import '../common/pages/my_info.dart';
import '../doctor/doctor_main_page.dart';
import '../doctor/page/MyAllPatientView.dart';
import '../patient/Patient_main_page.dart';
import '../patient/page/MyAppointments.dart';
import '../patient/page/PharmacyView.dart';
import '../patient/page/PredictionResult.dart';
import '../staff/staff_main_page.dart';

class HomePage extends StatefulWidget {
  static String url = '/homePage';
  final AuthUser user;

  const HomePage({super.key, required this.user});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  List<Patient> myPatients = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    try {
      final patients = await PatientService().getMyPatients(widget.user.userId);

      print("patients 조회");
      print(patients);
      setState(() {
        myPatients = patients;
        isLoading = false;
      });

    } catch (e) {
      print("환자 조회 오류: $e");

      setState(() {
        isLoading = false;
      });
    }
  }

  void _onNavItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onCategorySelected(String route) {
    if (route == '/pharmacy') {
      setState(() => _selectedIndex = 1);
    } else if (route == '/myAppointments') {
      setState(() => _selectedIndex = 2);
    } else if (route == '/predictionResult') {
      setState(() => _selectedIndex = 3);
    }
  }

  @override
  Widget build(BuildContext context) {
    /// 🔥 핵심 포인트: 화면을 매 빌드마다 "최신 상태"로 생성해야
    /// 환자데이터 로딩 후 doctor 화면이 정상 업데이트됨.
    final List<Widget> pages = () {
      switch (widget.user.role) {
        case 'staff' :
          return [
            StaffMainPage(),
            MyInfoPage(user: widget.user,) ];
        case 'general':
        case 'patient':
          return [
            PatientMainPage(onCategorySelected: _onCategorySelected),
            PharmacyView(),
            MyAppointments(),
            PredictionResult(),
            MyInfoPage(user: widget.user,),
          ];

        case 'doctor':
          return [
            DoctorMainPage(
              user: widget.user,
              patients: myPatients,
              isLoading: isLoading,
              onPatientsChanged: _loadPatients,
            ),
            MyAllPatientView(
              patients: myPatients,
              isLoading: isLoading,
            ),
            MyInfoPage(user: widget.user),
          ];

        case 'admin':
          return [
            AdminMainPage(onTabSelected: _onNavItemTapped),
            ApprovalPage(),
            UserListPage(),
            MyInfoPage(user: widget.user)
          ];

        default:
          return [
            PatientMainPage(),
            DoctorMainPage(user: widget.user),
            AdminMainPage(),
            MyInfoPage(user: widget.user,)
          ];
      }
    }();

    final List<MenuCategory> menuList = () {
      switch (widget.user.role) {
        case 'staff':
          return staffMenu;
        case 'general':
        case 'patient':
          return patientMenu;
        case 'doctor':
          return doctorMenu;
        case 'admin':
          return adminMenu;
        default:
          return menu_categories;
      }
    }();

    return Scaffold(
      body: SafeArea(
        child: pages[_selectedIndex],
      ),
      bottomNavigationBar: SafeArea(
        child: BottomNavBar(
          currentIndex: _selectedIndex,
          onTap: _onNavItemTapped,
          menuList: menuList,
        ),
      ),
    );
  }
}