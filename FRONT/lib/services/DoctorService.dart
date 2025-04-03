import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
<<<<<<< HEAD
import '../basrel.dart';
import '../core/models/doctor_model.dart';
import '../services/auth_service_api.dart';

class DoctorService {
  // Get doctors by specialty
=======
import 'package:my_app/services/auth_service_api.dart';

class Doctor {
  final int id;
  final int userId;
  final String name;
  final String specialty;
  final bool isVerified;
  final bool isAvailable;

  Doctor({
    required this.id,
    required this.userId,
    required this.name,
    required this.specialty,
    required this.isVerified,
    required this.isAvailable,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    try {
      // Debug print the entire JSON
      debugPrint('Processing doctor JSON: $json');
      
      // Prioritize name extraction
      String extractName(Map<String, dynamic> json) {
        // Try multiple ways to extract name
        if (json['full_name'] != null && json['full_name'].toString().isNotEmpty) {
          return json['full_name'];
        }
        if (json['name'] != null && json['name'].toString().isNotEmpty) {
          return json['name'];
        }
        // Fallback to constructing name from other fields
        return 'Dr. ${json['id'] ?? 'Unknown'}';
      }

      return Doctor(
        id: json['id'] ?? 0,
        userId: json['user_id'] ?? 0,
        name: extractName(json),
        specialty: json['specialties'] ?? json['specialty'] ?? 'General',
        isVerified: json['is_verified'] ?? false,
        isAvailable: json['is_available'] ?? false,
      );
    } catch (e) {
      debugPrint('Error parsing doctor: $e');
      return Doctor(
        id: 0,
        userId: 0,
        name: 'Unknown Doctor',
        specialty: 'General',
        isVerified: false,
        isAvailable: false,
      );
    }
  }
}

class DoctorService {
  static const String baseUrl = 'http://192.168.158.178:5000/api';
  
  // Get all doctors with their names using a custom query
  static Future<List<Doctor>> getAllDoctors() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/doctors/with-names'));
      
      debugPrint('Get doctors status code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final List<dynamic> doctorsJson = json.decode(response.body);
        debugPrint('Found ${doctorsJson.length} doctors');
        
        if (doctorsJson.isNotEmpty) {
          debugPrint('Sample doctor data: ${json.encode(doctorsJson[0])}');
        }
        
        return doctorsJson.map((json) => Doctor.fromJson(json)).toList();
      } else {
        debugPrint('API Error: ${response.body}');
        return []; // Return empty list instead of throwing exception
      }
    } catch (e) {
      debugPrint('Network error: $e');
      return []; // Return empty list instead of throwing exception
    }
  }
  
  // Update doctor availability
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
  
  // Approve a doctor
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
>>>>>>> 0f49f28f3662df96fa31f9030c2bdd0187900a80
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

<<<<<<< HEAD
      // Make sure we're using the correct endpoint
      final url = Uri.parse('$baseUrl/doctors/specialty/$specialty');
      debugPrint('Requesting URL: $url');
      
      final response = await http.get(url, headers: headers);
      
      // Log the response for debugging
      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body preview: ${response.body.substring(0, min(200, response.body.length))}...');
=======
      debugPrint('Fetching doctors with specialty: $specialty');
      debugPrint('Using API endpoint: $baseUrl/doctors/specialty/$specialty');

      final response = await http.get(
        Uri.parse('$baseUrl/doctors/specialty/$specialty'),
        headers: headers,
      );
      
      debugPrint('Response status code: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');
>>>>>>> 0f49f28f3662df96fa31f9030c2bdd0187900a80
      
      if (response.statusCode == 200) {
        final List<dynamic> doctorsJson = json.decode(response.body);
        debugPrint('Parsed ${doctorsJson.length} doctors');
        
<<<<<<< HEAD
        // Map JSON to Doctor objects
=======
        debugPrint('Successfully parsed ${doctorsJson.length} doctors');
        if (doctorsJson.isNotEmpty) {
          debugPrint('First doctor data: ${json.encode(doctorsJson[0])}');
        }
        
>>>>>>> 0f49f28f3662df96fa31f9030c2bdd0187900a80
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
        
<<<<<<< HEAD
        // Filter out any invalid doctors that might have been created as fallbacks
        final validDoctors = doctors.where((d) => d.id != 0).toList();
        debugPrint('Returning ${validDoctors.length} valid doctors');
=======
        if (doctors.every((d) => d.id == 0)) {
          debugPrint('All doctor parsing failed, returning empty list');
          return [];
        }
>>>>>>> 0f49f28f3662df96fa31f9030c2bdd0187900a80
        
        return validDoctors;
      } else {
<<<<<<< HEAD
        debugPrint('Failed to load doctors: ${response.statusCode}');
        debugPrint('Error response: ${response.body}');
=======
        debugPrint('Failed to load doctors in $specialty: ${response.body}');
>>>>>>> 0f49f28f3662df96fa31f9030c2bdd0187900a80
        return [];
      }
    } catch (e) {
      debugPrint('Error getting doctors by specialty: $e');
<<<<<<< HEAD
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
=======
>>>>>>> 0f49f28f3662df96fa31f9030c2bdd0187900a80
      return [];
    }
  }
}