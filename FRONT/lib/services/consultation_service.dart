import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/models/consultation.dart';
import '../services/auth_service_api.dart';

class ConsultationService {
  static const String baseUrl = "http://192.168.158.178:5000/api"; // Match your API base URL

  // Fetch pending consultations for a doctor
  static Future<List<Consultation>> fetchPendingConsultations(int doctorId) async {
  try {
    final token = await ApiService.getAuthToken();
    if (token == null) throw Exception('Authentication token not found');
    
    // Changed URL to match your actual backend route
    final response = await http.get(
      Uri.parse('$baseUrl/consultations/doctor/$doctorId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Consultation.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load consultations: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Error fetching consultations: $e');
  }
}

  // Update consultation status (accept/refuse)
 static Future<void> updateConsultationStatus({
  required int consultationId,
  required String status,
  DateTime? consultationDate,
}) async {
  try {
    final token = await ApiService.getAuthToken();
    if (token == null) throw Exception('Authentication token not found');
    
    final Map<String, dynamic> requestBody = {
      'consultation_id': consultationId,
      'status': status,
    };
    
    // Include consultation date if provided
    if (consultationDate != null) {
      requestBody['consultation_date'] = consultationDate.toIso8601String();
    }
    
    // Changed URL to match your actual backend route
    final response = await http.put(
      Uri.parse('$baseUrl/consultations/update-status'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(requestBody),
    );
    
    if (response.statusCode != 200) {
      final responseBody = jsonDecode(response.body);
      throw Exception(responseBody['message'] ?? 'Failed to update consultation status');
    }
  } catch (e) {
    throw Exception('Error updating consultation status: $e');
  }
}

  // Fetch accepted consultations (upcoming appointments)
  static Future<List<Consultation>> fetchUpcomingConsultations(int doctorId) async {
    try {
      final token = await ApiService.getAuthToken();
      if (token == null) throw Exception('Authentication token not found');
      
      final response = await http.get(
        Uri.parse('$baseUrl/consultations/upcoming/$doctorId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Consultation.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load upcoming consultations');
      }
    } catch (e) {
      throw Exception('Error fetching upcoming consultations: $e');
    }
  }

  // Fetch consultation history
  static Future<List<Consultation>> fetchConsultationHistory(int doctorId) async {
    try {
      final token = await ApiService.getAuthToken();
      if (token == null) throw Exception('Authentication token not found');
      
      final response = await http.get(
        Uri.parse('$baseUrl/consultations/history/$doctorId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Consultation.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load consultation history');
      }
    } catch (e) {
      throw Exception('Error fetching consultation history: $e');
    }
  }

  // Get consultation details by ID
  static Future<Consultation> getConsultationById(int consultationId) async {
    try {
      final token = await ApiService.getAuthToken();
      if (token == null) throw Exception('Authentication token not found');
      
      final response = await http.get(
        Uri.parse('$baseUrl/consultations/$consultationId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Consultation.fromJson(data);
      } else {
        throw Exception('Failed to get consultation details');
      }
    } catch (e) {
      throw Exception('Error getting consultation details: $e');
    }
  }
}