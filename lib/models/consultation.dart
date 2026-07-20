import 'dart:convert';

class ConsultationRecord {
  final String? consultationId;
  final String? patientId;
  final String? doctorId;
  final String? doctorName;
  final String? appointmentId;
  final String? consultationDate;
  final String? consultationTime;
  final List<String> imageUrls;
  final Map<String, String> vitals;
  final List<Map<String, String>> medications;
  final String? clinicalNotes;
  final String? labData;
  final int status;

  ConsultationRecord({
    this.consultationId,
    this.patientId,
    this.doctorId,
    this.doctorName,
    this.appointmentId,
    this.consultationDate,
    this.consultationTime,
    this.imageUrls = const [],
    this.vitals = const {},
    this.medications = const [],
    this.clinicalNotes,
    this.labData,
    this.status = 0,
  });

  factory ConsultationRecord.fromJson(Map<String, dynamic> json) {
    // Handle Image URLs
    List<String> images = [];
    if (json['image_urls'] is List) {
      images = List<String>.from(json['image_urls']);
    }

    // Handle Vitals JSON
    Map<String, String> vitalsMap = {};
    if (json['vital_signs'] != null && json['vital_signs'].toString().isNotEmpty) {
      try {
        final decoded = jsonDecode(json['vital_signs']);
        if (decoded is Map) {
          vitalsMap = decoded.map((k, v) => MapEntry(k.toString().toLowerCase(), v.toString()));
        }
      } catch (_) {}
    }

    // Handle Medications JSON (soap_plan)
    List<Map<String, String>> medsList = [];
    if (json['soap_plan'] != null && json['soap_plan'].toString().isNotEmpty) {
      try {
        final decoded = jsonDecode(json['soap_plan']);
        if (decoded is List) {
          medsList = decoded.map((m) {
            if (m is Map) {
              return m.map((k, v) => MapEntry(k.toString(), v.toString()));
            }
            return <String, String>{};
          }).toList();
        }
      } catch (_) {}
    }

    return ConsultationRecord(
      consultationId: json['consultation_id'],
      patientId: json['patient_id'],
      doctorId: json['doctor_id'],
      doctorName: json['doctor_name'],
      appointmentId: json['appointment_id'],
      consultationDate: json['consultation_date'],
      consultationTime: json['consultation_time'],
      imageUrls: images,
      vitals: vitalsMap,
      medications: medsList,
      clinicalNotes: json['clinical_notes'],
      labData: json['soap_objective'],
      status: int.tryParse(json['status']?.toString() ?? '0') ?? 0,
    );
  }
}
