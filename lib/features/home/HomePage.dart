import 'package:flutter/material.dart';
import '../../core/constants/MenuCategory.dart';
import '../admin/ApprovalPage.dart';
import '../admin/UserListPage.dart';
import '../../core/widgets/botton_nav_bar.dart';
import '../admin/admin_main_page.dart';
import '../common/pages/my_info.dart';
import '../doctor/doctor_main_page.dart';
import '../patient/Patient_main_page.dart';

class HomePage extends StatefulWidget {
  static String url = '/homePage';
  final String role;

  const HomePage({super.key, required this.role});

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
    switch (widget.role) {
      case 'patient':
        _pages = [PatientMainPage(), MyInfoPage()];
        _menuList = patientMenu;
        break;
      case 'doctor':
        _pages = [DoctorMainPage(), MyInfoPage()];
        _menuList = doctorMenu;
        break;
      case 'admin':
        _pages = [AdminMainPage(onTabSelected: _onNavItemTapped), ApprovalPage(), UserListPage(), MyInfoPage()];
        _menuList = adminMenu;
        break;
      default:
        _pages = [PatientMainPage(), DoctorMainPage(), AdminMainPage(), MyInfoPage()];
        _menuList = menu_categories;

    }
  }

  void _onNavItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: _pages[_selectedIndex],
        ),
      ),


      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onNavItemTapped,
        menuList: _menuList,
      ),

    );
  }
}
