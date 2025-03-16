class Consultation {
  final int id;
  final int patientId;
  final String? patientName;
  final int doctorId;
  final String? doctorName;
  final String type;
  final String description;
  final bool isEmergency;
  final String status;
  final DateTime? consultationDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  Consultation({
    required this.id,
    required this.patientId,
    this.patientName,
    required this.doctorId,
    this.doctorName,
    required this.type,
    required this.description,
    required this.isEmergency,
    required this.status,
    this.consultationDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Consultation.fromJson(Map<String, dynamic> json) {
    return Consultation(
      id: json['id'],
      patientId: json['patient_id'],
      patientName: json['patient_name'],
      doctorId: json['doctor_id'],
      doctorName: json['doctor_name'],
      type: json['type'],
      description: json['description'],
      isEmergency: json['is_emergency'] ?? false,
      status: json['status'],
      consultationDate: json['consultation_date'] != null 
          ? DateTime.parse(json['consultation_date']) 
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_id': patientId,
      'patient_name': patientName,
      'doctor_id': doctorId,
      'doctor_name': doctorName,
      'type': type,
      'description': description,
      'is_emergency': isEmergency,
      'status': status,
      'consultation_date': consultationDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}