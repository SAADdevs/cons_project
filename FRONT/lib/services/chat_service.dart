import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:my_app/core/models/consultation.dart';
import '../basrel.dart';
import '../core/models/chat_message_model.dart';
import '../services/auth_service_api.dart';

class ChatService {
  // Get consultation chat history

  static Future<dynamic> getConsultationMessages(int consultationId, int userId) async {
  try {
    debugPrint('Fetching consultation messages');
    debugPrint('Consultation ID: $consultationId');
    debugPrint('User ID: $userId');

    final token = await ApiService.getAuthToken();
    if (token == null) {
      debugPrint('No authentication token found');
      throw Exception('Authentication token is missing');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/chat/consultation/$consultationId?user_id=$userId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    debugPrint('Response Status Code: ${response.statusCode}');
    debugPrint('Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final responseBody = json.decode(response.body);
      
      if (responseBody['success'] == true) {
        final List<dynamic> data = responseBody['data'];
        debugPrint('Parsed Messages Count: ${data.length}');
        return data;
      } else {
        throw Exception('Failed to load chat history: ${responseBody['message']}');
      }
    } else {
      throw Exception('Failed to load chat history: ${response.body}');
    }
  } catch (e) {
    debugPrint('Error in getConsultationMessages: $e');
    rethrow;
  }
}

  // Get unread message count for all consultations
  static Future<int> getUnreadCount(int userId) async {
    try {
      final token = await ApiService.getAuthToken();
      if (token == null) throw Exception('Authentication token not found');

      final response = await http.get(
        Uri.parse('$baseUrl/chat/unread/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['unread_count'] ?? 0;
      } else {
        throw Exception('Failed to get unread count: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error getting unread count: $e');
      return 0; // Return 0 on error to prevent UI issues
    }
  }
  // Send a message
 static Future<ChatMessage> sendMessage({
  required int senderId,
  required int receiverId,
  required int consultationId,
  required String messageText,
  required bool isFromDoctor,
}) async {
  try {
    final token = await ApiService.getAuthToken();
    if (token == null) throw Exception('Authentication token not found');
    
    final response = await http.post(
      Uri.parse('$baseUrl/chat/send'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'sender_id': senderId,
        'receiver_id': receiverId,
        'consultation_id': consultationId,
        'message_text': messageText,
        'is_from_doctor': isFromDoctor,
      }),
    );
    
    if (response.statusCode == 201) {
      final responseData = json.decode(response.body);
      return ChatMessage.fromJson(responseData['chat_message']);
    } else {
      throw Exception('Failed to send message: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Error sending message: $e');
  }
}
  static Future<List<Consultation>> fetchUpcomingConsultations(int doctorId) async {
    try {
      final token = await ApiService.getAuthToken();
      if (token == null) throw Exception('Authentication token not found');
      
      final response = await http.get(
        Uri.parse('$baseUrl/upcoming-appointments/doctor/$doctorId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Consultation.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load upcoming consultations');
      }
    } catch (e) {
      throw Exception('Error fetching upcoming consultations: $e');
    }
  }

  static Future<Map<String, dynamic>> getPaginatedMessages({
    required int consultationId,
    int page = 1,
    int limit = 50,
    String sortOrder = 'ASC',
    DateTime? startDate,
    DateTime? endDate,
    String? searchText,
    int? userId,
  }) async {
    try {
      // Construct query parameters
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        'sortOrder': sortOrder,
        if (startDate != null) 'startDate': startDate.toIso8601String(),
        if (endDate != null) 'endDate': endDate.toIso8601String(),
        if (searchText != null) 'searchText': searchText,
        if (userId != null) 'user_id': userId.toString(),
      };

      // Convert query params to URL-encoded string
      final queryString = queryParams.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');

      final response = await http.get(
        Uri.parse('$baseUrl/chat/consultation/$consultationId/paginated?$queryString'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _getAuthToken()}',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(response.body);
        return {
          'messages': (body['messages'] as List)
              .map((item) => ChatMessage.fromJson(item))
              .toList(),
          'total': body['total'],
          'page': body['page'],
          'limit': body['limit'],
        };
      } else {
        throw Exception('Failed to load paginated messages');
      }
    } catch (e) {
      print('Error fetching paginated messages: $e');
      rethrow;
    }
  }
  static Future<int> getUnreadMessageCount(
    int userId, {
    int? consultationId,
  }) async {
    try {
      final url = consultationId != null
        ? '$baseUrl/chat/unread-count/$userId?consultation_id=$consultationId'
        : '$baseUrl/chat/unread-count/$userId';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _getAuthToken()}',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body)['unread_count'];
      } else {
        throw Exception('Failed to load unread message count');
      }
    } catch (e) {
      print('Error fetching unread message count: $e');
      rethrow;
    }
  }
  static Future<void> markMessagesAsRead(int userId, int consultationId) async {

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/chat/mark-read'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _getAuthToken()}',
        },
        body: json.encode({
          'user_id': userId,
          'consultation_id': consultationId,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to mark messages as read');
      }
    } catch (e) {
      print('Error marking messages as read: $e');
      rethrow;
    }
  }





  

  static Future<String> _getAuthToken() async {
  const storage = FlutterSecureStorage();
  
  try {
    // Try to get the token from secure storage
    final token = await storage.read(key: 'auth_token');
    
    if (token == null) {
      throw Exception('No authentication token found');
    }
    
    return token;
  } catch (e) {
    debugPrint('Error retrieving auth token: $e');
    // You might want to handle this differently - perhaps by:
    // 1. Redirecting to login screen
    // 2. Attempting to refresh the token
    // 3. Throwing a specific exception
    rethrow;
  }
}



  // Get consultation chat history
  

  // Get unread message count for all consultations
  

  
  
  // static Future<void> markMessagesAsRead({
  //   required int userId,
  //   required int consultationId,
  // }) async {
  //   try {
  //     final response = await http.put(
  //       Uri.parse('$baseUrl/chat/mark-read'),
  //       headers: {
  //         'Content-Type': 'application/json',
  //         'Authorization': 'Bearer ${await _getAuthToken()}',
  //       },
  //       body: json.encode({
  //         'user_id': userId,
  //         'consultation_id': consultationId,
  //       }),
  //     );

  //     if (response.statusCode != 200) {
  //       throw Exception('Failed to mark messages as read');
  //     }
  //   } catch (e) {
  //     print('Error marking messages as read: $e');
  //     rethrow;
  //   }
  // }




   
}
