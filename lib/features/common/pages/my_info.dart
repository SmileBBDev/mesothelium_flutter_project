import 'package:flutter/material.dart';

class MyInfoPage extends StatelessWidget {
  const MyInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // AppBar 대체
            Container(
              color: Theme.of(context).primaryColor,
              child: SafeArea(
                child: Container(
                  height: kToolbarHeight,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: const Text(
                    "내 정보",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

            // Body
            const SizedBox(height: 200, child: Center(child: Text("내 정보 페이지입니다"))),
          ],
        ),
      ),
    );
  }
}