import 'dart:async';
import 'package:flutter/material.dart';
import 'package:my_app/basrel.dart';
import 'package:my_app/core/models/chat_message_model.dart';
import 'package:my_app/core/models/consultation.dart';
import 'package:my_app/core/utils/constants.dart';
import 'package:my_app/services/auth_service_api.dart';
import 'package:my_app/services/chat_service.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  final Consultation consultation;
  final String receiverName;
  final bool isDoctor;

  const ChatScreen({
    Key? key,
    required this.consultation,
    required this.receiverName,
    required this.isDoctor,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  
  bool _isLoading = true;
  bool _isSending = false;
  bool _isTyping = false;
  bool _otherUserTyping = false;

  
  
  Timer? _typingTimer;
  int? _currentUserId;
  int? _receiverId;
  String? _currentUserName;
  io.Socket? _socket;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

 Future<void> _initialize() async {
  try {
    final userId = await ApiService.getCurrentUserId();
    final userName = await ApiService.getUserFullName();
    final token = await ApiService.getAuthToken();
    
    debugPrint('User ID: $userId');
    debugPrint('User Name: $userName');
    debugPrint('Is Doctor: ${widget.isDoctor}');
    
    if (userId == null || token == null) {
      debugPrint('User information is missing');
      throw Exception('User information not available');
    }

    // Get the receiver's USER ID (not professional ID)
    final receiverUserId = widget.isDoctor 
        ? widget.consultation.patientUserId 
        : widget.consultation.doctorUserId;

    setState(() {
      _currentUserId = userId;
      _currentUserName = userName;
      _receiverId = receiverUserId; // Using user ID now
    });

    debugPrint('Current User ID: $_currentUserId');
    debugPrint('Receiver USER ID: $_receiverId');

    _initSocket(token);
    await _loadMessages();
    
    if (_currentUserId != null) {
      await ChatService.markMessagesAsRead(_currentUserId!, widget.consultation.id);
    }
  } catch (e) {
    debugPrint('Detailed error initializing chat: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Detailed error loading chat: $e')),
      );
    }
  }
}
  void _initSocket(String token) {
    try {
      _socket = io.io(
        baseUrl,
        io.OptionBuilder()
            .setTransports(['websocket'])
            .enableAutoConnect()
            .setExtraHeaders({'Authorization': 'Bearer $token'})
            .setAuth({'token': token})
            .build()
      );

      _socket!.onConnect((_) {
        debugPrint('Connected to Socket.IO server');
        _socket!.emit('join_consultation', widget.consultation.id);
      });

      _socket!.on('new_message', (data) {
        try {
          final message = ChatMessage.fromJson(data);
          if (mounted) {
            setState(() {
              _messages.add(message);
              _otherUserTyping = false;
            });
          }
          _scrollToBottom();
          
          if (message.senderId != _currentUserId && _currentUserId != null) {
            ChatService.markMessagesAsRead(_currentUserId!, widget.consultation.id);
          }
        } catch (e) {
          debugPrint('Error processing new message: $e');
        }
      });

      _socket!.on('user_typing', (data) {
        if (data['user_id'] != _currentUserId && data['consultation_id'] == widget.consultation.id) {
          setState(() => _otherUserTyping = true);
        }
      });

      _socket!.on('user_stop_typing', (data) {
        if (data['user_id'] != _currentUserId && data['consultation_id'] == widget.consultation.id) {
          setState(() => _otherUserTyping = false);
        }
      });

      _socket!.connect();
    } catch (e) {
      debugPrint('Error initializing socket: $e');
    }
  }

  Future<void> _loadMessages() async {
    if (_currentUserId == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      final response = await ChatService.getConsultationMessages(
        widget.consultation.id,
        _currentUserId!,
      );

      List<ChatMessage> loadedMessages = [];
      
      if (response is List) {
        loadedMessages = response.map((msg) => ChatMessage.fromJson(msg)).toList();
      } else if (response is Map && response['data'] is List) {
        loadedMessages = (response['data'] as List)
            .map((msg) => ChatMessage.fromJson(msg))
            .toList();
      } else {
        throw FormatException('Unexpected response format');
      }

      setState(() {
        _messages.clear();
        _messages.addAll(loadedMessages);
        _isLoading = false;
      });
      
      _scrollToBottom();
    } catch (e) {
      debugPrint('Error loading messages: $e');
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load messages');
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: _loadMessages,
          ),
        ),
      );
    }
  }

  void _sendMessage() async {
  final text = _messageController.text.trim();
  if (text.isEmpty) return;

  setState(() => _isSending = true);
  _messageController.clear();

  try {
    // Use the consultation's IDs directly
    final senderProfessionalId = widget.isDoctor 
        ? widget.consultation.doctorId    // If user is doctor, use consultation's doctor ID
        : widget.consultation.patientId;  // If user is patient, use consultation's patient ID
    
    final receiverProfessionalId = widget.isDoctor
        ? widget.consultation.patientId   // If user is doctor, receiver is patient
        : widget.consultation.doctorId;   // If user is patient, receiver is doctor
    
    debugPrint('Sender Professional ID: $senderProfessionalId');
    debugPrint('Receiver Professional ID: $receiverProfessionalId');

    // Create local message
    final localMessage = ChatMessage.createLocalMessage(
      senderId: senderProfessionalId,
      receiverId: receiverProfessionalId,
      consultationId: widget.consultation.id,
      messageText: text,
      senderName: _currentUserName,
      isFromDoctor: widget.isDoctor,
    );

    setState(() => _messages.add(localMessage));
    _scrollToBottom();

    await ChatService.sendMessage(
      senderId: senderProfessionalId,
      receiverId: receiverProfessionalId,
      consultationId: widget.consultation.id,
      messageText: text,
      isFromDoctor: widget.isDoctor,
    );
  } catch (e) {
    debugPrint('Error sending message: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to send: ${e.toString()}')),
    );
    // Remove failed message
    if (_messages.isNotEmpty) {
      setState(() => _messages.removeLast());
    }
  } finally {
    setState(() => _isSending = false);
  }
}

  void _handleTyping() {
    if (!_isTyping && _messageController.text.isNotEmpty && _socket != null) {
      setState(() => _isTyping = true);
      _socket!.emit('typing', {
        'consultation_id': widget.consultation.id,
        'user_id': _currentUserId,
      });
    }
    
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      if (_isTyping && _socket != null) {
        setState(() => _isTyping = false);
        _socket!.emit('stop_typing', {'consultation_id': widget.consultation.id});
      }
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    
    if (_socket != null) {
      _socket!.emit('leave_consultation', widget.consultation.id);
      _socket!.disconnect();
      _socket!.dispose();
    }
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text(widget.receiverName),
    ),
    body: Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(12),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final message = _messages[index];
              final isCurrentUser = message.senderId == _currentUserId;
              
              // Add date headers if needed
              if (index == 0 || 
                  !_isSameDay(message.createdAt, _messages[index-1].createdAt)) {
                return Column(
                  children: [
                    _buildDateDivider(message.createdAt),
                    _buildMessageBubble(message, isCurrentUser),
                  ],
                );
              }
              
              return _buildMessageBubble(message, isCurrentUser);
            },
          ),
        ),
        _buildMessageInputField(),
      ],
    ),
  );
}
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: Icon(
                Icons.chat_outlined,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Start the conversation with ${widget.receiverName}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Send a message to begin your ${widget.consultation.type} consultation',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

 Widget _buildMessageBubble(ChatMessage message, bool isCurrentUser) {
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: isCurrentUser 
          ? MainAxisAlignment.end 
          : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const SizedBox(width: 8),
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: isCurrentUser 
                  ? AppColors.primary 
                  : Colors.grey[200],
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: isCurrentUser 
                    ? const Radius.circular(16) 
                    : const Radius.circular(4),
                bottomRight: isCurrentUser 
                    ? const Radius.circular(4) 
                    : const Radius.circular(16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.messageText,
                  style: TextStyle(
                    color: isCurrentUser ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      DateFormat('h:mm a').format(message.createdAt),
                      style: TextStyle(
                        color: isCurrentUser 
                            ? Colors.white70 
                            : Colors.grey[600],
                        fontSize: 10,
                      ),
                    ),
                    if (isCurrentUser) const SizedBox(width: 4),
                    if (isCurrentUser)
                      Icon(
                        message.isRead 
                            ? Icons.done_all 
                            : Icons.done,
                        size: 12,
                        color: message.isRead 
                            ? Colors.white70 
                            : Colors.white54,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

  Widget _buildDateDivider(DateTime date) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey[300])),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              _formatDate(date),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey[300])),
        ],
      ),
    );
  }

  Widget _buildMessageInputField() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextField(
                controller: _messageController,
                onChanged: (_) => _handleTyping(),
                textCapitalization: TextCapitalization.sentences,
                maxLines: null,
                decoration: InputDecoration(
                  hintText: "Type your message...",
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          MaterialButton(
            onPressed: _messageController.text.trim().isEmpty || _isSending ? null : _sendMessage,
            disabledColor: Colors.grey[300],
            color: AppColors.primary,
            minWidth: 0,
            height: 46,
            elevation: 0,
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(12),
            child: _isSending
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.send, color: Colors.white),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    
    if (_isSameDay(date, now)) {
      return 'Today';
    } else if (_isSameDay(date, now.subtract(const Duration(days: 1)))) {
      return 'Yesterday';
    } else if (now.difference(date).inDays < 7) {
      return DateFormat('EEEE').format(date);
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }

  String _formatTime(DateTime date) {
    return DateFormat('h:mm a').format(date);
  }
}