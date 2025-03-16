import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:my_app/core/utils/constants.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static const String baseUrl = "http://192.168.1.10:5000/api/auth"; // For Android emulator, use your IP for real devices

  // Login Function
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse("$baseUrl/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "password": password}),
    );

    final responseBody = jsonDecode(response.body);

    if (response.statusCode == 200) {
      // Store the token in secure storage
      final secureStorage = const FlutterSecureStorage();
      await secureStorage.write(key: 'auth_token', value: responseBody['token']);
      return responseBody;
    } else if (response.statusCode == 403 && 
               responseBody['message'] == "Doctor account not verified yet") {
      // Pass through the 403 error with the specific message
      return responseBody;
    } else {
      throw Exception(responseBody['message'] ?? "Failed to login");
    }
  }

  // Register Function
  static Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
    required String role,
    String? IMPE,
    String? specialties,
    String? hospital,
    int? age,
    String? gender,
  }) async {
    final url = Uri.parse("$baseUrl/register");

    final Map<String, dynamic> requestBody = {
      "full_name": fullName,
      "email": email,
      "password": password,
      "role": role,
    };

    if (role == "doctor") {
      requestBody["IMPE"] = IMPE;
      requestBody["specialties"] = specialties;
      requestBody["hospital"] = hospital;
    } else if (role == "patient") {
      requestBody["age"] = age;
      requestBody["gender"] = gender;
    }

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Unexpected response: ${response.body}");
      }
    } catch (e) {
      throw Exception("Failed to register: $e");
    }
  }

  // Update doctor availability
  static Future<Map<String, dynamic>> updateDoctorAvailability({
    required int doctorId,
    required bool isAvailable,
  }) async {
    final String? token = await getAuthToken();
    if (token == null) throw Exception('Authentication token not found');
    
    final response = await http.put(
      Uri.parse('${Constants.apiUrl}${Constants.updateDoctorAvailabilityEndpoint}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      },
      body: json.encode({
        'doctor_id': doctorId,
        'is_available': isAvailable,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to update doctor availability: ${response.body}');
    }
  }

  // Get current authenticated doctor ID
  static Future<int?> getCurrentDoctorId() async {
    try {
      // Retrieve the JWT token from secure storage
      final String? token = await getAuthToken();
      if (token == null) {
        return null; // No authentication token found
      }
      
      // Get doctor profile using the token
      final response = await http.get(
        Uri.parse("$baseUrl/doctor"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> doctorData = jsonDecode(response.body);
        return doctorData['id']; // Return the doctor ID from the profile
      } else {
        // Token might be invalid or expired
        return null;
      }
    } catch (e) {
      print('Error getting doctor ID: $e');
      return null;
    }
  }

  // Helper method to get the authentication token
  static Future<String?> getAuthToken() async {
    try {
      // Using secure storage to retrieve the token
      final secureStorage = const FlutterSecureStorage();
      final token = await secureStorage.read(key: 'auth_token');
      return token;
    } catch (e) {
      print('Error retrieving auth token: $e');
      return null;
    }
  }
}