import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_app/services/doctor_service.dart';
import '../core/models/doctor_model.dart';
import '../services/auth_service_api.dart';

class DoctorService {
  static const String baseUrl = "http://192.168.1.55:5000/api";

  // Get doctors by specialty
  static Future<List<Doctor>> getDoctorsBySpecialty(String specialty) async {
    try {
      final token = await ApiService.getAuthToken();
      if (token == null) throw Exception('Authentication token not found');

      final response = await http.get(
        Uri.parse('$baseUrl/doctors/specialty/$specialty'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> doctorsJson = json.decode(response.body);
        return doctorsJson.map((json) => Doctor.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load doctors in $specialty: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error getting doctors by specialty: $e');
      throw Exception('Network error: $e');
    }
  }

  // Get all doctors
  static Future<List<Doctor>> getAllDoctors() async {
    try {
      final token = await ApiService.getAuthToken();
      if (token == null) throw Exception('Authentication token not found');

      final response = await http.get(
        Uri.parse('$baseUrl/doctors'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> doctorsJson = json.decode(response.body);
        return doctorsJson.map((json) => Doctor.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load doctors: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error getting doctors: $e');
      throw Exception('Network error: $e');
    }
  }

  // Get available doctors
  static Future<List<Doctor>> getAvailableDoctors() async {
    try {
      final token = await ApiService.getAuthToken();
      if (token == null) throw Exception('Authentication token not found');

      final response = await http.get(
        Uri.parse('$baseUrl/doctors/available/list'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> doctorsJson = json.decode(response.body);
        return doctorsJson.map((json) => Doctor.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load available doctors: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error getting available doctors: $e');
      throw Exception('Network error: $e');
    }
  }
}