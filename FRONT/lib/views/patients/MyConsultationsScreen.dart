import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/utils/constants.dart';
import '../../services/consultation_service.dart';
import '../../core/models/consultation.dart';
import 'package:my_app/services/auth_service_api.dart';

class MyConsultationsScreen extends StatefulWidget {
  const MyConsultationsScreen({super.key});

  @override
  _MyConsultationsScreenState createState() => _MyConsultationsScreenState();
}

class _MyConsultationsScreenState extends State<MyConsultationsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Consultation> _pendingConsultations = [];
  List<Consultation> _upcomingConsultations = [];
  List<Consultation> _pastConsultations = [];
  int? _patientId;
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy - HH:mm');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadPatientIdAndConsultations();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPatientIdAndConsultations() async {
    try {
      final userId = await ApiService.getCurrentUserId();
      // For demo purposes, use a fixed patientId if the API doesn't return one
      setState(() => _patientId = userId ?? 1);
      await _fetchConsultations();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading patient information: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _fetchConsultations() async {
    if (_patientId == null) {
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      // This would ideally come from your API service
      // Using mock data here as a placeholder
      final consultations = await _fetchMockConsultations();
      
      if (mounted) {
        setState(() {
          _pendingConsultations = consultations.where((c) => c.status == 'pending').toList();
          _upcomingConsultations = consultations.where((c) => c.status == 'accepted').toList();
          _pastConsultations = consultations.where((c) => c.status == 'completed' || c.status == 'rejected').toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load consultations: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  // Mock function for development - replace with actual API calls
  Future<List<Consultation>> _fetchMockConsultations() async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    
    return [
      Consultation(
        id: 1,
        patientId: _patientId!,
        patientName: "You",
        doctorId: 1,
        doctorName: "Dr. John Smith",
        doctorSpecialty: "Cardiology",
        type: "video",
        status: "pending",
        isEmergency: false,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Consultation(
        id: 2,
        patientId: _patientId!,
        patientName: "You",
        doctorId: 2,
        doctorName: "Dr. Maria Johnson",
        doctorSpecialty: "Dermatology",
        type: "audio",
        status: "accepted",
        consultationDate: DateTime.now().add(const Duration(days: 3)),
        isEmergency: false,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      Consultation(
        id: 3,
        patientId: _patientId!,
        patientName: "You",
        doctorId: 3,
        doctorName: "Dr. Robert Lee",
        doctorSpecialty: "Pediatrics",
        type: "video",
        status: "completed",
        consultationDate: DateTime.now().subtract(const Duration(days: 5)),
        isEmergency: true,
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
      ),
      Consultation(
        id: 4,
        patientId: _patientId!,
        patientName: "You",
        doctorId: 4,
        doctorName: "Dr. Sarah Williams",
        doctorSpecialty: "Neurology",
        type: "text",
        status: "rejected",
        isEmergency: false,
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Consultations'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Upcoming'),
            Tab(text: 'Past'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchConsultations,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildConsultationList(_pendingConsultations, 'pending'),
                _buildConsultationList(_upcomingConsultations, 'upcoming'),
                _buildConsultationList(_pastConsultations, 'past'),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/doctor-categories');
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
        tooltip: 'New Consultation',
      ),
    );
  }

  Widget _buildConsultationList(List<Consultation> consultations, String type) {
    if (consultations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getEmptyStateIcon(type),
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _getEmptyStateText(type),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getEmptyStateSubText(type),
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
      padding: const EdgeInsets.all(16),
      itemCount: consultations.length,
      itemBuilder: (context, index) {
        final consultation = consultations[index];
        return _buildConsultationCard(consultation, type);
      },
    );
  }

  Widget _buildConsultationCard(Consultation consultation, String type) {
    final Color statusColor = _getStatusColor(consultation.status);
    final String statusText = _getStatusText(consultation.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _getSpecialtyColor(consultation.doctorSpecialty).withOpacity(0.2),
                  child: Icon(
                    _getSpecialtyIcon(consultation.doctorSpecialty),
                    color: _getSpecialtyColor(consultation.doctorSpecialty),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        consultation.doctorName ?? 'Unknown Doctor',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        consultation.doctorSpecialty ?? 'Specialist',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildInfoChip(
                  icon: Icons.videocam,
                  label: _getConsultationTypeText(consultation.type),
                ),
                const SizedBox(width: 8),
                if (consultation.isEmergency)
                  _buildInfoChip(
                    icon: Icons.priority_high,
                    label: 'Emergency',
                    color: Colors.red,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (consultation.consultationDate != null)
              _buildInfoRow(
                icon: Icons.event,
                label: 'Scheduled:',
                value: _dateFormat.format(consultation.consultationDate!),
              ),
            _buildInfoRow(
              icon: Icons.access_time,
              label: 'Requested:',
              value: _dateFormat.format(consultation.createdAt ?? DateTime.now()),
            ),
            const SizedBox(height: 12),
            if (type == 'upcoming')
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.cancel),
                    label: const Text('Cancel'),
                    onPressed: () => _showCancelConfirmation(consultation.id),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.videocam),
                    label: const Text('Join'),
                    onPressed: () => _joinConsultation(consultation),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                  ),
                ],
              ),
            if (type == 'pending')
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.cancel),
                    label: const Text('Cancel Request'),
                    onPressed: () => _showCancelConfirmation(consultation.id),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ],
              ),
            if (type == 'past' && consultation.status == 'completed')
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.comment),
                    label: const Text('Leave Review'),
                    onPressed: () => _leaveReview(consultation),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (color ?? Colors.blue).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color ?? Colors.blue,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color ?? Colors.blue,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  IconData _getEmptyStateIcon(String type) {
    switch (type) {
      case 'pending':
        return Icons.hourglass_empty;
      case 'upcoming':
        return Icons.event_available;
      case 'past':
        return Icons.history;
      default:
        return Icons.medical_services_outlined;
    }
  }

  String _getEmptyStateText(String type) {
    switch (type) {
      case 'pending':
        return 'No Pending Requests';
      case 'upcoming':
        return 'No Upcoming Consultations';
      case 'past':
        return 'No Past Consultations';
      default:
        return 'No Consultations';
    }
  }

  String _getEmptyStateSubText(String type) {
    switch (type) {
      case 'pending':
        return 'Your consultation requests will appear here';
      case 'upcoming':
        return 'Your scheduled consultations will appear here';
      case 'past':
        return 'Your consultation history will appear here';
      default:
        return 'Start by requesting a consultation with a doctor';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'accepted':
        return 'Accepted';
      case 'completed':
        return 'Completed';
      case 'rejected':
        return 'Rejected';
      default:
        return 'Unknown';
    }
  }

  String _getConsultationTypeText(String type) {
    switch (type) {
      case 'video':
        return 'Video Call';
      case 'audio':
        return 'Audio Call';
      case 'text':
        return 'Text Chat';
      default:
        return 'Consultation';
    }
  }

  IconData _getSpecialtyIcon(String? specialty) {
    switch (specialty) {
      case 'Cardiology':
        return Icons.favorite;
      case 'Dermatology':
        return Icons.face;
      case 'Pediatrics':
        return Icons.child_care;
      case 'Neurology':
        return Icons.psychology;
      case 'Orthopedics':
        return Icons.accessibility;
      case 'Dentistry':
        return Icons.medical_services;
      case 'Ophthalmology':
        return Icons.remove_red_eye;
      case 'Psychiatry':
        return Icons.sentiment_satisfied;
      default:
        return Icons.local_hospital;
    }
  }

  Color _getSpecialtyColor(String? specialty) {
    switch (specialty) {
      case 'Cardiology':
        return Colors.red;
      case 'Dermatology':
        return Colors.orange;
      case 'Pediatrics':
        return Colors.blue;
      case 'Neurology':
        return Colors.green;
      case 'Orthopedics':
        return Colors.purple;
      case 'Dentistry':
        return Colors.teal;
      case 'Ophthalmology':
        return Colors.indigo;
      case 'Psychiatry':
        return Colors.amber;
      default:
        return Colors.blue;
    }
  }

  void _showCancelConfirmation(int consultationId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Consultation'),
        content: const Text('Are you sure you want to cancel this consultation? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implement actual cancellation logic
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Consultation cancelled')),
              );
              _fetchConsultations(); // Refresh the list
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  void _joinConsultation(Consultation consultation) {
    // Implement navigation to the consultation screen based on type
    final consultationType = consultation.type;
    String route;
    
    switch (consultationType) {
      case 'video':
        route = '/video-consultation';
        break;
      case 'audio':
        route = '/audio-consultation';
        break;
      case 'text':
        route = '/chat';
        break;
      default:
        route = '/chat';
    }
    
    // For now, simply show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Joining ${_getConsultationTypeText(consultationType)} consultation')),
    );
    
    // Navigation implementation would go here
    // Navigator.pushNamed(context, route, arguments: consultation);
  }

  void _leaveReview(Consultation consultation) {
    // Implement review dialogue
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Rate Dr. ${consultation.doctorName?.split(' ')[1] ?? ''}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('How was your consultation experience?'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < 4 ? Icons.star : Icons.star_border,
                    color: index < 4 ? Colors.amber : Colors.grey,
                    size: 30,
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Thank you for your ${index + 1}-star review!')),
                    );
                  },
                );
              }),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}