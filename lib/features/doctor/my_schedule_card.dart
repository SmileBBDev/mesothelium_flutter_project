// 의사 진료 스케줄 조회 ui
import 'package:flutter/material.dart';
import 'package:flutter_diease_app/features/doctor/patient_card.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';


import '../../constants.dart';
import '../../core/model/patient.dart';
import '../../core/utils/parseReservationDate.dart';

class MyScheduleCard extends StatefulWidget {
  final int? userId;
  final List<Patient> patients;
  const MyScheduleCard({super.key, this.userId, required this.patients});

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
    _appointments = widget.patients.map((p) {
      // DB 저장된 날짜를 DateTime으로 변환
      final DateTime startTime = parseReservationDate(p.reservationDate);

      final int age = DateTime.now().year - p.birthYear;

      return Appointment(
        startTime: startTime,
        endTime: startTime.add(Duration(minutes: 30)),
        subject: p.name ?? "",
        notes: "${p.createdByUsername ?? '등록자 없음'} | ${age != null ? '$age세' : '나이 모름'}",
        color: Colors.indigoAccent,
      );
    }).toList();
  }

  List<Map<String, String>> _getEventsForDay(DateTime date) {
    final events = _appointments.where((a) =>
    a.startTime.year == date.year &&
        a.startTime.month == date.month &&
        a.startTime.day == date.day);

    return events.map((a) => {
      "time":
      "${a.startTime.hour.toString().padLeft(2, '0')}:${a.startTime.minute.toString().padLeft(2, '0')} - ${a.endTime.hour.toString().padLeft(2, '0')}:${a.endTime.minute.toString().padLeft(2, '0')}",
      "name": a.subject,
      "dept": a.notes?.split('|').first.trim() ?? "",
      "age": a.notes
          ?.split('|')
          .last
          .trim()
          .replaceAll(RegExp(r'[^0-9]'), '') ??
          "",
      "gender": (a.notes ?? "").contains("남") ? "남성" : "여성",
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
                color: Colors.blue.withOpacity(0.3),
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
          child: PatientCard(patients: selectedEvents),
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