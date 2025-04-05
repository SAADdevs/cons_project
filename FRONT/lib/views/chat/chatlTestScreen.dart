import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ConsultationChatScreen extends StatefulWidget {
  final String receiverName;
  final String receiverTitle;
  final bool isDoctor;
  final DateTime consultationTime;
  final Duration consultationDuration;

  const ConsultationChatScreen({
    Key? key,
    required this.receiverName,
    required this.receiverTitle,
    required this.isDoctor,
    required this.consultationTime,
    required this.consultationDuration,
  }) : super(key: key);

  @override
  _ConsultationChatScreenState createState() => _ConsultationChatScreenState();
}

class _ConsultationChatScreenState extends State<ConsultationChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isConsultationActive = false;
  Timer? _consultationTimer;
  final List<ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _checkConsultationStatus();
    _setupConsultationTimer();
    _loadSampleMessages();
  }

  @override
  void dispose() {
    _consultationTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadSampleMessages() {
    final now = DateTime.now();
    setState(() {
      _messages.addAll([
        ChatMessage(
          text: 'Hello Patient, when did the symptoms start?',
          isMe: true,
          time: now.subtract(const Duration(minutes: 25)),
          isRead: true,
        ),
        ChatMessage(
          text: '  Hello Doctor, I have been experiencing headaches',
          isMe: false,
          time: now.subtract(const Duration(minutes: 20)),
          isRead: true,
        ),
        ChatMessage(
          text: 'About 3 days ago, mostly in the mornings',
          isMe: true,
          time: now.subtract(const Duration(minutes: 18)),
          isRead: true,
        ),
      ]);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
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

  void _checkConsultationStatus() {
    final now = DateTime.now();
    final endTime = widget.consultationTime.add(widget.consultationDuration);
    
    setState(() {
      _isConsultationActive = now.isAfter(widget.consultationTime) && 
                             now.isBefore(endTime);
    });
  }

  void _setupConsultationTimer() {
    final now = DateTime.now();
    final startDelay = widget.consultationTime.isAfter(now) 
        ? widget.consultationTime.difference(now) 
        : Duration.zero;
    
    final endTime = widget.consultationTime.add(widget.consultationDuration);
    final endDelay = endTime.isAfter(now) 
        ? endTime.difference(now) 
        : Duration.zero;

    if (startDelay > Duration.zero) {
      _consultationTimer = Timer(startDelay, () {
        setState(() => _isConsultationActive = true);
      });
    }

    if (endDelay > Duration.zero) {
      _consultationTimer = Timer(endDelay, () {
        setState(() => _isConsultationActive = false);
      });
    }
  }

  bool get _canSendMessage => widget.isDoctor || _isConsultationActive;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[800],
        elevation: 2,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white,
                radius: 18,
                child: Text(
                  widget.receiverTitle[0],
                  style: TextStyle(
                    color: Colors.blue[800],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.receiverTitle} ${widget.receiverName}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    _isConsultationActive ? 'Active now' : _getConsultationStatus(),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.video_call, color: Colors.white, size: 26),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white, size: 24),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          _buildConsultationInfoBar(),
          Expanded(
            child: _buildMessagesList(),
          ),
          _buildMessageInputField(),
        ],
      ),
    );
  }

  Widget _buildConsultationInfoBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: Colors.blue[50],
      child: Row(
        children: [
          Icon(Icons.access_time, size: 16, color: Colors.blue[800]),
          const SizedBox(width: 8),
          Text(
            'Consultation ${_isConsultationActive ? 'ended at' : _getTimePrefix()} ${_formatConsultationTime()}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue[800],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _getTimePrefix() {
    return DateTime.now().isBefore(widget.consultationTime) 
        ? 'starts' 
        : 'ended';
  }

  String _formatConsultationTime() {
    final time = DateTime.now().isBefore(widget.consultationTime)
        ? widget.consultationTime
        : widget.consultationTime.add(widget.consultationDuration);
    
    return DateFormat('h:mm a').format(time);
  }

  String _getConsultationStatus() {
    final now = DateTime.now();
    if (now.isBefore(widget.consultationTime)) {
      final timeLeft = widget.consultationTime.difference(now);
      return 'Starts in ${timeLeft.inMinutes} min';
    } else {
      return 'Ended';
    }
  }

  Widget _buildMessagesList() {
    if (_messages.isEmpty) {
      return Center(
        child: Text(
          'No messages yet',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(12),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isMe = message.isMe;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              backgroundColor: Colors.blue[100],
              radius: 16,
              child: Text(
                widget.receiverTitle[0],
                style: TextStyle(color: Colors.blue[800]),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: isMe ? Colors.blue[600] : Colors.grey[100],
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isMe ? 16 : 4),
                  topRight: Radius.circular(isMe ? 4 : 16),
                  bottomLeft: const Radius.circular(16),
                  bottomRight: const Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                     color: isMe ? Colors.white : Colors.black87,
                     ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat('h:mm a').format(message.time),
                        style: TextStyle(
                          fontSize: 10,
                          color: isMe 
                              ? Colors.white.withOpacity(0.8) 
                              : Colors.grey[600],
                        ),
                      ),
                      if (isMe) const SizedBox(width: 6),
                      if (isMe)
                        Icon(
                          message.isRead ? Icons.done_all : Icons.done,
                          size: 14,
                          color: message.isRead 
                              ? Colors.white.withOpacity(0.8) 
                              : Colors.white.withOpacity(0.5),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Colors.blue[100],
              radius: 16,
              child: Icon(Icons.person, size: 16, color: Colors.blue[800]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageInputField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.attach_file, color: Colors.blue[600]),
            onPressed: _canSendMessage ? _showAttachmentOptions : null,
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      enabled: _canSendMessage,
                      decoration: InputDecoration(
                        hintText: _canSendMessage 
                            ? "Type your message..." 
                            : _getInputHintText(),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.emoji_emotions_outlined, 
                      color: Colors.blue[600]),
                    onPressed: _canSendMessage ? () {} : null,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          FloatingActionButton(
            onPressed: _canSendMessage ? _sendMessage : null,
            elevation: 0,
            backgroundColor: _canSendMessage 
                ? Colors.blue[600] 
                : Colors.grey[300],
            mini: true,
            child: const Icon(
              Icons.send,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.image, color: Colors.blue[600]),
                title: const Text('Photo Library'),
                onTap: () {
                  Navigator.pop(context);
                  // Handle photo selection
                },
              ),
              ListTile(
                leading: Icon(Icons.insert_drive_file, color: Colors.blue[600]),
                title: const Text('Documents'),
                onTap: () {
                  Navigator.pop(context);
                  // Handle document selection
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt, color: Colors.blue[600]),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  // Handle camera
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String _getInputHintText() {
    if (widget.isDoctor) return "Type your message...";
    
    final now = DateTime.now();
    if (now.isBefore(widget.consultationTime)) {
      return "You can message when consultation starts";
    } else {
      return "Consultation has ended";
    }
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final newMessage = ChatMessage(
      text: text,
      isMe: true,
      time: DateTime.now(),
      isRead: false,
    );

    setState(() {
      _messages.add(newMessage);
      _messageController.clear();
    });
    _scrollToBottom();
  }
}

class ChatMessage {
  final String text;
  final bool isMe;
  final DateTime time;
  final bool isRead;

  ChatMessage({
    required this.text,
    required this.isMe,
    required this.time,
    required this.isRead,
  });
}