class Consultation {
  final int id;
  final int patientId;
  final String? patientName;
  final String type;
  final String status;
  final bool isEmergency;
  final DateTime? consultationDate;
  final DateTime createdAt;
  final String? description;
  final String? symptoms;
  final String? diagnosis;
  final String? prescription;
  final String? notes;

  Consultation({
    required this.id,
    required this.patientId,
    this.patientName,
    required this.type,
    required this.status,
    required this.isEmergency,
    this.consultationDate,
    required this.createdAt,
    this.description,
    this.symptoms,
    this.diagnosis,
    this.prescription,
    this.notes,
  });

  factory Consultation.fromJson(Map<String, dynamic> json) {
    // Handle consultation_id or id field
    int consultationId = 0;
    if (json.containsKey('consultation_id') && json['consultation_id'] != null) {
      consultationId = json['consultation_id'];
    } else if (json.containsKey('id') && json['id'] != null) {
      consultationId = json['id'];
    }

    // Handle patient_id field which might be null in some responses
    int patientId = 0;
    if (json.containsKey('patient_id') && json['patient_id'] != null) {
      patientId = json['patient_id'];
    } else if (json.containsKey('patientId') && json['patientId'] != null) {
      patientId = json['patientId'];
    }

    // Handle creation date
    DateTime createdAt = DateTime.now();
    if (json.containsKey('created_at') && json['created_at'] != null) {
      createdAt = DateTime.parse(json['created_at']);
    } else if (json.containsKey('consultation_created_at') && json['consultation_created_at'] != null) {
      createdAt = DateTime.parse(json['consultation_created_at']);
    } else if (json.containsKey('createdAt') && json['createdAt'] != null) {
      createdAt = DateTime.parse(json['createdAt']);
    }

    return Consultation(
      id: consultationId,
      patientId: patientId,
      patientName: json['patient_name'] ?? json['patientName'],
      type: json['type'] ?? 'text',
      status: json['status'] ?? 'pending',
      isEmergency: json['is_emergency'] ?? json['isEmergency'] ?? false,
      consultationDate: json['consultation_date'] != null 
          ? DateTime.parse(json['consultation_date']) 
          : (json['consultationDate'] != null 
              ? DateTime.parse(json['consultationDate']) 
              : null),
      createdAt: createdAt,
      description: json['description'],
      symptoms: json['symptoms'],
      diagnosis: json['diagnosis'],
      prescription: json['prescription'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_id': patientId,
      'patient_name': patientName,
      'type': type,
      'status': status,
      'is_emergency': isEmergency,
      'consultation_date': consultationDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'description': description,
      'symptoms': symptoms,
      'diagnosis': diagnosis,
      'prescription': prescription,
      'notes': notes,
    };
  }
}