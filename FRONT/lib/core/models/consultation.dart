class Consultation {
  final int id;
  final int patientId;
  final String? patientName; // Add this field
  final int doctorId;
  final String status;
  final bool isEmergency;
  final String? consultationDate;
  final String createdAt;
  final String type; // Add this field


  Consultation({
    required this.id,
    required this.patientId,
    this.patientName, // Make optional for now
    required this.doctorId,
    required this.status,
    required this.isEmergency,
    this.consultationDate,
    required this.createdAt,
    required this.type, // Add to constructor

  });

  factory Consultation.fromJson(Map<String, dynamic> json) {
    return Consultation(
      id: json['id'],
      patientId: json['patient_id'],
      patientName: json['patient_name'], // Parse from JSON if available
      doctorId: json['doctor_id'],
      status: json['status'],
      isEmergency: json['is_emergency'],
      consultationDate: json['consultation_date'],
      createdAt: json['created_at'],
      type: json['type'] ?? 'text', // Parse from JSON with fallback

    );
  }
}