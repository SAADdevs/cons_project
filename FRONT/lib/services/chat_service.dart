import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:my_app/core/models/consultation.dart';
import 'package:path/path.dart' as path;
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

static Future<String> uploadMediaFile({
    required File file,
    required int consultationId,
    String? description,
  }) async {
    try {
      final token = await ApiService.getAuthToken();
      if (token == null) throw Exception('Authentication token not found');

      // Determine MIME type manually
      final mimeType = _getMimeType(file.path);
      
      // Create multipart request
      final request = http.MultipartRequest(
        'POST', 
        Uri.parse('$baseUrl/chat/upload-media')
      );

      // Add headers
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Content-Type': 'multipart/form-data',
      });

      // Add file to request
      request.files.add(
        await http.MultipartFile.fromPath(
          'file', 
          file.path,
          filename: path.basename(file.path),
        )
      );

      // Add additional form fields
      request.fields['consultation_id'] = consultationId.toString();
      if (description != null) {
        request.fields['description'] = description;
      }

      // Send request and get response
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      // Handle response
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseBody = json.decode(response.body);
        final mediaUrl = responseBody['media_url'];
        
        if (mediaUrl == null) {
          throw Exception('Media URL not found in response');
        }
        
        return mediaUrl;
      } else {
        throw Exception('File upload failed: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error uploading media file: $e');
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
     static Future<void> sendMessage({
    int? senderId,  // This can be null or 0
    required int receiverId,
    required int consultationId,
    required String messageText,
    required bool isFromDoctor,
    String? mediaUrl,
    String? messageType,
  }) async {
    try {
      // Get the current user data if senderId is null or 0
      int actualSenderId;
      
      if (senderId == null || senderId == 0) {
        // Fetch current user info from API
        final userData = await ApiService.getCurrentUser();
        
        // Make sure the ID is an integer
        actualSenderId = userData['id'] is int ? userData['id'] : int.parse(userData['id'].toString());
        
        print('Updated sender ID from ${senderId ?? 'null'} to $actualSenderId');
        
        // Double check that we have a valid ID now
        if (actualSenderId == 0) {
          throw Exception('Unable to determine user ID');
        }
      } else {
        actualSenderId = senderId;
      }
      
      // Debug log
      print("Sending message with:");
      print("- Sender ID: $actualSenderId");
      print("- Receiver ID: $receiverId");
      print("- Consultation ID: $consultationId");
      print("- Is From Doctor: $isFromDoctor");
      
      // Prepare the payload
      final payload = {
        'sender_id': actualSenderId,
        'receiver_id': receiverId,
        'consultation_id': consultationId,
        'message_text': messageText,
        'is_from_doctor': isFromDoctor,
      };

      // Add optional fields only if they are provided and not empty
      if (mediaUrl != null && mediaUrl.isNotEmpty) {
        payload['media_url'] = mediaUrl;
      }
      
      if (messageType != null && messageType.isNotEmpty) {
        payload['message_type'] = messageType;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/chat/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await ApiService.getAuthToken()}',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode != 201) {
        throw Exception('Failed to send message: ${response.body}');
      }

      print('Message sent successfully');
      return;
    } catch (e) {
      print('Send message error: $e');
      rethrow;
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

  static String _getMimeType(String path) {
    final extension = path.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      case 'mp4':
        return 'video/mp4';
      case 'txt':
        return 'text/plain';
      default:
        return 'application/octet-stream';
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


static String _determineMediaType(File file) {
    final extension = path.extension(file.path).toLowerCase().replaceFirst('.', '');
    switch (extension) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
        return 'image';
      case 'pdf':
      case 'doc':
      case 'docx':
      case 'xls':
      case 'xlsx':
        return 'document';
      case 'mp3':
      case 'wav':
      case 'aac':
        return 'audio';
      case 'mp4':
      case 'avi':
      case 'mov':
        return 'video';
      default:
        return 'file';
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

 


   
}
