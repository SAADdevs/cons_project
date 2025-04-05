// lib/core/models/consultation.dart
import 'package:flutter/foundation.dart';

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
      id: _parseId(json['id'] ?? json['consultation_id']),
      patientId: _parseId(json['patient_id'] ?? 0),
      patientName: (json['patient_name'] ?? json['patientName'] ?? json['name']) as String?,
      doctorId: _parseId(json['doctor_id'] ?? 0),
      doctorName: json['doctor_name'] as String?,
      doctorSpecialty: json['doctor_specialty'] ?? json['specialties'] as String?,
      type: (json['type'] ?? json['consultation_type'] as String?) ?? 'unknown',
      status: (json['status'] as String?) ?? 'pending',
      isEmergency: _parseBool(json['is_emergency']),
      consultationDate: _parseDate(json['consultation_date'] ?? json['date']),
      createdAt: json['created_at'] ?? json['consultation_created_at'],
    );
  }

  // Safely parse ID, defaulting to 0 if null or invalid
  static int _parseId(dynamic id) {
    if (id == null) return 0;
    return id is int ? id : int.tryParse(id.toString()) ?? 0;
  }

  // Safely parse boolean values
  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is String) {
      return ['true', '1', 'yes'].contains(value.toLowerCase());
    }
    return false;
  }

  // Safely parse date values
  static dynamic _parseDate(dynamic date) {
    if (date == null) return null;
    
    try {
      // If it's already a DateTime, return it
      if (date is DateTime) return date;
      
      // If it's a string, parse it
      if (date is String) {
        return DateTime.parse(date);
      }
      
      // If it's something else, return null
      return null;
    } catch (e) {
      debugPrint('Error parsing date: $e, Original value: $date');
      return null;
    }
  }

  // Getter for patient age (returning null for now)
  int? get patientAge => null;

  // Getter for patient gender (returning null for now)
  String? get patientGender => null;

  // Helper method to safely get consultation date as DateTime
  DateTime? get consultationDateTime {
    return _parseDate(consultationDate);
  }

  // Helper method to safely get created date as DateTime
  DateTime? get createdDateTime {
    return _parseDate(createdAt);
  }

  // Convert to JSON for potential serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_id': patientId,
      'patient_name': patientName,
      'doctor_id': doctorId,
      'doctor_name': doctorName,
      'doctor_specialty': doctorSpecialty,
      'type': type,
      'status': status,
      'is_emergency': isEmergency,
      'consultation_date': consultationDate,
      'created_at': createdAt,
    };
  }

  // Override toString for easy debugging
  @override
  String toString() {
    return 'Consultation(id: $id, patient: $patientName, doctor: $doctorName, type: $type, status: $status, date: $consultationDate)';
  }

  // Equality comparison
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is Consultation &&
      other.id == id &&
      other.patientId == patientId &&
      other.doctorId == doctorId &&
      other.type == type &&
      other.status == status;
  }

  // Hash code for proper comparison
  @override
  int get hashCode {
    return id.hashCode ^ 
      patientId.hashCode ^ 
      doctorId.hashCode ^ 
      type.hashCode ^ 
      status.hashCode;
  }

  get patientUserId => null;

  get doctorUserId => null;
}