import 'dart:convert';

import 'package:http/http.dart' as http;

class Consultation {
  final int id;
  final String? patientName;
  final int? patientAge;
  final String? patientGender;
  final DateTime? consultationDate; // Ensure this is DateTime
  final String type;
  final bool isEmergency;

  Consultation({
    required this.id,
    this.patientName,
    this.patientAge,
    this.patientGender,
    this.consultationDate,
    required this.type,
    this.isEmergency = false,
  });

  factory Consultation.fromJson(Map<String, dynamic> json) {
    return Consultation(
      id: json['consultation_id'] as int,
      patientName: json['patient_name'] as String?,
      patientAge: json['patient_age'] as int?,
      patientGender: json['patient_gender'] as String?,
      // Explicitly parse the date string to DateTime
      consultationDate: json['consultation_date'] != null 
        ? DateTime.parse(json['consultation_date'].toString()) 
        : null,
      type: json['type'] as String? ?? 'unknown',
      isEmergency: json['is_emergency'] as bool? ?? false,
    );
  }
}

// In your ConsultationService
Future<List<Consultation>> fetchUpcomingConsultations(int doctorId) async {
  try {
    final response = await http.get(
      Uri.parse('/api/upcoming-appointments/doctor/$doctorId'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      
      // Add comprehensive logging
      print('Raw consultation data: $data');

      return data.map((item) {
        try {
          return Consultation.fromJson(item);
        } catch (e) {
          print('Error parsing consultation: $e');
          print('Problematic item: $item');
          // You might want to handle or log parsing errors
          return null;
        }
      }).whereType<Consultation>().toList();
    } else {
      throw Exception('Failed to load consultations');
    }
  } catch (e) {
    print('Error in fetchUpcomingConsultations: $e');
    rethrow;
  }
}