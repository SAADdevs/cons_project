import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../basrel.dart';
import '../core/models/doctor_model.dart';
import '../services/auth_service_api.dart';

class DoctorService {
  // Get doctors by specialty
  static Future<List<Doctor>> getDoctorsBySpecialty(String specialty) async {
    try {
      debugPrint('Getting doctors for specialty: $specialty');
      
      final token = await ApiService.getAuthToken();
      final headers = {
        'Content-Type': 'application/json',
      };
      
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      // Make sure we're using the correct endpoint
      final url = Uri.parse('$baseUrl/doctors/specialty/$specialty');
      debugPrint('Requesting URL: $url');
      
      final response = await http.get(url, headers: headers);
      
      // Log the response for debugging
      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body preview: ${response.body.substring(0, min(200, response.body.length))}...');
      
      if (response.statusCode == 200) {
        final List<dynamic> doctorsJson = json.decode(response.body);
        debugPrint('Parsed ${doctorsJson.length} doctors');
        
        // Map JSON to Doctor objects
        final List<Doctor> doctors = doctorsJson.map((json) {
          try {
            return Doctor.fromJson(json);
          } catch (e) {
            debugPrint('Error parsing doctor: $e');
            return Doctor(
              id: 0, 
              userId: 0, 
              name: 'Unknown Doctor', 
              specialty: 'General', 
              isVerified: false, 
              isAvailable: false
            );
          }
        }).toList();
        
        // Filter out any invalid doctors that might have been created as fallbacks
        final validDoctors = doctors.where((d) => d.id != 0).toList();
        debugPrint('Returning ${validDoctors.length} valid doctors');
        
        return validDoctors;
      } else {
        debugPrint('Failed to load doctors: ${response.statusCode}');
        debugPrint('Error response: ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('Error getting doctors by specialty: $e');
      return [];
    }
  }

  // Get all doctors
  static Future<List<Doctor>> getAllDoctors() async {
    try {
      final token = await ApiService.getAuthToken();
      final headers = {
        'Content-Type': 'application/json',
      };
      
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.get(
        Uri.parse('$baseUrl/doctors'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> doctorsJson = json.decode(response.body);
        return doctorsJson
            .map((json) => Doctor.fromJson(json))
            .toList();
      } else {
        debugPrint('Failed to load doctors: ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('Error getting doctors: $e');
      return [];
    }
  }

  // Helper method to limit string length for logging
  static int min(int a, int b) => a < b ? a : b;

  // Get available doctors
  static Future<List<Doctor>> getAvailableDoctors() async {
    try {
      final token = await ApiService.getAuthToken();
      final headers = {
        'Content-Type': 'application/json',
      };
      
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.get(
        Uri.parse('$baseUrl/doctors/available/list'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> doctorsJson = json.decode(response.body);
        return doctorsJson
            .map((json) => Doctor.fromJson(json))
            .toList();
      } else {
        debugPrint('Failed to load available doctors: ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('Error getting available doctors: $e');
      return [];
    }
  }
}