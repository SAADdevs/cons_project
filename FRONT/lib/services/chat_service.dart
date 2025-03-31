// lib/services/chat_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/models/chat_message.dart';
import '../services/auth_service_api.dart';

class ChatService {
  static const String baseUrl = "http://192.168.1.10:5000/api/chat"; // Update with your server IP

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
  static Future<List<ChatMessage>> getConsultationChat(
    int consultationId, 
    int userId,
  ) async {
    try {
      final token = await ApiService.getAuthToken();
      if (token == null) throw Exception('Authentication token not found');

      final response = await http.get(
        Uri.parse('$baseUrl/consultation/$consultationId?user_id=$userId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => ChatMessage.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load chat history: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting chat history: $e');
    }
  }

  // Get unread message count
  static Future<int> getUnreadCount(int userId) async {
    try {
      final token = await ApiService.getAuthToken();
      if (token == null) throw Exception('Authentication token not found');

      final response = await http.get(
        Uri.parse('$baseUrl/unread/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['unread_count'];
      } else {
        throw Exception('Failed to get unread count: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting unread count: $e');
    }
  }

  // Mark messages as read
  static Future<void> markMessagesAsRead(
    int userId, 
    int consultationId,
  ) async {
    try {
      final token = await ApiService.getAuthToken();
      if (token == null) throw Exception('Authentication token not found');

      final response = await http.put(
        Uri.parse('$baseUrl/mark-read'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'user_id': userId,
          'consultation_id': consultationId,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to mark messages as read: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error marking messages as read: $e');
    }
  }
}