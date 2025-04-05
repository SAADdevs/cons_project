import 'package:flutter/material.dart';
import 'package:my_app/core/utils/constants.dart';
import 'package:my_app/services/chat_service.dart';
import 'package:my_app/services/auth_service_api.dart';
import 'package:intl/intl.dart';

class DoctorChatListScreen extends StatefulWidget {
  const DoctorChatListScreen({Key? key}) : super(key: key);

  @override
  _DoctorChatListScreenState createState() => _DoctorChatListScreenState();
}

class _DoctorChatListScreenState extends State<DoctorChatListScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _chatList = [];
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredChatList = [];

  @override
  void initState() {
    super.initState();
    _loadChats();
    _searchController.addListener(_filterChats);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadChats() async {
    setState(() => _isLoading = true);
    try {
      // Get current user ID
      final userId = await ApiService.getCurrentUserId();
      if (userId == null) {
        throw Exception('User ID not found');
      }

      // Fetch chats (this is a placeholder - replace with actual chat service method)
      final chats = await _fetchChatList(userId);

      setState(() {
        _chatList = chats;
        _filteredChatList = chats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading chats: $e')),
      );
    }
  }

  // Placeholder method - replace with actual chat service implementation
  Future<List<Map<String, dynamic>>> _fetchChatList(int userId) async {
    // Simulated chat list data
    return [
      {
        'consultationId': 1,
        'patientId': 101,
        'patientName': 'Emma Phillips',
        'lastMessage': 'Thank you for the consultation, doctor.',
        'timestamp': DateTime.now().subtract(const Duration(minutes: 30)),
        'unreadCount': 2,
        'patientImage': null,
        'consultationType': 'video'
      },
      {
        'consultationId': 2,
        'patientId': 102,
        'patientName': 'John Cooper',
        'lastMessage': 'When should I take the medication?',
        'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
        'unreadCount': 0,
        'patientImage': null,
        'consultationType': 'text'
      },
      {
        'consultationId': 3,
        'patientId': 103,
        'patientName': 'Lisa Wong',
        'lastMessage': 'I\'ve been feeling better since last visit',
        'timestamp': DateTime.now().subtract(const Duration(days: 1)),
        'unreadCount': 0,
        'patientImage': null,
        'consultationType': 'voice'
      },
    ];
  }

  void _filterChats() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredChatList = _chatList.where((chat) {
        return chat['patientName'].toLowerCase().contains(query);
      }).toList();
    });
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    if (now.difference(timestamp).inDays == 0) {
      return DateFormat('h:mm a').format(timestamp);
    } else if (now.difference(timestamp).inDays == 1) {
      return 'Yesterday';
    } else {
      return DateFormat('MMM d').format(timestamp);
    }
  }

  Color _getConsultationTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'video':
        return Colors.blue;
      case 'voice':
        return Colors.orange;
      case 'text':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _navigateToChatScreen(Map<String, dynamic> chatData) {
    Navigator.pushNamed(
      context,
      '/doctor/chat',
      arguments: {
        'consultationId': chatData['consultationId'],
        'patientName': chatData['patientName'],
        'patientId': chatData['patientId'],
        'patientImage': chatData['patientImage'],
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Chats'),
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_comment),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Start new chat coming soon')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search chats...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),

          // Chat list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredChatList.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadChats,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredChatList.length,
                          itemBuilder: (context, index) {
                            final chat = _filteredChatList[index];
                            return _buildChatCard(chat);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Start new chat coming soon')),
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.chat, color: Colors.white),
      ),
    );
  }

  Widget _buildChatCard(Map<String, dynamic> chat) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _navigateToChatScreen(chat),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Patient avatar
              Stack(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    backgroundImage: chat['patientImage'] != null
                        ? NetworkImage(chat['patientImage'])
                        : null,
                    child: chat['patientImage'] == null
                        ? Text(
                            chat['patientName'].toString().isNotEmpty
                                ? chat['patientName'].toString()[0].toUpperCase()
                                : 'U',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                              fontSize: 18,
                            ),
                          )
                        : null,
                  ),
                  if (chat['unreadCount'] > 0)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          chat['unreadCount'].toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),

              // Chat details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          chat['patientName'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          _formatTimestamp(chat['timestamp']),
                          style: TextStyle(
                            fontSize: 12,
                            color: chat['unreadCount'] > 0 
                                ? Colors.green 
                                : Colors.grey[500],
                            fontWeight: chat['unreadCount'] > 0 
                                ? FontWeight.bold 
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            chat['lastMessage'],
                            style: TextStyle(
                              fontSize: 14,
                              color: chat['unreadCount'] > 0 
                                  ? Colors.black87 
                                  : Colors.grey[600],
                              fontWeight: chat['unreadCount'] > 0 
                                  ? FontWeight.w500 
                                  : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8, 
                            vertical: 4
                          ),
                          decoration: BoxDecoration(
                            color: _getConsultationTypeColor(chat['consultationType'])
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            chat['consultationType'],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _getConsultationTypeColor(chat['consultationType']),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Chats Yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a conversation with your patients',
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Start new chat coming soon')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Start New Chat'),
          ),
        ],
      ),
    );
  }
}