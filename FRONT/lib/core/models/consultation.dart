class Consultation {
  final int id;
  final String status;
  final String type;
  final bool isEmergency;
  final DateTime? consultationDate;
  final DateTime? createdAt;
  
  // Patient info
  final int patientId;
  final String? patientName;
  
  // Doctor info (may need to be fetched separately)
  final int? doctorId;
  final String? doctorName;
  final String? doctorSpecialty;
  
  // Extra fields from API that might be useful
  final String? patientEmail;
  final int? patientAge;
  final String? patientGender;

  Consultation({
    required this.id,
    required this.status,
    required this.type,
    required this.isEmergency,
    required this.patientId,
    this.consultationDate,
    this.createdAt,
    this.patientName,
    this.doctorId,
    this.doctorName,
    this.doctorSpecialty,
    this.patientEmail,
    this.patientAge,
    this.patientGender,
  });

  factory Consultation.fromJson(Map<String, dynamic> json) {
    return Consultation(
      // Map consultation_id to id
      id: json['consultation_id'] ?? json['id'] ?? 0,
      
      // Basic consultation fields
      status: json['status'] ?? 'pending',
      type: json['type'] ?? 'text',
      isEmergency: json['is_emergency'] ?? false,
      
      // Date fields - handle both string and DateTime
      consultationDate: json['consultation_date'] != null 
          ? json['consultation_date'] is String 
              ? DateTime.parse(json['consultation_date']) 
              : json['consultation_date']
          : null,
      
      createdAt: json['consultation_created_at'] != null || json['created_at'] != null
          ? (json['consultation_created_at'] ?? json['created_at']) is String
              ? DateTime.parse(json['consultation_created_at'] ?? json['created_at'])
              : (json['consultation_created_at'] ?? json['created_at'])
          : DateTime.now(),
      
      // Patient info
      patientId: json['patient_id'] ?? 0,
      patientName: json['patient_name'],
      patientEmail: json['email'],
      patientAge: json['age'],
      patientGender: json['gender'],
      
      // Doctor info - might need to be fetched separately
      doctorId: json['doctor_id'],
      doctorName: json['doctor_name'] ?? json['doctor_full_name'],
      doctorSpecialty: json['doctor_specialty'] ?? json['specialty'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status,
      'type': type,
      'is_emergency': isEmergency,
      'consultation_date': consultationDate?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'patient_id': patientId,
      'patient_name': patientName,
      'doctor_id': doctorId,
      'doctor_name': doctorName,
      'doctor_specialty': doctorSpecialty,
    };
  }
}