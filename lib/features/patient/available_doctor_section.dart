import 'package:flutter/material.dart';

import '../../constants.dart';
class AvailableDoctorSection extends StatelessWidget {
  const AvailableDoctorSection({super.key});

  @override
  Widget build(BuildContext context) {
    final doctors = [
      {"name": "Dr. Serena Gomez", "speciality": "Medicine Specialist", "experience": "8 Years", "patients": "1.08K", "image": "assets/images/search_doc_1.png"},
      {"name": "Dr. Serena Gomez", "speciality": "Medicine Specialist", "experience": "8 Years", "patients": "1.08K", "image": "assets/images/search_doc_2.png"},
      {"name": "Dr. Asma Khan", "speciality": "Heart Specialist", "experience": "5 Years", "patients": "2.7K", "image": "assets/images/search_doc_3.png"},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text("Available Doctor", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              Text("See All", style: TextStyle(color: Colors.blue)),
            ],
          ),
        ),
        SizedBox(height: defaultPadding),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: doctors.length,
            itemBuilder: (context, index) {
              final doctor = doctors[index];
              return Container(
                width: 200,
                margin: const EdgeInsets.only(left: 16, right: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.asset(doctor["image"]!, height: 65),
                    const SizedBox(height: 8),
                    Text(doctor["name"]!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(doctor["speciality"]!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Text("Experience: ${doctor["experience"]}", style: const TextStyle(fontSize: 12)),
                    Text("Patients: ${doctor["patients"]}", style: const TextStyle(fontSize: 12)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
