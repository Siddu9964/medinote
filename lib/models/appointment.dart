class Appointment {
  final String appointmentId;
  final String patientId;
  final String patientName;
  final String phoneNumber;
  final String age;
  final String gender;
  final DateTime? appointmentDate;
  final int status; // 1: Active, 0: Completed
  final String? birthDate;
  final String? bloodGroup;
  final String? doctorName;
  final String? complaint;
  final String? vitalSigns;

  Appointment({
    required this.appointmentId,
    required this.patientId,
    required this.patientName,
    required this.phoneNumber,
    required this.age,
    required this.gender,
    this.appointmentDate,
    this.status = 1,
    this.birthDate,
    this.bloodGroup,
    this.doctorName,
    this.complaint,
    this.vitalSigns,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    if (json['appointment_date'] != null) {
      String datePart = json['appointment_date'].toString();
      String timePart = json['appointment_time']?.toString() ?? '00:00:00';
      parsedDate = DateTime.tryParse("$datePart $timePart");
    }

    return Appointment(
      appointmentId: json['appointment_id']?.toString() ?? '',
      patientId: json['patient_id']?.toString() ?? '',
      patientName: json['patient_name']?.toString() ?? 'Unknown',
      phoneNumber: json['phone_number']?.toString() ?? 'N/A',
      age: json['age']?.toString() ?? 'N/A',
      gender: json['patient_gender']?.toString() ?? 'N/A',
      appointmentDate: parsedDate,
      status: int.tryParse(json['appointment_status']?.toString() ?? '1') ?? 1,
      birthDate: json['birth_date']?.toString(),
      bloodGroup: json['blood_group']?.toString(),
      doctorName: json['doctor_name']?.toString(),
      complaint: json['complaint']?.toString(),
      vitalSigns: json['vital_signs']?.toString(),
    );
  }
}
