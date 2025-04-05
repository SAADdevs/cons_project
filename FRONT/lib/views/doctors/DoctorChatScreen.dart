import 'package:flutter/material.dart';
import 'package:my_app/core/models/chat_message_model.dart';
import 'package:my_app/core/utils/constants.dart';
import 'package:my_app/services/auth_service_api.dart';
import 'package:my_app/services/chat_service.dart';
import 'package:intl/intl.dart';

class DoctorChatScreen extends StatefulWidget {
  final int consultationId;
  final String patientName;
  final int patientId;
  final String? patientImage;
  final bool isDoctor; // ✅ Add this field


  const DoctorChatScreen({
    Key? key,
    required this.consultationId,
    required this.isDoctor,  // ✅ Make sure to pass the value her
    required this.patientName,
    required this.patientId,
    this.patientImage,
  }) : super(key: key);

  @override
  _DoctorChatScreenState createState() => _DoctorChatScreenState();
}

class _DoctorChatScreenState extends State<DoctorChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  int? _userId;
  bool _isPatientOnline = true; // Simulated online status
  
  @override
  void initState() {
    super.initState();
    _loadUserIdAndMessages();
  }
  
  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _loadUserIdAndMessages() async {
    setState(() => _isLoading = true);
    
    try {
      // Get current user ID
      final userId = await ApiService.getCurrentUserId();
      if (userId == null) {
        throw Exception('Failed to get current user ID');
      }
      
      setState(() => _userId = userId);
      
      // Fetch messages
      await _fetchMessages();
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchMessages() async {
    try {
      if (_userId == null) return;
      
      // Get messages for this consultation
      final messages = await ChatService.getConsultationMessages(
        widget.consultationId,
        _userId!,
      );
      
      setState(() {
        _messages.clear();
        _messages.addAll(messages);
      });
      
      // Mark messages as read
      await ChatService.markMessagesAsRead(
        _userId!,
        widget.consultationId,
      );
      
      // Scroll to bottom after messages load
      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load messages: $e')),
      );
    }
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty || _userId == null) return;
    
    setState(() => _isSending = true);
    
    try {
      await ChatService.sendMessage(
  senderId: _userId!,
  receiverId: widget.patientId,
  consultationId: widget.consultationId,
  messageText: messageText,
  isFromDoctor: widget.isDoctor,
);

      
      _messageController.clear();
      
      // Refresh messages
      await _fetchMessages();
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e')),
      );
    } finally {
      setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            // Chat messages area
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildMessagesList(),
            ),
            
            // Input area
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 1,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      leadingWidth: 30,
      titleSpacing: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, size: 24),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            backgroundImage: widget.patientImage != null
                ? NetworkImage(widget.patientImage!)
                : null,
            child: widget.patientImage == null
                ? Text(
                    widget.patientName.isNotEmpty
                        ? widget.patientName[0].toUpperCase()
                        : 'P',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.patientName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _isPatientOnline ? Colors.green : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isPatientOnline ? 'Online' : 'Offline',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.videocam),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Video call feature coming soon')),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.call),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Voice call feature coming soon')),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () => _showOptionsMenu(),
        ),
      ],
    );
  }

  Widget _buildMessagesList() {
    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No messages yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start your conversation with ${widget.patientName}',
              style: TextStyle(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final bool isMe = message.senderId == _userId;
        final bool showAvatar = index == 0 || 
                               _messages[index - 1].senderId != message.senderId;
        final DateTime createdAt = message.createdAt;
final String timeString = DateFormat('h:mm a').format(createdAt);

        
        // Group messages by date
        
final bool showDate = index == 0 || 
                     !_isSameDay(createdAt, _messages[index - 1].createdAt);
        
        return Column(
          children: [
            if (showDate) _buildDateSeparator(message.createdAt),
            
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (!isMe && showAvatar)
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: widget.patientImage != null
                          ? NetworkImage(widget.patientImage!)
                          : null,
                      child: widget.patientImage == null
                          ? Text(
                              widget.patientName.isNotEmpty
                                  ? widget.patientName[0].toUpperCase()
                                  : 'P',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            )
                          : null,
                    )
                  else if (!isMe && !showAvatar)
                    const SizedBox(width: 32),
                  
                  const SizedBox(width: 8),
                  
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isMe 
                            ? AppColors.primary
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20).copyWith(
                          bottomLeft: !isMe ? const Radius.circular(0) : null,
                          bottomRight: isMe ? const Radius.circular(0) : null,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                                message.messageText,
                                style: TextStyle(
                                  color: isMe ? Colors.white : Colors.black87,
                                  fontSize: 16,
                                ),
                              ),
                          const SizedBox(height: 4),
                          Text(
                            timeString,
                            style: TextStyle(
                              color: isMe ? Colors.white70 : Colors.grey[500],
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
  
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && 
           date1.month == date2.month && 
           date1.day == date2.day;
  }

  Widget _buildDateSeparator(DateTime date) {
    // Show date in format: Today, Yesterday or specific date
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);
    
    String dateStr;
    if (messageDate == today) {
      dateStr = 'Today';
    } else if (messageDate == yesterday) {
      dateStr = 'Yesterday';
    } else {
      dateStr = DateFormat('MMMM d, y').format(date);
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey[300])),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                dateStr,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey[300])),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -2),
            blurRadius: 6,
            color: Colors.black.withOpacity(0.06),
          ),
        ],
      ),
      child: Row(
        children: [
          // Attach button
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.add, color: Colors.grey),
              onPressed: () => _showAttachmentOptions(),
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Text field
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                maxLines: null,
                keyboardType: TextInputType.multiline,
              ),
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Send button
          Container(
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.send, color: Colors.white),
              onPressed: _isSending ? null : _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Text(
                'Chat Options',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(),
            _buildOptionTile(
              icon: Icons.article_outlined,
              title: 'Patient Records',
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Patient records coming soon')),
                );
              },
            ),
            _buildOptionTile(
              icon: Icons.description_outlined,
              title: 'Create Prescription',
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Prescription feature coming soon')),
                );
              },
            ),
            _buildOptionTile(
              icon: Icons.event_note_outlined,
              title: 'Schedule Appointment',
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Appointment scheduling coming soon')),
                );
              },
            ),
            _buildOptionTile(
              icon: Icons.block_outlined,
              title: 'Block Patient',
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Block feature coming soon')),
                );
              },
              destructive: true,
            ),
          ],
        ),
      ),
    );
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Attach File',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttachmentOption(
                  icon: Icons.image,
                  color: Colors.green,
                  label: 'Gallery',
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Gallery attachment coming soon')),
                    );
                  },
                ),
                _buildAttachmentOption(
                  icon: Icons.camera_alt,
                  color: Colors.blue,
                  label: 'Camera',
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Camera attachment coming soon')),
                    );
                  },
                ),
                _buildAttachmentOption(
                  icon: Icons.insert_drive_file,
                  color: Colors.orange,
                  label: 'Document',
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Document attachment coming soon')),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttachmentOption(
                  icon: Icons.location_on,
                  color: Colors.red,
                  label: 'Location',
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Location attachment coming soon')),
                    );
                  },
                ),
                _buildAttachmentOption(
                  icon: Icons.contacts,
                  color: Colors.indigo,
                  label: 'Contact',
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Contact attachment coming soon')),
                    );
                  },
                ),
                _buildAttachmentOption(
                  icon: Icons.mic,
                  color: Colors.purple,
                  label: 'Audio',
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Audio attachment coming soon')),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool destructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: destructive ? Colors.red : AppColors.primary,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: destructive ? Colors.red : null,
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required Color color,
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
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}