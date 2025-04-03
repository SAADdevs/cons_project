import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_app/basrel.dart';
import '../core/models/consultation.dart';
import '../services/auth_service_api.dart';
import 'dart:math'; // Import for min function

class ConsultationService {
  // Request a new consultation
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
        Map<String, dynamic> responseBody = {};
        try {
          responseBody = jsonDecode(response.body);
        } catch (e) {
          throw Exception('Failed to parse API response: ${response.body}');
        }
        throw Exception(responseBody['message'] ?? 'Failed to request consultation');
      }
    } catch (e) {
      print('Error in requestConsultation: $e');
      throw Exception('Error requesting consultation: $e');
    }
  }

  // Fetch pending consultations for a doctor with improved error handling
  static Future<List<Consultation>> fetchPendingConsultations(int doctorId) async {
    try {
      final token = await ApiService.getAuthToken();
      if (token == null) throw Exception('Authentication token not found');
      
      print("Fetching pending consultations for doctor ID: $doctorId");
      
      // Request URL
      final url = '$baseUrl/consultations/doctor/$doctorId';
      print("Requesting URL: $url");
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      print("Response status: ${response.statusCode}");
      if (response.body.isNotEmpty) {
        print("Response preview: ${response.body.substring(0, min(100, response.body.length))}...");
      }
      
      if (response.statusCode == 200) {
        try {
          final List<dynamic> data = jsonDecode(response.body);
          return data.map((json) => Consultation.fromJson(json)).toList();
        } catch (e) {
          print("Error parsing consultations data: $e");
          throw Exception('Error parsing consultations: $e');
        }
      } else {
        throw Exception('Failed to load consultations: ${response.statusCode}');
      }
    } catch (e) {
      print("Error in fetchPendingConsultations: $e");
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
      
      print("Updating consultation status: $requestBody");
      
      final url = '$baseUrl/consultations/update-status';
      print("Request URL: $url");
      
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );
      
      print("Update status response: ${response.statusCode}");
      
      if (response.statusCode != 200) {
        Map<String, dynamic> responseBody = {};
        try {
          responseBody = jsonDecode(response.body);
        } catch (e) {
          throw Exception('Failed to parse API response: ${response.body}');
        }
        throw Exception(responseBody['message'] ?? 'Failed to update consultation status');
      }
    } catch (e) {
      print("Error in updateConsultationStatus: $e");
      throw Exception('Error updating consultation status: $e');
    }
  }

  // Fetch accepted consultations (upcoming appointments)
  // consultation_service.dart - Update the fetchUpcomingConsultations method

static Future<List<Consultation>> fetchUpcomingConsultations(int doctorId) async {
  try {
    final token = await ApiService.getAuthToken();
    if (token == null) throw Exception('Authentication token not found');
    
    print("Fetching upcoming consultations for doctor ID: $doctorId");
    
    // Using try-catch with multiple endpoint formats to increase reliability
    List<String> endpoints = [
      '$baseUrl/upcoming-appointments/doctor/$doctorId',
      '$baseUrl/consultations/upcoming/$doctorId',
      '$baseUrl/consultations/doctor/$doctorId/upcoming',
    ];
    
    Exception? lastException;
    
    for (String endpoint in endpoints) {
      try {
        print("Trying endpoint: $endpoint");
        final response = await http.get(
          Uri.parse(endpoint),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ).timeout(const Duration(seconds: 10)); // Add timeout for better error handling
        
        if (response.statusCode == 200) {
          print("Success! Response body: ${response.body.substring(0, min(100, response.body.length))}...");
          final List<dynamic> data = jsonDecode(response.body);
          return data.map((json) => Consultation.fromJson(json)).toList();
        }
      } catch (e) {
        print("Error with endpoint $endpoint: $e");
        lastException = Exception(e.toString());
        // Continue to next endpoint
      }
    }
    
    // If we've tried all endpoints and none worked
    throw lastException ?? Exception('Failed to load upcoming consultations after trying multiple endpoints');
  } catch (e) {
    print("Final error in fetchUpcomingConsultations: $e");
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
        print("Cancel response preview: ${response.body.substring(0, min(100, response.body.length))}...");
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
  static Future<List<Consultation>> getPatientConsultations(int userId) async {
  try {
    debugPrint('Fetching consultations for user ID: $userId');
    
    final token = await ApiService.getAuthToken();
    if (token == null) throw Exception('Authentication token not found');
    
    // First check if user has a patient record
    final patientIdResponse = await http.get(
      Uri.parse('$baseUrl/patients/consultations/get-patient-id/$userId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    
    if (patientIdResponse.statusCode != 200) {
      debugPrint('User $userId does not have a patient profile. Status: ${patientIdResponse.statusCode}');
      // Return empty list instead of throwing exception for better UX
      return [];
    }
    
    // Extract the patient ID from the response
    final patientData = jsonDecode(patientIdResponse.body);
    final patientId = patientData['id'];
    
    debugPrint('Found patient ID: $patientId for user ID: $userId');
    
    // Now get the consultations using the patient ID
    final response = await http.get(
      Uri.parse('$baseUrl/patients/consultations/$patientId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    
    debugPrint('Response status code: ${response.statusCode}');
    if (response.body.isNotEmpty) {
      debugPrint('Response body: ${response.body}');
    }
    
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      debugPrint('Fetched ${data.length} consultations');
      
      final consultations = data.map((json) => Consultation.fromJson(json)).toList();
      return consultations;
    } else {
      debugPrint('Failed to load consultations: ${response.body}');
      // Return empty list instead of throwing exception for better UX
      return [];
    }
  } catch (e) {
    debugPrint('Error in getPatientConsultations: $e');
    // Return empty list on error for better UX
    return [];
  }
}

 
}