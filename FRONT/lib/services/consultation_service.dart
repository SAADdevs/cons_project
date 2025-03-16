import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/models/consultation.dart'; // Import the Consultation model

class ConsultationService {
  static const String baseUrl = "http://192.168.1.10:5000/api";

  // Fetch pending consultations for a doctor
  static Future<List<Consultation>> fetchPendingConsultations(int doctorId) async {
  try {
    print('Fetching consultations for doctor ID: $doctorId');
    final response = await http.get(
      Uri.parse('$baseUrl/consultations/doctor/$doctorId'),
    );

    print('Response status code: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      try {
        final List<dynamic> data = jsonDecode(response.body);
        final consultations = data
          .map((json) => Consultation.fromJson(json))
          .where((consultation) => consultation.status == 'pending')
          .toList();
        
        print('Found ${consultations.length} pending consultations');
        return consultations;
      } catch (jsonError) {
        print('Error parsing JSON: $jsonError');
        throw Exception('Failed to parse consultation data: $jsonError');
      }
    } else {
      throw Exception('Failed to load consultations: ${response.statusCode}');
    }
  } catch (e) {
    print('Error in fetchPendingConsultations: $e');
    rethrow;
  }
}
  // Update consultation status
 // Modified update consultation status method
static Future<void> updateConsultationStatus({
  required int consultationId,
  required String status,
  DateTime? consultationDate, // Make this optional
}) async {
  final body = {
    'consultation_id': consultationId,
    'status': status,
  };
  
  // Only add consultation_date if it's provided and not null
  if (consultationDate != null) {
    body['consultation_date'] = consultationDate.toIso8601String();
  }
  
  final response = await http.put(
    Uri.parse('$baseUrl/consultations/update-status'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(body),
  );
  
  if (response.statusCode != 200) {
    throw Exception('Failed to update consultation status: ${response.statusCode}');
  }
}
}