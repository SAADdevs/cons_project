import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../basrel.dart';
import '../core/models/consultation.dart';
import '../services/auth_service_api.dart';

class UpcomingAppointmentsService {
  // Get upcoming appointments for a doctor
  static Future<List<Consultation>> getDoctorUpcomingAppointments(int doctorId) async {
    try {
      // Add debugging
      debugPrint('Fetching upcoming appointments for doctor: $doctorId');
      debugPrint('API endpoint: $baseUrl/upcoming-appointments/doctor/$doctorId');
      
      final token = await ApiService.getAuthToken();
      if (token == null) throw Exception('Authentication token not found');
      
      final response = await http.get(
        Uri.parse('$baseUrl/upcoming-appointments/doctor/$doctorId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      // Debug the response
      debugPrint('Response status: ${response.statusCode}');
      if (response.body.isNotEmpty) {
        debugPrint('Response body sample: ${response.body.substring(0, response.body.length > 100 ? 100 : response.body.length)}...');
      }
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        debugPrint('Parsed ${data.length} appointments');
        
        final appointments = data.map((json) => Consultation.fromJson(json)).toList();
        return appointments;
      } else {
        // Try to parse error message
        String errorMsg = 'Failed to load upcoming appointments';
        try {
          final errorJson = jsonDecode(response.body);
          errorMsg = errorJson['message'] ?? errorMsg;
        } catch (_) {}
        
        debugPrint('Error loading appointments: $errorMsg');
        return []; // Return empty list instead of throwing
      }
    } catch (e) {
      debugPrint('Exception in getDoctorUpcomingAppointments: $e');
      return []; // Return empty list on error
    }
  }

  // Cancel an appointment
  static Future<bool> cancelAppointment(int consultationId) async {
    try {
      debugPrint('Cancelling appointment: $consultationId');
      final token = await ApiService.getAuthToken();
      if (token == null) throw Exception('Authentication token not found');
      
      final response = await http.put(
        Uri.parse('$baseUrl/upcoming-appointments/cancel/$consultationId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      debugPrint('Cancel response status: ${response.statusCode}');
      debugPrint('Cancel response body: ${response.body}');
      
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error cancelling appointment: $e');
      return false;
    }
  }
  
  // Test connection to upcoming appointments API
  static Future<bool> testConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/upcoming-appointments/test'),
      );
      
      debugPrint('Test connection status: ${response.statusCode}');
      debugPrint('Test connection body: ${response.body}');
      
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Test connection error: $e');
      return false;
    }
  }
}