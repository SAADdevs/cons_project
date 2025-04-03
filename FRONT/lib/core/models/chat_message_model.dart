// lib/core/models/chat_message_model.dart
class ChatMessage {
  final int id;
  final int consultationId;
  final int senderId;
  final int receiverId;
  final String messageText;
  final String? mediaUrl;
  final String messageType;
  final bool isRead;
  final DateTime createdAt;
  final String? senderName;
  final String? receiverName;

  ChatMessage({
    required this.id,
    required this.consultationId,
    required this.senderId,
    required this.receiverId,
    required this.messageText,
    this.mediaUrl,
    required this.messageType,
    required this.isRead,
    required this.createdAt,
    this.senderName,
    this.receiverName,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      consultationId: json['consultation_id'],
      senderId: json['sender_id'],
      receiverId: json['receiver_id'],
      messageText: json['message_text'],
      mediaUrl: json['media_url'],
      messageType: json['message_type'] ?? 'text',
      isRead: json['is_read'] ?? false,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      senderName: json['sender_name'],
      receiverName: json['receiver_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'consultation_id': consultationId,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'message_text': messageText,
      'media_url': mediaUrl,
      'message_type': messageType,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'sender_name': senderName,
      'receiver_name': receiverName,
    };
  }

  // Helper method to create a local message before sending to server
  static ChatMessage createLocalMessage({
    required int senderId,
    required int receiverId,
    required int consultationId,
    required String messageText,
    String? mediaUrl,
    String messageType = 'text',
    String? senderName,
  }) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch, // Temporary ID
      consultationId: consultationId,
      senderId: senderId,
      receiverId: receiverId,
      messageText: messageText,
      mediaUrl: mediaUrl,
      messageType: messageType,
      isRead: false,
      createdAt: DateTime.now(),
      senderName: senderName,
    );
  }
}