import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../constants.dart';

class CategorySection extends StatelessWidget {
  final void Function(String route)? onCategorySelected; // 부모에서 전달됨
  const CategorySection({super.key, this.onCategorySelected});

  @override
  Widget build(BuildContext context) {
    final categories = [
      {"icon": "assets/icons/Pediatrician.svg", "name": "근처 약국", "route": "/pharmacy"},
      {"icon": "assets/icons/Neurosurgeon.svg", "name": "질병정보", "route": "/disease"},
      {"icon": "assets/icons/Cardiologist.svg", "name": "진료 예약", "route": "/myAppointments"},
      {"icon": "assets/icons/Psychiatrist.svg", "name": "진단결과", "route": "/predictionResult"},
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
                  child : GestureDetector(
                    onTap: (){
                      if(item["route"] == "/disease"){
                        Navigator.of(context, rootNavigator: false).pushNamed(item["route"]!);

                      } else { // 질병정보 외에 메뉴들
                        onCategorySelected?.call(item["route"]!);
                      }
                    },
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
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
