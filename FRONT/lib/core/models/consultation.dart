// lib/core/models/consultation.dart

class Consultation {
  final int id;
  final int patientId;
  final String? patientName;
  final int doctorId;
  final String? doctorName;
  final String? doctorSpecialty;
  final String type;
  final String status;
  final bool isEmergency;
  final dynamic consultationDate;
  final dynamic createdAt;

  Consultation({
    required this.id,
    required this.patientId,
    this.patientName,
    required this.doctorId,
    this.doctorName,
    this.doctorSpecialty,
    required this.type,
    required this.status,
    required this.isEmergency,
    this.consultationDate,
    this.createdAt,
  });

  factory Consultation.fromJson(Map<String, dynamic> json) {
    return Consultation(
      id: json['id'] ?? json['consultation_id'] ?? 0,
      patientId: json['patient_id'] ?? 0,
      patientName: json['patient_name'],
      doctorId: json['doctor_id'] ?? 0,
      doctorName: json['doctor_name'],
      doctorSpecialty: json['doctor_specialty'] ?? json['specialties'],
      type: json['type'] ?? 'unknown',
      status: json['status'] ?? 'pending',
      isEmergency: json['is_emergency'] ?? false,
      consultationDate: json['consultation_date'],
      createdAt: json['created_at'] ?? json['consultation_created_at'],
    );
  }

  // Helper method to safely get consultation date as DateTime
  DateTime? getConsultationDateTime() {
    if (consultationDate == null) return null;
    
    try {
      if (consultationDate is DateTime) {
        return consultationDate;
      } else if (consultationDate is String) {
        return DateTime.parse(consultationDate);
      }
      return null;
    } catch (e) {
      print('Error parsing consultation date: $e');
      return null;
    }
  }

  // Helper method to safely get created date as DateTime
  DateTime? getCreatedAtDateTime() {
    if (createdAt == null) return null;
    
    try {
      if (createdAt is DateTime) {
        return createdAt;
      } else if (createdAt is String) {
        return DateTime.parse(createdAt);
      }
      return null;
    } catch (e) {
      print('Error parsing created date: $e');
      return null;
    }
  }
}