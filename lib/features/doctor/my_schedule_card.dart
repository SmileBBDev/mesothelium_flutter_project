// 의사 진료 스케줄 조회 ui
import 'package:flutter/material.dart';
import 'package:flutter_diease_app/features/doctor/patient_card.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

import '../../core/model/patient.dart';
import '../../core/utils/parse_reservation_date.dart';
import '../../core/service/auth_service.dart';

class MyScheduleCard extends StatefulWidget {
  final int? userId;
  final List<Patient> patients;
  final AuthUser? user;
  const MyScheduleCard({super.key, this.userId, required this.patients, this.user});

  @override
  State<MyScheduleCard> createState() => _MyScheduleCardState();
}

class _MyScheduleCardState extends State<MyScheduleCard> {
  DateTime? _selectedDate;
  late final DateTime _today;
  late final List<Appointment> _appointments;
  final CalendarController _calendarController = CalendarController();

  @override
  void initState() {
    super.initState();

    // 오늘 날짜 기준
    _today = DateTime.now();
    _selectedDate  = DateTime(_today.year, _today.month, _today.day);

    // DB에서 받아온 데이터 기준으로 진료 일정 생성
    // ✅ reservation_date가 null이 아닌 환자만 일정으로 추가
    _appointments = widget.patients
        .where((p) => p.reservationDate != null)
        .map((p) {
      // DB 저장된 날짜를 DateTime으로 변환
      final DateTime startTime = parseReservationDate(p.reservationDate);

      final int age = DateTime.now().year - p.birthYear;

      return Appointment(
        startTime: startTime,
        endTime: startTime.add(Duration(minutes: 30)),
        subject: p.name ?? "",
        notes: "${p.id} | ${p.createdByUsername ?? '등록자 없음'} | ${age != null ? '$age세' : '나이 모름'} | ${p.gender ?? '성별 미기입'} ",
        color: Colors.indigoAccent,
      );
    }).toList();
  }

  List<Map<String, String>> _getEventsForDay(DateTime date) {
    final events = _appointments.where((a) =>
    a.startTime.year == date.year &&
        a.startTime.month == date.month &&
        a.startTime.day == date.day);

    return events.map((a) {
      final parts = a.notes?.split('|') ?? [];
      // notes 형식: "patientId | 등록자 | 나이 | 성별"
      final patientId = parts.isNotEmpty ? parts[0].trim() : "0";
      final age = parts.length > 2 ? parts[2].trim().replaceAll(RegExp(r'[^0-9]'), '') : "";
      final gender = parts.length > 3 && parts[3].contains("M") ? "남성" : "여성";

      return {
        "id": patientId,  // ⭐ patient ID 추가
        "time": "${a.startTime.hour.toString().padLeft(2, '0')}:${a.startTime.minute.toString().padLeft(2, '0')} - ${a.endTime.hour.toString().padLeft(2, '0')}:${a.endTime.minute.toString().padLeft(2, '0')}",
        "name": a.subject,
        "dept": parts.length > 1 ? parts[1].trim() : "",
        "age": age,
        "gender": gender,
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final selectedEvents = _getEventsForDay(_selectedDate ?? DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 헤더
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("진료 일정",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigoAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  textStyle: const TextStyle(fontSize: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate ?? _today,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      _selectedDate = pickedDate;
                      _calendarController.displayDate = pickedDate;
                      _calendarController.selectedDate = pickedDate;
                    });
                  }
                },
                child: const Text("날짜 선택"),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // 달력 카드
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.grey.shade200, blurRadius: 8),
              ],
            ),
            height: 360,
            child: SfCalendar(
              controller: _calendarController,
              view: CalendarView.month,
              initialDisplayDate: _today, //DateTime(2025, 11, 12),
              initialSelectedDate: _today, //DateTime(2025, 11, 12),
              dataSource: AppointmentDataSource(_appointments),
              showNavigationArrow: true,
              onSelectionChanged: (args) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  setState(() {
                    _selectedDate = args.date;
                  });
                });
              },
              monthViewSettings: const MonthViewSettings(
                appointmentDisplayMode: MonthAppointmentDisplayMode.indicator,
                showAgenda: false,
              ),
              todayHighlightColor: Colors.grey,
              selectionDecoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.3),
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(100),

              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 일정 목록
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: PatientCard(patients: selectedEvents, user: widget.user),

        ),
      ],
    );
  }
}

// Syncfusion Calendar용 데이터소스
class AppointmentDataSource extends CalendarDataSource {
  AppointmentDataSource(List<Appointment> source) {
    appointments = source;
  }
}