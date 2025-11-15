class Patient {
  final int id;
  final String name;
  final int birthYear;
  final String phone;
  final String gender;
  final String reservationDate;
  final int createdById;
  final String createdByUsername;
  final String createdAt;

  final List<AssignedDoctor> assignedDoctors;

  Patient({
    required this.id,
    required this.name,
    required this.birthYear,
    required this.phone,
    required this.gender,
    required this.reservationDate,
    required this.createdById,
    required this.createdByUsername,
    required this.createdAt,
    required this.assignedDoctors,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'],
      name: json['name'] ?? '',
      gender: json['sex'] ?? '',
      reservationDate: json['reservation_date'] ?? '',
      birthYear: json['birth_year'] ?? 0,
      phone: json['phone'] ?? '',
      createdById: json['created_by_id'] ?? 0,
      createdByUsername: json['created_by_username'] ?? '',
      createdAt: json['created_at'] ?? '',
      assignedDoctors: (json['assigned_doctors_info'] as List<dynamic>?)
          ?.map((e) => AssignedDoctor.fromJson(e))
          .toList()
          ?? [],
    );
  }
}

class AssignedDoctor {
  final int id;
  final int userId;
  final String username;
  final String role;
  final String licenseNumber;
  final String department;

  AssignedDoctor({
    required this.id,
    required this.userId,
    required this.username,
    required this.role,
    required this.licenseNumber,
    required this.department,
  });

  factory AssignedDoctor.fromJson(Map<String, dynamic> json) {
    return AssignedDoctor(
      id: json['id'],
      userId: json['user_id'],
      username: json['username'] ?? '',
      role: json['role'] ?? '',
      licenseNumber: json['license_number'] ?? '',
      department: json['department'] ?? '',
    );
  }
}
