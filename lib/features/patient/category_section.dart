import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../constants.dart';

class CategorySection extends StatelessWidget {
  const CategorySection({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = [
      {"icon": "assets/icons/Pediatrician.svg", "name": "근처 약국"},
      {"icon": "assets/icons/Neurosurgeon.svg", "name": "질병정보"},
      {"icon": "assets/icons/Cardiologist.svg", "name": "내 예약"},
      {"icon": "assets/icons/Psychiatrist.svg", "name": "진단예측"},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text("카테고리", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              Text("See All", style: TextStyle(color: Colors.blue)),
            ],
          ),
        ),
        SizedBox(height: defaultPadding),
        SizedBox(
          height:90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final item = categories[index];
              return Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Container(
                  width: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 3,
                      )
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      //Image.asset(item["icon"]!, height: 40),
                      SvgPicture.asset(item["icon"]!, height:28),
                      const SizedBox(height: 8),
                      Text(item["name"]!, style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
