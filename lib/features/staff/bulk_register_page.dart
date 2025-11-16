import 'package:flutter/material.dart';
import '../../core/service/staff_service.dart';

class BulkRegisterPage extends StatefulWidget {
  const BulkRegisterPage({Key? key}) : super(key: key);

  @override
  State<BulkRegisterPage> createState() => _BulkRegisterPageState();
}

class _BulkRegisterPageState extends State<BulkRegisterPage> {
  final StaffService _staffService = StaffService();
  final _formKey = GlobalKey<FormState>();

  List<UserRegistrationData> _users = [
    UserRegistrationData(),
  ];

  bool _isLoading = false;
  BulkRegisterResult? _lastResult;

  void _addUser() {
    setState(() {
      _users.add(UserRegistrationData());
    });
  }

  void _removeUser(int index) {
    if (_users.length > 1) {
      setState(() {
        _users.removeAt(index);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _lastResult = null;
    });

    try {
      final usersData = _users.map((user) => user.toJson()).toList();
      final result = await _staffService.bulkRegister(usersData);

      setState(() {
        _lastResult = result;
        _isLoading = false;
      });

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? '등록이 완료되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );

        // 성공한 경우 폼 초기화
        setState(() {
          _users = [UserRegistrationData()];
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? '등록에 실패했습니다.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('오류가 발생했습니다: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('대량 회원 등록'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addUser,
            tooltip: '사용자 추가',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _users.length,
                itemBuilder: (context, index) {
                  return _buildUserCard(index);
                },
              ),
            ),
          ),
          if (_lastResult != null) _buildResultSection(),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildUserCard(int index) {
    final user = _users[index];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '사용자 ${index + 1}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_users.length > 1)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removeUser(index),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: '아이디',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '아이디를 입력해주세요';
                }
                return null;
              },
              onChanged: (value) => user.username = value,
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(
                labelText: '비밀번호',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '비밀번호를 입력해주세요';
                }
                return null;
              },
              onChanged: (value) => user.password = value,
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(
                labelText: '이름',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '이름을 입력해주세요';
                }
                return null;
              },
              onChanged: (value) => user.name = value,
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(
                labelText: '이메일',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              onChanged: (value) => user.email = value,
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(
                labelText: '전화번호',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              onChanged: (value) => user.phone = value,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: '역할',
                border: OutlineInputBorder(),
              ),
              value: user.role,
              items: const [
                DropdownMenuItem(value: 'patient', child: Text('환자')),
                DropdownMenuItem(value: 'staff', child: Text('직원')),
                DropdownMenuItem(value: 'general', child: Text('일반')),
              ],
              onChanged: (value) {
                setState(() {
                  user.role = value ?? 'patient';
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultSection() {
    final result = _lastResult!;
    final results = result.results;

    if (results == null) return const SizedBox.shrink();

    final successList = results['success'] as List? ?? [];
    final failedList = results['failed'] as List? ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '등록 결과',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (successList.isNotEmpty) ...[
            Text(
              '성공: ${successList.length}명',
              style: const TextStyle(color: Colors.green),
            ),
            ...successList.map((user) => Text(
                  '  ✓ ${user['username']} (${user['name']})',
                  style: const TextStyle(fontSize: 12),
                )),
          ],
          if (failedList.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '실패: ${failedList.length}명',
              style: const TextStyle(color: Colors.red),
            ),
            ...failedList.map((user) => Text(
                  '  ✗ ${user['username']}: ${user['reason']}',
                  style: const TextStyle(fontSize: 12),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _isLoading ? null : _addUser,
              icon: const Icon(Icons.add),
              label: const Text('사용자 추가'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text('${_users.length}명 등록하기'),
            ),
          ),
        ],
      ),
    );
  }
}

class UserRegistrationData {
  String username = '';
  String password = '';
  String name = '';
  String email = '';
  String phone = '';
  String role = 'patient';

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
    };
  }
}
