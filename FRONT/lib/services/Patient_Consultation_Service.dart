import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../basrel.dart';
import '../core/models/consultation.dart';
import '../services/auth_service_api.dart';

class PatientConsultationService {
  // Get all consultations for a patient
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
      debugPrint('Requesting consultation with doctor ID: $doctorId');
      
      final token = await ApiService.getAuthToken();
      if (token == null) throw Exception('Authentication token not found');
      
      final requestBody = {
        'patient_id': patientId,
        'doctor_id': doctorId,
        'type': type,
        'is_emergency': isEmergency,
      };
      
      if (consultationDate != null) {
        requestBody['consultation_date'] = consultationDate.toIso8601String();
      }
      
      if (reason != null && reason.isNotEmpty) {
        requestBody['reason'] = reason;
      }
      
      final response = await http.post(
        Uri.parse('$baseUrl/consultations/request'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );
      
      debugPrint('Response status code: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');
      
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final consultation = Consultation.fromJson(data);
        return consultation;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to request consultation');
      }
    } catch (e) {
      debugPrint('Error in requestConsultation: $e');
      throw Exception('Failed to request consultation: $e');
    }
  }
  
  // Cancel a consultation request
  static Future<bool> cancelConsultationRequest(int consultationId) async {
    try {
      debugPrint('Cancelling consultation request: $consultationId');
      
      final token = await ApiService.getAuthToken();
      if (token == null) throw Exception('Authentication token not found');
      
      final response = await http.put(
        Uri.parse('$baseUrl/consultations/cancel/$consultationId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      debugPrint('Response status code: ${response.statusCode}');
      
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error cancelling consultation request: $e');
      return false;
    }
  }
}