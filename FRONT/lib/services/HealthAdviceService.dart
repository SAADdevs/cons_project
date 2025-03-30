import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:my_app/basrel.dart';
import 'package:my_app/core/models/healthAdvice.dart';
import '../core/models/healthAdvice.dart';
import '../services/auth_service_api.dart';

class HealthAdviceService {

  // Get all health advices
  static Future<List<HealthAdvice>> getAllHealthAdvices() async {
    try {
      final token = await ApiService.getAuthToken();
      if (token == null) throw Exception('Authentication token not found');

      final response = await http.get(
        Uri.parse('$baseUrl/health-advice'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> advicesJson = json.decode(response.body);
        return advicesJson.map((json) => HealthAdvice.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load health advices: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Get health advice by ID
  static Future<HealthAdvice> getHealthAdviceById(int id) async {
    try {
      final token = await ApiService.getAuthToken();
      if (token == null) throw Exception('Authentication token not found');

      final response = await http.get(
        Uri.parse('$baseUrl/health-advice/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        final adviceJson = json.decode(response.body);
        return HealthAdvice.fromJson(adviceJson);
      } else {
        throw Exception('Failed to load health advice: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Get health advice by category
  static Future<List<HealthAdvice>> getHealthAdviceByCategory(String category) async {
    try {
      final token = await ApiService.getAuthToken();
      if (token == null) throw Exception('Authentication token not found');

      final response = await http.get(
        Uri.parse('$baseUrl/health-advice/category/$category'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> advicesJson = json.decode(response.body);
        return advicesJson.map((json) => HealthAdvice.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load health advices by category: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
  
}