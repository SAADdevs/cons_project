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
  Map<int, int> _unreadCounts = {}; // Mapping consultation ID to unread message count

  @override
  void initState() {
    super.initState();
    _loadUserDataAndConsultations();
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
        // Get patient consultations
        consultations = await ConsultationService.getPatientConsultations(userId);
      } else if (role == 'doctor') {
        // Get doctor's accepted consultations
        final upcomingConsultations = await ConsultationService.fetchUpcomingConsultations(userId);
        consultations.addAll(upcomingConsultations);
      }
      
      // Filter consultations to show only accepted or completed ones (those that can have chats)
      final chatableConsultations = consultations.where((c) => 
        c.status == 'accepted' || c.status == 'completed').toList();
      
      if (mounted) {
        setState(() {
          _consultations = chatableConsultations;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading consultations: $e');
      if (mounted) {
        setState(() {
          _consultations = []; // Empty list
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadUnreadCounts(int userId) async {
    try {
      // Get total unread count for the user
      final totalUnreadCount = await ChatService.getUnreadCount(userId);
      
      // For now, just assigning the total count to the first consultation
      // In a real app, you'd have a more detailed API to get counts per consultation
      if (_consultations.isNotEmpty && mounted) {
        setState(() {
          _unreadCounts[_consultations[0].id] = totalUnreadCount;
        });
      }
    } catch (e) {
      debugPrint('Error loading unread counts: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Consultations'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
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
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _consultations.isEmpty
              ? _buildEmptyState()
              : _buildConsultationsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No active consultations',
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
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildConsultationsList() {
    return RefreshIndicator(
      onRefresh: () async {
        if (_userId != null && _userRole != null) {
          await _loadConsultations(_userId!, _userRole!);
          await _loadUnreadCounts(_userId!);
        } else {
          await _loadUserDataAndConsultations();
        }
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _consultations.length,
        itemBuilder: (context, index) {
          final consultation = _consultations[index];
          return _buildConsultationCard(consultation);
        },
      ),
    );
  }

  Widget _buildConsultationCard(Consultation consultation) {
    // Determine if current user is doctor or patient
    final bool isDoctor = _userRole == 'doctor';
    
    // Get the name of the other person in the conversation
    final String otherPersonName = isDoctor 
        ? consultation.patientName ?? 'Patient'
        : consultation.doctorName ?? 'Doctor';
    
    // Get subtitle text
    final String subtitle = isDoctor
        ? 'Patient'
        : consultation.doctorSpecialty ?? 'Medical Professional';
    
    // Format date
    final String dateText = consultation.consultationDate != null
        ? DateFormat('MMM dd, yyyy').format(consultation.consultationDate!)
        : '';
    
    // Get unread count
    final int unreadCount = _unreadCounts[consultation.id] ?? 0;
    
    // Get icon based on consultation type
    IconData typeIcon;
    switch (consultation.type.toLowerCase()) {
      case 'video':
        typeIcon = Icons.videocam;
        break;
      case 'voice':
      case 'audio':
        typeIcon = Icons.phone;
        break;
      case 'text':
      default:
        typeIcon = Icons.chat_bubble_outline;
        break;
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Navigate to chat screen
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
            // Refresh unread counts when returning from chat
            if (_userId != null) {
              _loadUnreadCounts(_userId!);
            }
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 28,
                backgroundColor: _getConsultationTypeColor(consultation.type).withOpacity(0.2),
                child: Icon(
                  typeIcon,
                  color: _getConsultationTypeColor(consultation.type),
                ),
              ),
              const SizedBox(width: 16),
              
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      otherPersonName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getConsultationTypeColor(consultation.type).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                typeIcon,
                                color: _getConsultationTypeColor(consultation.type),
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _getConsultationTypeText(consultation.type),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _getConsultationTypeColor(consultation.type),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (dateText.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              dateText,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              
              // Unread count badge and chevron
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (unreadCount > 0)
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Icon(
                    Icons.chevron_right,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ],
          ),
        ),
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
        return Colors.green;
      case 'text':
      default:
        return Colors.purple;
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