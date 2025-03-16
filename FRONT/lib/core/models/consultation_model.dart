// lib/core/models/consultation_model.dart
class ConsultationModel {
  final int id;
  final int patientId;
  final String patientName;
  final int doctorId;
  final String type;
  final bool isEmergency;
  final String status;
  final DateTime? consultationDate;

  ConsultationModel({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.doctorId,
    required this.type,
    required this.isEmergency,
    required this.status,
    this.consultationDate,
  });

  factory ConsultationModel.fromJson(Map<String, dynamic> json) {
    return ConsultationModel(
      id: json['id'],
      patientId: json['patient_id'],
      patientName: json['patient_name'] ?? 'Unknown Patient',
      doctorId: json['doctor_id'],
      type: json['type'] ?? 'video',
      isEmergency: json['is_emergency'] ?? false,
      status: json['status'] ?? 'pending',
      consultationDate: json['consultation_date'] != null
          ? DateTime.parse(json['consultation_date'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_id': patientId,
      'patient_name': patientName,
      'doctor_id': doctorId,
      'type': type,
      'is_emergency': isEmergency,
      'status': status,
      'consultation_date': consultationDate?.toIso8601String(),
    };
  }
}