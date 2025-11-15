// 원무과 메인 페이지
import 'package:flutter/material.dart';
import 'user_approval_list.dart';
import 'patient_management_list.dart';
import 'bulk_register_page.dart';

class StaffMainPage extends StatelessWidget {
  const StaffMainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('원무과 관리'),
          bottom: const TabBar(
            tabs: [
              Tab(text: '승인 관리', icon: Icon(Icons.pending_actions)),
              Tab(text: '환자 관리', icon: Icon(Icons.people)),
              Tab(text: '대량 등록', icon: Icon(Icons.group_add)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            UserApprovalList(),
            PatientManagementList(),
            BulkRegisterPage(),
          ],
        ),
      ),
    );
  }
}
