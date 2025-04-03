import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/models/consultation.dart';
import '../../services/consultation_service.dart';
import '../../services/auth_service_api.dart';
import '../../services/chat_service.dart';
import '../chat/chat_screen.dart';

class DoctorChatListScreen extends StatefulWidget {
  const DoctorChatListScreen({Key? key}) : super(key: key);

  @override
  _DoctorChatListScreenState createState() => _DoctorChatListScreenState();
}

class _DoctorChatListScreenState extends State<DoctorChatListScreen> {
  bool _isLoading = true;
  List<Consultation> _consultations = [];
  int? _doctorId;
  Map<int, int> _unreadCounts = {};

  @override
  void initState() {
    super.initState();
    _loadDoctorDataAndConsultations();
  }

  Future<void> _loadDoctorDataAndConsultations() async {
    try {
      setState(() => _isLoading = true);
      
      final doctorId = await ApiService.getCurrentDoctorId();
      
      if (doctorId == null) {
        throw Exception('Doctor not authenticated');
      }
      
      setState(() => _doctorId = doctorId);
      
      await _loadConsultations(doctorId);
      await _loadUnreadCounts(doctorId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadConsultations(int doctorId) async {
    try {
      // Get doctor's accepted or completed consultations
      final consultations = await ConsultationService.fetchUpcomingConsultations(doctorId);
      
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
          _consultations = [];
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadUnreadCounts(int doctorId) async {
    try {
      // Implement method to get unread counts for doctor
      final totalUnreadCount = await ChatService.getUnreadCount(doctorId);
      
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
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _doctorId != null 
              ? () => _loadDoctorDataAndConsultations() 
              : null,
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
        if (_doctorId != null) {
          await _loadDoctorDataAndConsultations();
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
    // Get patient name and details
    final String patientName = consultation.patientName ?? 'Patient';
    final int unreadCount = _unreadCounts[consultation.id] ?? 0;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                consultation: consultation,
                receiverName: patientName,
                isDoctor: true,
              ),
            ),
          ).then((_) {
            // Refresh unread counts when returning from chat
            if (_doctorId != null) {
              _loadUnreadCounts(_doctorId!);
            }
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.blue.withOpacity(0.2),
                child: const Icon(
                  Icons.person,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patientName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Consultation Type: ${consultation.type}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
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
            ],
          ),
        ),
      ),
    );
  }
}