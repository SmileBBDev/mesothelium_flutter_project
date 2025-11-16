import 'package:flutter/material.dart';
import '../../core/constants/MenuCategory.dart';
import '../../core/service/auth_service.dart';
import '../admin/ApprovalPage.dart';
import '../admin/UserListPage.dart';
import '../../core/widgets/botton_nav_bar.dart';
import '../admin/admin_main_page.dart';
import '../common/pages/my_info.dart';
import '../doctor/doctor_main_page.dart';
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
  int _selectedIndex = 0; // 현재 선택된 탭 인덱스
  late List<Widget> _pages;
  late List<MenuCategory> _menuList;

  @override
  void initState() {
    super.initState();
    // 역할에 따른 footbar 구분
    switch (widget.user.role) {
      case 'patient':
        _pages = [
          PatientMainPage(onCategorySelected: _onCategorySelected),
          PharmacyView(),
          MyAppointments(),
          PredictionResult(),
          MyInfoPage()
        ];
        _menuList = patientMenu;
        break;
      case 'doctor':
        _pages = [DoctorMainPage(user:widget.user), MyInfoPage()];
        _menuList = doctorMenu;
        break;
      case 'admin':
        _pages = [AdminMainPage(onTabSelected: _onNavItemTapped), ApprovalPage(), UserListPage(), MyInfoPage()];
        _menuList = adminMenu;
        break;
      case 'staff':
        // 원무과 역할: 승인 관리, 환자 관리, 대량 등록
        _pages = [StaffMainPage(), MyInfoPage()];
        _menuList = staffMenu;
        break;
      default:
        // 일반 사용자(general) 또는 알 수 없는 역할 → 환자 화면으로 처리
        _pages = [
          PatientMainPage(onCategorySelected: _onCategorySelected),
          PharmacyView(),
          MyAppointments(),
          PredictionResult(),
          MyInfoPage()
        ];
        _menuList = patientMenu;
        break;
    }
  }

  void _onNavItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // 메뉴 탭 번호 지정
  void _onCategorySelected(String route) {
    // 환자 메뉴 탭 이동
    if (route == '/pharmacy') {
      setState(() {
        _selectedIndex = 1; // 약국 탭으로 이동
      });
    } else if (route == '/myAppointments') {
      setState(() {
        _selectedIndex = 2; // 예약 탭
      });
    } else if (route == '/predictionResult') {
      setState(() {
        _selectedIndex = 3; // 예측결과 탭
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: SafeArea(
        child:  _pages[_selectedIndex],
      ),


      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onNavItemTapped,
        menuList: _menuList,
      ),

    );
  }
}
