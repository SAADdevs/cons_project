import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:my_app/basrel.dart';
import '../core/models/consultation.dart';
import '../services/auth_service_api.dart';
import 'dart:math'; // Import for min function

class ConsultationService {


static Future<Consultation> requestConsultation({
    required int patientId,
    required int doctorId,
    required String type,
    required bool isEmergency,
    DateTime? consultationDate,
    String? reason,
  }) async {
    try {
      final token = await ApiService.getAuthToken();
      if (token == null) throw Exception('Authentication token not found');
      
      // Prepare request body
      final Map<String, dynamic> requestBody = {
        'user_id': patientId,
        'doctor_id': doctorId,
        'type': type,
        'is_emergency': isEmergency,
      };

      // Add optional parameters
      if (consultationDate != null) {
        requestBody['consultation_date'] = consultationDate.toIso8601String();
      }
      
      if (reason != null) {
        requestBody['reason'] = reason;
      }
      
      // Make API call
      final response = await http.post(
        Uri.parse('$baseUrl/consultations/request'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );
      
      // Check response
      if (response.statusCode == 201) {
        final responseBody = jsonDecode(response.body);
        return Consultation.fromJson(responseBody);
      } else {
        // Parse error message from response
        final responseBody = jsonDecode(response.body);
        throw Exception(responseBody['message'] ?? 'Failed to request consultation');
      }
    } catch (e) {
      throw Exception('Error requesting consultation: $e');
    }
  }

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
      
      // Make sure this URL matches your server's endpoint structure
      final url = '$baseUrl/upcoming-appointments/doctor/$doctorId';
      print("Requesting URL: $url"); // Add this for debugging
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print("Response status: ${response.statusCode}");
      if (response.body.isNotEmpty) {
        print("Response body (first 100 chars): ${response.body.substring(0, min(100, response.body.length))}...");
      }
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Consultation.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load upcoming consultations: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching upcoming consultations: $e');
    }
  }
  
  // Cancel an upcoming appointment
  static Future<void> cancelUpcomingAppointment(int consultationId) async {
    try {
      final token = await ApiService.getAuthToken();
      if (token == null) throw Exception('Authentication token not found');
      
      // Match the URL format with your Express route 
      final url = '$baseUrl/upcoming-appointments/cancel/$consultationId';
      print("Canceling appointment: Making PUT request to $url");
      
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      print("Cancel response status: ${response.statusCode}");
      if (response.body.isNotEmpty) {
        print("Cancel response body: ${response.body}");
      }
      
      if (response.statusCode != 200) {
        // Safely try to parse the response body
        String errorMessage = 'Failed to cancel appointment';
        try {
          if (response.body.contains("<!DOCTYPE html>")) {
            errorMessage = 'Server returned HTML instead of JSON (status ${response.statusCode})';
          } else {
            final responseBody = jsonDecode(response.body);
            errorMessage = responseBody['message'] ?? 'Failed to cancel appointment';
          }
        } catch (e) {
          errorMessage = 'Failed to cancel appointment: Server error';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      print("Error in cancelUpcomingAppointment: $e");
      throw Exception('Error cancelling appointment: $e');
    }
  }

  // Count upcoming appointments
  static Future<int> countUpcomingAppointments(int doctorId) async {
    try {
      final token = await ApiService.getAuthToken();
      if (token == null) throw Exception('Authentication token not found');
      
      final response = await http.get(
        Uri.parse('$baseUrl/upcoming-appointments/count/$doctorId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['upcoming_count'] ?? 0;
      } else {
        throw Exception('Failed to count upcoming consultations');
      }
    } catch (e) {
      throw Exception('Error counting upcoming consultations: $e');
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
  
  // Get patient's consultations
  static Future<List<Consultation>> getPatientConsultations(int patientId) async {
    try {
      final token = await ApiService.getAuthToken();
      if (token == null) throw Exception('Authentication token not found');
      
      final response = await http.get(
        Uri.parse('$baseUrl/patients/consultations/$patientId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Consultation.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load patient consultations: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching patient consultations: $e');
    }
  }

 
}