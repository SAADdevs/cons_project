import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
    debugPrint('Processing doctor: $json');
    return Doctor(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      name: json['full_name'] ?? json['name'] ?? 'Unknown Doctor',
      specialty: json['specialties'] ?? 'General',
      isVerified: json['is_verified'] ?? false,
      isAvailable: json['is_available'] ?? false,
    );
  }
}

class DoctorService {
  static const String baseUrl = 'http://192.168.1.55:5000/api';
  // static const String baseUrl ='http://192.168.1.11:5000/api';  
  
  // Get all doctors with their names using a custom query
  static Future<List<Doctor>> getAllDoctors() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/with-names'));
      
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
        throw Exception('Failed to load doctors');
      }
    } catch (e) {
      debugPrint('Network error: $e');
      throw Exception('Network error: $e');
    }
  }
  
  // Update doctor availability - FIXED URL
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

  static getDoctorsBySpecialty(String specialty) {}
}