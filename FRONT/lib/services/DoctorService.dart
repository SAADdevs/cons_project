import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_app/basrel.dart';
import 'package:my_app/services/doctor_service.dart';
import '../core/models/doctor_model.dart';
import '../services/auth_service_api.dart';

class DoctorService {

  // Get doctors by specialty
  static Future<List<Doctor>> getDoctorsBySpecialty(String specialty) async {
    try {
      final token = await ApiService.getAuthToken();
      // Try to get token, if not available proceed without it
      final headers = {
        'Content-Type': 'application/json',
      };
      
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      // Debug log
      debugPrint('Fetching doctors with specialty: $specialty');
      debugPrint('Using API endpoint: $baseUrl/doctors/specialty/$specialty');

      final response = await http.get(
        Uri.parse('$baseUrl/doctors/specialty/$specialty'),
        headers: headers,
      );
      
      // Debug log response
      debugPrint('Response status code: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final List<dynamic> doctorsJson = json.decode(response.body);
        
        // Debug log the parsed data
        debugPrint('Successfully parsed ${doctorsJson.length} doctors');
        if (doctorsJson.isNotEmpty) {
          debugPrint('First doctor data: ${json.encode(doctorsJson[0])}');
        }
        
        // Map JSON to Doctor objects with null check
        final List<Doctor> doctors = doctorsJson.map((json) {
          try {
            return Doctor.fromJson(json);
          } catch (e) {
            debugPrint('Error parsing doctor: $e');
            // Return a default doctor if parsing fails
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
        
        // Return empty list if all parsing fails
        if (doctors.every((d) => d.id == 0)) {
          debugPrint('All doctor parsing failed, returning empty list');
          return [];
        }
        
        return doctors;
      } else {
        debugPrint('Failed to load doctors in $specialty: ${response.body}');
        // Return empty list instead of throwing exception
        return [];
      }
    } catch (e) {
      debugPrint('Error getting doctors by specialty: $e');
      // Return empty list instead of throwing exception
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