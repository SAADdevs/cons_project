import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:my_app/basrel.dart';
import 'package:my_app/core/models/chat_message_model.dart';
import 'package:my_app/core/models/consultation.dart';
import 'package:my_app/core/utils/constants.dart';
import 'package:my_app/services/auth_service_api.dart';
import 'package:my_app/services/chat_service.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:intl/intl.dart';
// ignore: depend_on_referenced_packages
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher.dart' as UrlLauncher;
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;


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

  Future<void> _sendMessage() async {
  if (_messageController.text.trim().isEmpty) {
    return;
  }
  
  setState(() => _isLoading = true);
  
  try {
    // Get current user info from API
    final userData = await ApiService.getCurrentUser();
    
    // Ensure we have integer values by parsing if needed
    final currentUserId = userData['id'] is int ? userData['id'] : int.parse(userData['id'].toString());
    final currentUserRole = userData['role'];
    
    // Debug log which helps diagnose issues
    print('Current user data: $userData');
    print('Current user ID: $currentUserId');
    print('Current user role: $currentUserRole');
    
    // Determine receiver ID based on user role
    int receiverId;
    if (widget.isDoctor) {
      // If we're a doctor, receiver is patient
      receiverId = widget.consultation.patientId;
    } else {
      // If we're a patient, receiver is doctor
      receiverId = widget.consultation.doctorId;
    }
    
    // Ensure IDs are valid integers
    if (currentUserId <= 0) {
      throw Exception('Invalid user ID: $currentUserId');
    }
    
    if (receiverId <= 0) {
      throw Exception('Invalid receiver ID: $receiverId');
    }
    
    if (widget.consultation.id <= 0) {
      throw Exception('Invalid consultation ID: ${widget.consultation.id}');
    }
    
    final messageText = _messageController.text.trim();
    _messageController.clear();
    
    // Create local message for display (uses professional IDs)
    final localMessage = ChatMessage.createLocalMessage(
      senderId: widget.isDoctor ? widget.consultation.doctorId : widget.consultation.patientId,
      receiverId: receiverId,
      consultationId: widget.consultation.id,
      messageText: messageText,
      senderName: userData['full_name'] ?? 'Me',
      isFromDoctor: widget.isDoctor,
    );
    
    setState(() => _messages.add(localMessage));
    _scrollToBottom();
    
    // Send the message with the correct user ID
    await ChatService.sendMessage(
      senderId: currentUserId, // This is the user ID, not the professional ID
      receiverId: receiverId,
      consultationId: widget.consultation.id,
      messageText: messageText,
      isFromDoctor: widget.isDoctor,
    );
    
    print('Message sent successfully from _sendMessage');
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
    setState(() => _isLoading = false);
  }
}

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Attach Media",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildAttachmentOption(
                      icon: Icons.image,
                      label: "Gallery",
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.gallery);
                      },
                    ),
                    _buildAttachmentOption(
                      icon: Icons.camera_alt,
                      label: "Camera",
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.camera);
                      },
                    ),
                    _buildAttachmentOption(
                      icon: Icons.insert_drive_file,
                      label: "Document",
                      onTap: () {
                        Navigator.pop(context);
                        _pickDocument();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 30,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

 Future<void> _pickImage(ImageSource source) async {
  try {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: source,
      imageQuality: 70,
      maxWidth: 1920,  // Limit image dimensions
      maxHeight: 1080,
    );
    
    if (image != null) {
      // Check file size
      final fileSize = await File(image.path).length();
      if (fileSize > 10 * 1024 * 1024) { // 10MB limit
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File is too large. Maximum size is 10MB.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      _uploadAndSendMedia(File(image.path), 'image');
    }
  } catch (e) {
    debugPrint('Error picking image: $e');
    _showErrorSnackBar('Failed to pick image');
  }
}
  Future<void> _pickDocument() async {
  try {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt'],
      // Limit file size
      withReadStream: true,
      withData: false,
    );
    
    if (result != null) {
      final file = File(result.files.single.path!);
      final fileSize = await file.length();
      
      if (fileSize > 10 * 1024 * 1024) { // 10MB limit
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File is too large. Maximum size is 10MB.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      _uploadAndSendMedia(file, 'document');
    }
  } catch (e) {
    debugPrint('Error picking document: $e');
    _showErrorSnackBar('Failed to pick document');
  }
}

Future<void> _uploadAndSendMedia(File file, String type) async {
  try {
    setState(() => _isSending = true);
    
    // Show progress dialog
    _showUploadProgressDialog(type);
    
    // Upload file
    final mediaUrl = await ChatService.uploadMediaFile(
      file: file,
      consultationId: widget.consultation.id,
    );
    
    // Send message with media
    await _sendMessageWithMedia(mediaUrl, type);
    
    // Close the progress dialog
    Navigator.of(context).pop();
  } catch (e) {
    // Close the progress dialog if it's still open
    Navigator.of(context).pop();

    debugPrint('Error uploading media: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Upload failed: ${_getErrorMessage(e)}'),
        backgroundColor: Colors.red,
      ),
    );
  } finally {
    setState(() => _isSending = false);
  }
}

// Helper method to get user-friendly error messages
String _getErrorMessage(dynamic error) {
  if (error is SocketException) {
    return 'Network error. Please check your connection.';
  } else if (error is FormatException) {
    return 'Invalid file format';
  } else if (error is FileSystemException) {
    return 'File access error';
  }
  return error.toString();
}
 Future<void> _sendMessageWithMedia(String mediaUrl, String mediaType) async {
  try {
    // Debug current values
    print('Debug - Consultation data:');
    print('Consultation ID: ${widget.consultation.id}');
    print('Doctor ID: ${widget.consultation.doctorId}');
    print('Patient ID: ${widget.consultation.patientId}');
    print('Is doctor: ${widget.isDoctor}');
    
    // Verify we have valid IDs before proceeding
    if (widget.consultation.doctorId == 0 || widget.consultation.doctorId == null) {
      throw Exception('Invalid doctor ID');
    }
    
    if (widget.consultation.patientId == 0 || widget.consultation.patientId == null) {
      throw Exception('Invalid patient ID');
    }
    
    // Get the correct sender and receiver IDs based on user role
    final senderId = widget.isDoctor 
        ? widget.consultation.doctorId
        : widget.consultation.patientId;
    
    final receiverId = widget.isDoctor
        ? widget.consultation.patientId
        : widget.consultation.doctorId;
    
    // Create placeholder text based on media type
    final messageText = _messageController.text.trim().isEmpty 
        ? 'Sent a ${mediaType == 'image' ? 'photo' : 'document'}'
        : _messageController.text.trim();
    
    _messageController.clear();
    
    // Log the values being sent
    print('Sender Professional ID: $senderId');
    print('Receiver Professional ID: $receiverId');
    
    // Create local message
    final localMessage = ChatMessage.createLocalMessage(
      senderId: 49,
      receiverId: 48,
      consultationId: widget.consultation.id,
      messageText: messageText,
      senderName: _currentUserName,
      isFromDoctor: widget.isDoctor,
      mediaUrl: mediaUrl,
      messageType: mediaType,
    );

    setState(() => _messages.add(localMessage));
    _scrollToBottom();

    await ChatService.sendMessage(
      senderId: 49,
      receiverId: 48,
      consultationId: widget.consultation.id,
      messageText: messageText,
      isFromDoctor: widget.isDoctor,
      mediaUrl: mediaUrl,
      messageType: mediaType,
    );
  } catch (e) {
    debugPrint('Error sending message with media: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to send: ${e.toString()}')),
    );
    // Remove failed message
    if (_messages.isNotEmpty) {
      setState(() => _messages.removeLast());
    }
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

  void _showFullScreenImage(String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            elevation: 0,
          ),
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              boundaryMargin: const EdgeInsets.all(20),
              minScale: 0.5,
              maxScale: 4,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                errorWidget: (context, url, error) => const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 50,
                ),
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openDocument(String documentUrl) async {
    try {
      // Launch URL to open document
      final result = await UrlLauncher.launchUrl(
  Uri.parse(documentUrl),
  mode: UrlLauncher.LaunchMode.externalApplication,
);
      
      if (!result) {
        throw Exception('Could not launch document');
      }
    } catch (e) {
      debugPrint('Error opening document: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to open document: $e')),
      );
    }
  }

  IconData _getFileIcon(String url) {
    final extension = url.split('.').last.toLowerCase();
    
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'txt':
        return Icons.text_snippet;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _getFileName(String url) {
    return url.split('/').last;
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
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.receiverName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              widget.isDoctor ? 'Patient' : widget.consultation.type + ' consultation',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          if (widget.consultation.type.toLowerCase() == 'video')
            IconButton(
              icon: const Icon(Icons.videocam),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Video call feature coming soon')),
                );
              },
            )
          else if (widget.consultation.type.toLowerCase() == 'voice' || 
                  widget.consultation.type.toLowerCase() == 'audio')
            IconButton(
              icon: const Icon(Icons.call),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Voice call feature coming soon')),
                );
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Typing indicator
          if (_otherUserTyping)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: Colors.grey[50],
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    height: 20,
                    child: Stack(
                      children: [
                        Positioned(
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.7),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Positioned(
                          left: 15,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Positioned(
                          left: 30,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${widget.receiverName} is typing...',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          
          // Main chat area
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  )
                : _messages.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(12),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          final isCurrentUser = widget.isDoctor 
                              ? message.isFromDoctor
                              : !message.isFromDoctor;
                          
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

  Widget _buildMessageBubble(ChatMessage message, bool isCurrentUser) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isCurrentUser 
            ? MainAxisAlignment.end 
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isCurrentUser)
            CircleAvatar(
              radius: 16,
              backgroundColor: isCurrentUser 
                  ? AppColors.primary.withOpacity(0.2)
                  : Colors.grey[300],
              child: Text(
                widget.isDoctor 
                    ? (isCurrentUser ? 'D' : 'P')
                    : (isCurrentUser ? 'P' : 'D'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isCurrentUser 
                      ? AppColors.primary
                      : Colors.grey[700],
                ),
              ),
            ),
          
          const SizedBox(width: 8),
          
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: message.messageType == 'text' 
                  ? const EdgeInsets.symmetric(horizontal: 16, vertical: 10)
                  : const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Display media content based on message type
                  if (message.messageType == 'image' && message.mediaUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: GestureDetector(
                        onTap: () => _showFullScreenImage(message.mediaUrl!),
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.6,
                            maxHeight: 200,
                          ),
                          child: CachedNetworkImage(
                            imageUrl: message.mediaUrl!,
                            placeholder: (context, url) => Center(
                              child: SizedBox(
                                width: 30,
                                height: 30,
                                child: CircularProgressIndicator(
                                  color: isCurrentUser 
                                      ? Colors.white70 
                                      : AppColors.primary,
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              width: 100,
                              height: 100,
                              color: Colors.grey[300],
                              child: const Icon(
                                Icons.error_outline,
                                color: Colors.red,
                              ),
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    )
                  else if (message.messageType == 'document' && message.mediaUrl != null)
                    GestureDetector(
                      onTap: () => _openDocument(message.mediaUrl!),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: isCurrentUser 
                              ? Colors.white.withOpacity(0.1) 
                              : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getFileIcon(message.mediaUrl!),
                              color: isCurrentUser 
                                  ? Colors.white 
                                  : AppColors.primary,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _getFileName(message.mediaUrl!),
                                    style: TextStyle(
                                      color: isCurrentUser 
                                          ? Colors.white 
                                          : Colors.black87,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'Document',
                                    style: TextStyle(
                                      color: isCurrentUser 
                                          ? Colors.white70 
                                          : Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                
                  // Show message text if not empty
                  if (message.messageText.isNotEmpty &&
                      !(message.messageType != 'text' && 
                        message.messageText.startsWith('Sent a')))
                    Padding(
                      padding: EdgeInsets.only(
                        top: message.messageType != 'text' ? 8 : 0,
                        bottom: 4,
                        left: message.messageType != 'text' ? 4 : 0,
                        right: message.messageType != 'text' ? 4 : 0,
                      ),
                      child: Text(
                        message.messageText,
                        style: TextStyle(
                          color: isCurrentUser ? Colors.white : Colors.black87,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  
                  // Show timestamp and read status
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
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
          
          const SizedBox(width: 8),
          
          if (isCurrentUser)
            CircleAvatar(
              radius: 16,
              backgroundColor: isCurrentUser 
                  ? AppColors.primary.withOpacity(0.2)
                  : Colors.grey[300],
              child: Text(
                widget.isDoctor 
                    ? (isCurrentUser ? 'D' : 'P')
                    : (isCurrentUser ? 'P' : 'D'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isCurrentUser 
                      ? AppColors.primary
                      : Colors.grey[700],
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
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _formatDate(date),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w500,
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
          // Add attachment button
          IconButton(
            icon: const Icon(Icons.attach_file),
            color: AppColors.primary,
            onPressed: _showAttachmentOptions,
          ),
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

  void _showUploadProgressDialog(String type) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return Dialog(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Uploading $type',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 20),
              const LinearProgressIndicator(),
              const SizedBox(height: 20),
              Text(
                'Please wait...',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    },
  );
}
}