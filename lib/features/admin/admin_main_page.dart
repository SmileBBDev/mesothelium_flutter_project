
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../constants.dart';
import '../../core/widgets/botton_nav_bar.dart';
import 'ApprovalPage.dart';

class AdminMainPage extends StatefulWidget{
  static String url = '/adminMain';
  final Function(int)? onTabSelected;
  const AdminMainPage({this.onTabSelected});

  @override
  _AdminMainPageState createState() => _AdminMainPageState();
}
class _AdminMainPageState extends State<AdminMainPage> {
  final int totalUsers = 120;
  final int pendingUsers = 3;
  final int todayUsers = 2;

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
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 제목
            Text(
              '회원관리',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 20),

            // 통계 카드 3개
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatCard('총 회원', totalUsers.toString(), Colors.blue),
                _buildStatCard('승인 대기', pendingUsers.toString(), Colors.orange),
                _buildStatCard('오늘 가입', todayUsers.toString(), Colors.green),
              ],
            ),
            SizedBox(height: 32),

            // 회원 승인 관리 버튼 => 메뉴바 순서 번호로 하드코딩 되어있음(수정필요)
            ElevatedButton.icon(
              onPressed: () => widget.onTabSelected?.call(1),
              icon: Icon(Icons.verified_user),
              label: Text('회원 승인 관리'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
                backgroundColor: Colors.blueGrey.shade700,
                foregroundColor: Colors.white,
                textStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,

              ),
            ),
            SizedBox(height: 16),

            // 전체 회원 조회 버튼
            ElevatedButton.icon(
              onPressed: () => widget.onTabSelected?.call(2),
              icon: Icon(Icons.people),
              label: Text('전체 회원 조회'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
                backgroundColor: Colors.blueGrey.shade700,
                foregroundColor: Colors.white,
                textStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 통계 카드 위젯
  Widget _buildStatCard(String title, String count, Color color) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 4),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(
              count,
              style: TextStyle(
                fontSize: 20,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
