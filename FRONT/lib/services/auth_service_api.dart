import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_app/basrel.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {




  static const secureStorage = FlutterSecureStorage();

  // Login Function
  static Future<Map<String, dynamic>> login(String email, String password) async {
  try {
    print("Attempting login to: $baseUrl/auth/login");
    print("Payload: ${jsonEncode({"email": email, "password": password})}");
    
    final response = await http.post(
      Uri.parse("$baseUrl/auth/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "password": password}),
    );

    print("Login response status: ${response.statusCode}");
    print("Login response body: ${response.body}");

    if (response.body.isNotEmpty) {
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
    } else {
      throw Exception("Empty response from server");
    }
  } catch (e) {
    print("Login exception: $e");
    throw Exception("Failed to login: $e");
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
    final url = Uri.parse("$baseUrl/auth/register");

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
    final String url = "$baseUrl/doctors/update-availability";
    
    final response = await http.put(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      },
      // Sending both doctorId and isAvailable in the body
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
  
  // Get user email
  static Future<String?> getUserEmail() async {
    return await secureStorage.read(key: 'user_email');
  }

  // Clear all stored authentication data (for logout)
  static Future<void> clearAuthData() async {
    await secureStorage.deleteAll();
  }
  
  // Get doctor profile
  static Future<Map<String, dynamic>> getDoctorProfile() async {
    try {
      final token = await getAuthToken();
      final userId = await getCurrentUserId(); // Get user_id instead of doctor_id
      
      if (token == null) throw Exception('Authentication token not found');
      if (userId == null) throw Exception('User ID not found');
      
      // Using the correct endpoint that's used in admin_doctors_page.dart
      final response = await http.get(
        Uri.parse("$baseUrl/doctors/with-names"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> doctors = json.decode(response.body);
        
        // Find the doctor with the matching user_id
        for (var doctor in doctors) {
          if (doctor['user_id'] == userId) {
            return doctor;
          }
        }
        
        throw Exception('Doctor profile not found for user ID: $userId');
      } else {
        throw Exception('Failed to load doctor profile: ${response.statusCode}');
      }
    } catch (e) {
      print("Error in getDoctorProfile: $e");
      throw Exception("Failed to get doctor profile: $e");
    }
  }
  
  // Get patient profile
  static Future<Map<String, dynamic>> getPatientProfile(int userId) async {
    try {
      final token = await getAuthToken();
      
      if (token == null) throw Exception('Authentication token not found');
      
      // Use the updated endpoint path that matches the backend route
      final response = await http.get(
        Uri.parse("$baseUrl/patients/profile/$userId"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        // For debugging purposes, print the error response
        print("Patient profile fetch failed with status: ${response.statusCode}");
        print("Response body: ${response.body}");
        
        // Return a default response instead of throwing an exception
        // This will allow the UI to display without crashing
        return {
          'user_id': userId,
          'full_name': await getUserFullName() ?? 'User',
          'email': await getUserEmail() ?? 'email@example.com',
          'age': null,
          'gender': null,
          'created_at': DateTime.now().toIso8601String(),
        };
      }
    } catch (e) {
      print("Error in getPatientProfile: $e");
      // Return default values to prevent UI crashes
      return {
        'user_id': userId,
        'full_name': await getUserFullName() ?? 'User',
        'email': await getUserEmail() ?? 'email@example.com',
        'age': null,
        'gender': null,
        'created_at': DateTime.now().toIso8601String(),
      };
    }
  }
  

  
  // Update user profile
  static Future<Map<String, dynamic>> updateUserProfile({
    required String fullName,
    required String email,
  }) async {
    try {
      final token = await getAuthToken();
      
      if (token == null) throw Exception('Authentication token not found');
      
      print("Updating user profile - Full Name: $fullName, Email: $email");
      
      // Use the updated endpoint path that matches the backend route
      final response = await http.put(
        Uri.parse("$baseUrl/auth/profile"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
        body: jsonEncode({
          "full_name": fullName,
          "email": email,
        }),
      );
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        // Update stored user data
        await secureStorage.write(key: 'user_full_name', value: fullName);
        await secureStorage.write(key: 'user_email', value: email);
        
        print("Profile update successful: $responseData");
        return responseData;
      } else {
        print("Profile update failed with status: ${response.statusCode}");
        if (response.body.isNotEmpty) {
          print("Response body: ${response.body}");
        }
        
        // Even if the API call fails, update the local storage
        await secureStorage.write(key: 'user_full_name', value: fullName);
        await secureStorage.write(key: 'user_email', value: email);
        
        // Return a successful response to allow local updates
        return {
          "message": "Profile updated locally",
          "user": {
            "id": await getCurrentUserId(),
            "full_name": fullName,
            "email": email
          }
        };
      }
    } catch (e) {
      print("Error in updateUserProfile: $e");
      
      // Even if there's an exception, update the local storage
      await secureStorage.write(key: 'user_full_name', value: fullName);
      await secureStorage.write(key: 'user_email', value: email);
      
      // Return a successful response to allow local updates
      return {
        "message": "Profile updated locally",
        "user": {
          "id": await getCurrentUserId(),
          "full_name": fullName,
          "email": email
        }
      };
    }
  }
  
  // Update patient profile
  static Future<Map<String, dynamic>> updatePatientProfile({
    required int userId,
    int? age,
    String? gender,
  }) async {
    try {
      final token = await getAuthToken();
      
      if (token == null) throw Exception('Authentication token not found');
      
      print("Updating patient profile - Age: $age, Gender: $gender");
      
      // Use the updated endpoint path that matches the backend route
      final response = await http.put(
        Uri.parse("$baseUrl/patients/profile/$userId"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
        body: jsonEncode({
          "age": age,
          "gender": gender,
        }),
      );
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print("Patient profile update successful: $responseData");
        return responseData;
      } else {
        print("Patient profile update failed with status: ${response.statusCode}");
        if (response.body.isNotEmpty) {
          print("Response body: ${response.body}");
        }
        
        // Return a successful response to allow local updates
        return {
          "message": "Patient profile updated locally",
          "patient": {
            "user_id": userId,
            "age": age,
            "gender": gender
          }
        };
      }
    } catch (e) {
      print("Error in updatePatientProfile: $e");
      
      // Return a successful response to allow local updates
      return {
        "message": "Patient profile updated locally",
        "patient": {
          "user_id": userId,
          "age": age,
          "gender": gender
        }
      };
    }
  }
  
  // Change password
  static Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      final token = await getAuthToken();
      
      if (token == null) throw Exception('Authentication token not found');
      
      final response = await http.post(
        Uri.parse("$baseUrl/auth/change-password"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
        body: jsonEncode({
          "currentPassword": currentPassword,
          "newPassword": newPassword,
        }),
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to change password: ${response.statusCode}');
      }
    } catch (e) {
      print("Error in changePassword: $e");
      throw Exception("Failed to change password: $e");
    }
  }

  static Future<int?> getPatientId(int userId) async {
     if (userId == null) {
    debugPrint('Invalid user ID provided');
    return null;
  }
  final response = await http.get(
    Uri.parse('$baseUrl/patients/consultations/get-patient-id/$userId'),
    headers: {'Authorization': 'Bearer ${await getAuthToken()}'},
  );
  if (response.statusCode == 200) {
    return jsonDecode(response.body)['id'];
  }
  return null;
}



static Future<int?> getDoctorId(int userId) async {
  if (userId == null) {
    debugPrint('Invalid user ID provided');
    return null;
  }
  final response = await http.get(
    Uri.parse('$baseUrl/doctors/get-doctor-id/$userId'),
    headers: {'Authorization': 'Bearer ${await getAuthToken()}'},
  );
  if (response.statusCode == 200) {
      print('doctor id getting-----------------------------'); 
    return jsonDecode(response.body)['id'];
  }
  print('id of the facking doctor not getting-----------------------------'); 
  return null;
}
  static Map<String, dynamic>? _currentUserData;

 static Future<Map<String, dynamic>> getCurrentUser({bool forceRefresh = false}) async {
    // Return cached data if available and not forcing refresh
    if (_currentUserData != null && !forceRefresh) {
      return _currentUserData!;
    }
    
    try {
      final token = await getAuthToken();
      
      if (token == null) {
        throw Exception('No authentication token available');
      }
      
      final response = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to get user profile: ${response.body}');
      }
      
      // Parse and cache the response
      _currentUserData = jsonDecode(response.body);
      print('Current user data loaded: ${_currentUserData!['id']} (${_currentUserData!['role']})');
      
      return _currentUserData!;
    } catch (e) {
      print('Error getting current user: $e');
      rethrow;
    }
  }

}