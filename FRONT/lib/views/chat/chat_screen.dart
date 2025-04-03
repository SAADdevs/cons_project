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
  final bool isDoctor; // To determine UI layout

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
      // Get current user ID and token
      final userId = await ApiService.getCurrentUserId();
      final userName = await ApiService.getUserFullName();
      final token = await ApiService.getAuthToken();
      
      if (userId == null || token == null) {
        throw Exception('User information not available');
      }

      setState(() {
        _currentUserId = userId;
        _currentUserName = userName;
        
        // Determine receiver ID based on whether current user is doctor or patient
        if (widget.isDoctor) {
          _receiverId = widget.consultation.patientId;
        } else {
          _receiverId = widget.consultation.doctorId;
        }
      });

      // Initialize socket connection
      _initSocket(token);
      
      // Load message history
      await _loadMessages();
      
      // Mark messages as read when opening the chat
      if (_currentUserId != null) {
        await ChatService.markMessagesAsRead(_currentUserId!, widget.consultation.id);
      }
    } catch (e) {
      debugPrint('Error initializing chat: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading chat: $e')),
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
        
        // Join the consultation room
        _socket!.emit('join_consultation', widget.consultation.id);
      });

      _socket!.onDisconnect((_) {
        debugPrint('Disconnected from Socket.IO server');
      });

      _socket!.on('error', (data) {
        debugPrint('Socket error: $data');
      });

      // Handle incoming messages
      _socket!.on('new_message', (data) {
        debugPrint('New message received: $data');
        final message = ChatMessage.fromJson(data);
        
        setState(() {
          _messages.add(message);
          _otherUserTyping = false;
        });
        
        // Scroll to bottom on new message
        _scrollToBottom();
        
        // Mark as read if from the other user
        if (message.senderId != _currentUserId && _currentUserId != null) {
          ChatService.markMessagesAsRead(_currentUserId!, widget.consultation.id);
        }
      });

      // Handle typing indicators
      _socket!.on('user_typing', (data) {
        // Check if typing indicator is from the other user
        if (data['user_id'] != _currentUserId && data['consultation_id'] == widget.consultation.id) {
          setState(() => _otherUserTyping = true);
        }
      });

      _socket!.on('user_stop_typing', (data) {
        // Check if typing indicator is from the other user
        if (data['user_id'] != _currentUserId && data['consultation_id'] == widget.consultation.id) {
          setState(() => _otherUserTyping = false);
        }
      });

      // Connect to the socket server
      _socket!.connect();
    } catch (e) {
      debugPrint('Error initializing socket: $e');
    }
  }

  Future<void> _loadMessages() async {
    if (_currentUserId == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      final messages = await ChatService.getConsultationChat(
        widget.consultation.id, 
        _currentUserId!,
      );
      
      setState(() {
        _messages.clear();
        _messages.addAll(messages);
        _isLoading = false;
      });
      
      // Scroll to bottom after messages load
      _scrollToBottom();
    } catch (e) {
      debugPrint('Error loading messages: $e');
      setState(() => _isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading messages: $e')),
        );
      }
    }
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _currentUserId == null || _receiverId == null || _isSending) return;
    
    setState(() => _isSending = true);
    
    // Clear text field immediately for better UX
    _messageController.clear();
    
    // Cancel typing indicator
    _typingTimer?.cancel();
    if (_socket != null) {
      _socket!.emit('stop_typing', {'consultation_id': widget.consultation.id});
    }
    setState(() => _isTyping = false);
    
    try {
      // Create local message for immediate UI feedback
      final localMessage = ChatMessage.createLocalMessage(
        senderId: _currentUserId!,
        receiverId: _receiverId!,
        consultationId: widget.consultation.id,
        messageText: text,
        senderName: _currentUserName,
      );
      
      // Add to local messages
      setState(() => _messages.add(localMessage));
      
      // Scroll to bottom
      _scrollToBottom();
      
      // Send via socket if available
      if (_socket != null && _socket!.connected) {
        _socket!.emit('send_message', {
          'consultation_id': widget.consultation.id,
          'receiver_id': _receiverId,
          'message_text': text,
          'message_type': 'text',
        });
      }
      
      // Also send via HTTP API as fallback
      await ChatService.sendMessage(
        senderId: _currentUserId!,
        receiverId: _receiverId!,
        consultationId: widget.consultation.id,
        messageText: text,
      );
    } catch (e) {
      debugPrint('Error sending message: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending message: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  void _handleTyping() {
    if (!_isTyping && _messageController.text.isNotEmpty && _socket != null) {
      setState(() => _isTyping = true);
      _socket!.emit('typing', {'consultation_id': widget.consultation.id});
    }
    
    // Reset typing timer
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      if (_isTyping && _socket != null) {
        setState(() => _isTyping = false);
        _socket!.emit('stop_typing', {'consultation_id': widget.consultation.id});
      }
    });
  }

  void _scrollToBottom() {
    // Delayed to ensure the list is built
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
    
    // Leave consultation room and disconnect socket
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.receiverName),
            const SizedBox(height: 2),
            Text(
              widget.isDoctor ? 'Patient' : widget.consultation.doctorSpecialty ?? 'Doctor',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          // Add voice/video call buttons based on consultation type
          if (widget.consultation.type == 'video' || widget.consultation.type == 'voice')
            IconButton(
              icon: Icon(widget.consultation.type == 'video' ? Icons.videocam : Icons.phone),
              onPressed: () {
                // Handle initiating call
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${widget.consultation.type} calling feature coming soon')),
                );
              },
              tooltip: widget.consultation.type == 'video' ? 'Video Call' : 'Voice Call',
            ),
        ],
      ),
      body: _currentUserId == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Typing indicator
                if (_otherUserTyping)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 40,
                          child: Center(
                            child: SizedBox(
                              width: 30,
                              height: 30,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${widget.receiverName} is typing...',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Chat messages
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _messages.isEmpty
                          ? _buildEmptyState()
                          : _buildChatMessages(),
                ),
                
                // Message input
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

  Widget _buildChatMessages() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isMe = message.senderId == _currentUserId;
        final showDate = index == 0 ||
            !_isSameDay(message.createdAt, _messages[index - 1].createdAt);

        return Column(
          children: [
            if (showDate) _buildDateDivider(message.createdAt),
            _buildMessageBubble(message, isMe),
          ],
        );
      },
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

  Widget _buildMessageBubble(ChatMessage message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : Colors.grey[200],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
            bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Message text
            Text(
              message.messageText,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
                fontSize: 16,
              ),
            ),
            
            // Message time
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    _formatTime(message.createdAt),
                    style: TextStyle(
                      fontSize: 10,
                      color: isMe ? Colors.white70 : Colors.grey,
                    ),
                  ),
                  if (isMe) const SizedBox(width: 4),
                  if (isMe)
                    Icon(
                      message.isRead ? Icons.done_all : Icons.done,
                      size: 12,
                      color: message.isRead ? Colors.white70 : Colors.white38,
                    ),
                ],
              ),
            ),
          ],
        ),
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
          // Message text field
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
          
          // Send button
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

  // Helper methods
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
      // Return day of week for dates within the last week
      final format = DateFormat('EEEE'); // Full day name (e.g., "Monday")
      return format.format(date);
    } else {
      // Return the full date for older messages
      final format = DateFormat('MMM d, yyyy'); // e.g., "Jan 1, 2025"
      return format.format(date);
    }
  }

  String _formatTime(DateTime date) {
    return DateFormat('h:mm a').format(date); // e.g., "2:30 PM"
  }
}