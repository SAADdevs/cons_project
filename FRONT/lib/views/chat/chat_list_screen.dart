import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/models/consultation.dart';
import '../../services/consultation_service.dart';
import '../../services/auth_service_api.dart';
import '../../services/chat_service.dart';
import '../../core/utils/constants.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  bool _isLoading = true;
  List<Consultation> _consultations = [];
  int? _userId;
  String? _userRole;
  Map<int, int> _unreadCounts = {};
  final TextEditingController _searchController = TextEditingController();
  List<Consultation> _filteredConsultations = [];

  @override
  void initState() {
    super.initState();
    _loadUserDataAndConsultations();
    _searchController.addListener(_filterConsultations);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserDataAndConsultations() async {
    try {
      setState(() => _isLoading = true);
      
      // Get current user info
      final userId = await ApiService.getCurrentUserId();
      final userRole = await ApiService.getUserRole();
      
      setState(() {
        _userId = userId;
        _userRole = userRole;
      });
      
      if (userId == null) {
        throw Exception('User not authenticated');
      }
      
      await _loadConsultations(userId, userRole ?? '');
      await _loadUnreadCounts(userId);
    } catch (e) {
      debugPrint('Error loading user data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadConsultations(int userId, String role) async {
    try {
      List<Consultation> consultations = [];
      
      if (role == 'patient') {
        consultations = await ConsultationService.getPatientConsultations(userId);
      } else if (role == 'doctor') {
        final upcomingConsultations = await ConsultationService.fetchUpcomingConsultations(userId);
        consultations.addAll(upcomingConsultations);
      }
      
      final chatableConsultations = consultations.where((c) => 
        c.status == 'accepted' || c.status == 'completed').toList();
      
      if (mounted) {
        setState(() {
          _consultations = chatableConsultations;
          _filteredConsultations = chatableConsultations;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading consultations: $e');
      if (mounted) {
        setState(() {
          _consultations = [];
          _filteredConsultations = [];
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadUnreadCounts(int userId) async {
    try {
      final totalUnreadCount = await ChatService.getUnreadCount(userId);
      
      if (_consultations.isNotEmpty && mounted) {
        setState(() {
          _unreadCounts[_consultations[0].id] = totalUnreadCount;
        });
      }
    } catch (e) {
      debugPrint('Error loading unread counts: $e');
    }
  }

  void _filterConsultations() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredConsultations = _consultations.where((consultation) {
        final otherPersonName = _userRole == 'doctor' 
            ? consultation.patientName ?? 'Patient'
            : consultation.doctorName ?? 'Doctor';
        return otherPersonName.toLowerCase().contains(query);
      }).toList();
    });
  }

  String _formatTimestamp(DateTime? timestamp) {
    if (timestamp == null) return '';
    
    final now = DateTime.now();
    if (now.difference(timestamp).inDays == 0) {
      return DateFormat('h:mm a').format(timestamp);
    } else if (now.difference(timestamp).inDays == 1) {
      return 'Yesterday';
    } else {
      return DateFormat('MMM d').format(timestamp);
    }
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
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (_userId != null && _userRole != null) {
                _loadConsultations(_userId!, _userRole!);
                _loadUnreadCounts(_userId!);
              } else {
                _loadUserDataAndConsultations();
              }
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
                : _filteredConsultations.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: () async {
                          if (_userId != null && _userRole != null) {
                            await _loadConsultations(_userId!, _userRole!);
                            await _loadUnreadCounts(_userId!);
                          } else {
                            await _loadUserDataAndConsultations();
                          }
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredConsultations.length,
                          itemBuilder: (context, index) {
                            final consultation = _filteredConsultations[index];
                            return _buildChatCard(consultation);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatCard(Consultation consultation) {
    final bool isDoctor = _userRole == 'doctor';
    final String otherPersonName = isDoctor 
        ? consultation.patientName ?? 'Patient'
        : consultation.doctorName ?? 'Doctor';
    final String subtitle = isDoctor
        ? 'Patient'
        : consultation.doctorSpecialty ?? 'Medical Professional';
    final int unreadCount = _unreadCounts[consultation.id] ?? 0;
    final IconData typeIcon = _getConsultationTypeIcon(consultation.type);
    final Color typeColor = _getConsultationTypeColor(consultation.type);

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                consultation: consultation,
                receiverName: otherPersonName,
                isDoctor: isDoctor,
              ),
            ),
          ).then((_) {
            if (_userId != null) {
              _loadUnreadCounts(_userId!);
            }
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar with unread count
              Stack(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: typeColor.withOpacity(0.1),
                    child: Icon(
                      typeIcon,
                      color: typeColor,
                    ),
                  ),
                  if (unreadCount > 0)
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
                          unreadCount.toString(),
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
                          otherPersonName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          _formatTimestamp(consultation.consultationDate),
                          style: TextStyle(
                            fontSize: 12,
                            color: unreadCount > 0 
                                ? Colors.green 
                                : Colors.grey[500],
                            fontWeight: unreadCount > 0 
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
                            subtitle,
                            style: TextStyle(
                              fontSize: 14,
                              color: unreadCount > 0 
                                  ? Colors.black87 
                                  : Colors.grey[600],
                              fontWeight: unreadCount > 0 
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
                            color: typeColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _getConsultationTypeText(consultation.type),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: typeColor,
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
            'Your accepted consultations will appear here',
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  Color _getConsultationTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'video':
        return Colors.blue;
      case 'voice':
      case 'audio':
        return Colors.orange;
      case 'text':
      default:
        return Colors.green;
    }
  }

  IconData _getConsultationTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'video':
        return Icons.videocam;
      case 'voice':
      case 'audio':
        return Icons.phone;
      case 'text':
      default:
        return Icons.chat_bubble_outline;
    }
  }

  String _getConsultationTypeText(String type) {
    switch (type.toLowerCase()) {
      case 'video':
        return 'Video';
      case 'voice':
      case 'audio':
        return 'Voice';
      case 'text':
      default:
        return 'Text';
    }
  }
}