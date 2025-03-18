import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:my_app/core/utils/constants.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';


class ApiService {
  static const String baseUrl = "http://192.168.1.69:5000/api/auth"; // For Android emulator, use your IP for real devices
  static const secureStorage = FlutterSecureStorage();

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
      await secureStorage.write(key: 'auth_token', value: responseBody['token']);
      
      // Store user data for later use
      if (responseBody['user'] != null) {
        await secureStorage.write(key: 'user_id', value: responseBody['user']['id'].toString());
        await secureStorage.write(key: 'user_role', value: responseBody['user']['role']);
        await secureStorage.write(key: 'user_full_name', value: responseBody['user']['full_name']);
        await secureStorage.write(key: 'user_email', value: responseBody['user']['email']);
      }
      
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

  static Future<Map<String, dynamic>> updateDoctorAvailability({
    required int doctorId,
    required bool isAvailable,
  }) async {
    final String? token = await getAuthToken();
    if (token == null) throw Exception('Authentication token not found');
    
    // Direct URL with doctorId in the path
    final String url = "http://192.168.1.69:5000/api/doctors/approve/$doctorId";
    
    final response = await http.put(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      },
      // Only sending isAvailable in the body
      body: json.encode({
        'is_available': isAvailable,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to update doctor availability: ${response.body}');
    }
  }

  // Get auth token from secure storage
  static Future<String?> getAuthToken() async {
    return await secureStorage.read(key: 'auth_token');
  }

  // Get current authenticated user ID
  static Future<int?> getCurrentUserId() async {
    final userIdStr = await secureStorage.read(key: 'user_id');
    return userIdStr != null ? int.tryParse(userIdStr) : null;
  }

  // Get current authenticated doctor ID
  static Future<int?> getCurrentDoctorId() async {
    final userIdStr = await secureStorage.read(key: 'user_id');
    final userRole = await secureStorage.read(key: 'user_role');
    
    // Only return the ID if the user is a doctor
    if (userRole == 'doctor' && userIdStr != null) {
      return int.tryParse(userIdStr);
    }
    return null;
  }

  // Get user role
  static Future<String?> getUserRole() async {
    return await secureStorage.read(key: 'user_role');
  }

  // Get user full name
  static Future<String?> getUserFullName() async {
    return await secureStorage.read(key: 'user_full_name');
  }

  // Clear all stored authentication data (for logout)
  static Future<void> clearAuthData() async {
    await secureStorage.deleteAll();
  }
}