class Consultation {
  final int id;
  final int patientId;
  final String? patientName;
  final int? patientAge;
  final String? patientGender;
  final String type;
  final String status;
  final DateTime? consultationDate;
  final bool isEmergency;
  final DateTime? createdAt;

  Consultation({
    required this.id,
    required this.patientId,
    this.patientName,
    this.patientAge,
    this.patientGender,
    required this.type,
    required this.status,
    this.consultationDate,
    required this.isEmergency,
    this.createdAt,
  });

  factory Consultation.fromJson(Map<String, dynamic> json) {
    return Consultation(
      id: json['consultation_id'] ?? 0,
      patientId: json['user_id'] ?? 0,
      patientName: json['patient_name'],
      patientAge: json['patient_age'],
      patientGender: json['patient_gender'],
      type: json['type'] ?? '',
      status: json['status'] ?? '',
      consultationDate: json['consultation_date'] != null ? 
        DateTime.parse(json['consultation_date']) : null,
      isEmergency: json['is_emergency'] ?? false,
      createdAt: json['created_at'] != null ? 
        DateTime.parse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'consultation_id': id,
      'user_id': patientId,
      'patient_name': patientName,
      'patient_age': patientAge,
      'patient_gender': patientGender,
      'type': type,
      'status': status,
      'consultation_date': consultationDate?.toIso8601String(),
      'is_emergency': isEmergency,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}