import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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
      debugPrint('Fetching doctors with specialty: $specialty');
      debugPrint('Using API endpoint: $baseUrl/doctors/specialty/$specialty');      
      debugPrint('Response status code: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final List<dynamic> doctorsJson = json.decode(response.body);
        debugPrint('Parsed ${doctorsJson.length} doctors');
        
        // Map JSON to Doctor objects        debugPrint('Successfully parsed ${doctorsJson.length} doctors');
        if (doctorsJson.isNotEmpty) {
          debugPrint('First doctor data: ${json.encode(doctorsJson[0])}');
        }
        
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
        if (doctors.every((d) => d.id == 0)) {
          debugPrint('All doctor parsing failed, returning empty list');
          return [];
        }
        
        return validDoctors;
      } else {

        debugPrint('Failed to load doctors: ${response.statusCode}');
        debugPrint('Error response: ${response.body}');
        debugPrint('Failed to load doctors in $specialty: ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('Error getting doctors by specialty: $e');

      return [];
    }
  }

static Future<bool> updateDoctorAvailability(int doctorId, bool isAvailable) async {
    debugPrint('Attempting to update doctor $doctorId availability to $isAvailable');
    
    try {
      final url = Uri.parse('$baseUrl/doctors/update-availability');
      final body = json.encode({
        'doctor_id': doctorId,
        'is_available': isAvailable,
      });
      
      debugPrint('Sending request to: $url');
      debugPrint('With body: $body');
      
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );
      
      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');
      
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error updating availability: $e');
      return false;
    }
  }


static Future<bool> approveDoctor(int doctorId) async {
    try {
      final url = Uri.parse('$baseUrl/doctors/approve/$doctorId');
      
      debugPrint('Sending approval request to: $url');
      
      final response = await http.put(url);
      
      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');
      
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error approving doctor: $e');
      return false;
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

