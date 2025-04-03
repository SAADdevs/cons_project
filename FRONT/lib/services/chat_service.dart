import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
<<<<<<< HEAD
import 'package:my_app/core/models/consultation.dart';
import '../basrel.dart';
import '../core/models/chat_message_model.dart';
import '../services/auth_service_api.dart';

class ChatService {
  // Get consultation chat history
=======
import 'package:my_app/basrel.dart';
import '../core/models/chat_message.dart';
import '../services/auth_service_api.dart';

class ChatService {

  // Send a new message
  static Future<ChatMessage> sendMessage({
    required int senderId,
    required int receiverId,
    required int consultationId,
    required String messageText,
  }) async {
    try {
      final token = await ApiService.getAuthToken();
      if (token == null) throw Exception('Authentication token not found');

      final response = await http.post(
        Uri.parse('$baseUrl/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'sender_id': senderId,
          'receiver_id': receiverId,
          'consultation_id': consultationId,
          'message_text': messageText,
        }),
      );

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return ChatMessage.fromJson(responseData['chat_message']);
      } else {
        throw Exception('Failed to send message: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error sending message: $e');
    }
  }

  // Get chat history for a consultation
>>>>>>> 0f49f28f3662df96fa31f9030c2bdd0187900a80
  static Future<List<ChatMessage>> getConsultationChat(
    int consultationId, 
    int userId,
  ) async {
    try {
      final token = await ApiService.getAuthToken();
      if (token == null) throw Exception('Authentication token not found');

      // Debug log
      debugPrint('Getting chat for consultationId: $consultationId, userId: $userId');

      final response = await http.get(
        Uri.parse('$baseUrl/chat/consultation/$consultationId?user_id=$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      // Debug logs
      debugPrint('Status code: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => ChatMessage.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load chat history: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Error getting chat history: $e');
      throw Exception('Error getting chat history: $e');
    }
  }

  // Get unread message count for a user in a specific consultation
  static Future<int> getUnreadCountForConsultation(
    int userId, 
    int consultationId
  ) async {
    try {
      final token = await ApiService.getAuthToken();
      if (token == null) throw Exception('Authentication token not found');

      final response = await http.get(
        Uri.parse('$baseUrl/chat/unread/$userId/$consultationId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['unread_count'] ?? 0;
      } else {
        throw Exception('Failed to get unread count for consultation: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error getting unread count for consultation: $e');
      return 0; // Return 0 on error to prevent UI issues
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

  // Mark messages as read
  static Future<void> markMessagesAsRead(int userId, int consultationId) async {
    try {
      final token = await ApiService.getAuthToken();
      if (token == null) throw Exception('Authentication token not found');

      // Debug log
      debugPrint('Marking messages as read for userId: $userId, consultationId: $consultationId');

      final response = await http.put(
        Uri.parse('$baseUrl/chat/mark-read'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'user_id': userId,
          'consultation_id': consultationId,
        }),
      );

      // Debug logs
      debugPrint('Status code: ${response.statusCode}');
      if (response.body.isNotEmpty) {
        debugPrint('Response body: ${response.body}');
      }

      if (response.statusCode != 200) {
        throw Exception('Failed to mark messages as read: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
      throw Exception('Error marking messages as read: $e');
    }
  }

  // Send a message
  static Future<ChatMessage> sendMessage({
    required int senderId,
    required int receiverId,
    required int consultationId,
    required String messageText,
    String messageType = 'text',
    String? mediaUrl,
  }) async {
    try {
      final token = await ApiService.getAuthToken();
      if (token == null) throw Exception('Authentication token not found');

      // Debug log
      debugPrint('Sending message from: $senderId to: $receiverId for consultation: $consultationId');

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
          'message_type': messageType,
          'media_url': mediaUrl,
        }),
      );

      // Debug logs
      debugPrint('Status code: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        return ChatMessage.fromJson(responseData['chat_message']);
      } else {
        throw Exception('Failed to send message: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Error sending message: $e');
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
}