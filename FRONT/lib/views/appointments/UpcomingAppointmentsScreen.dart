import 'package:flutter/material.dart';
import 'package:my_app/core/models/consultation.dart';
import 'package:my_app/core/utils/constants.dart';
import 'package:my_app/services/auth_service_api.dart';
import 'package:my_app/services/consultation_service.dart';
import 'dart:developer' as developer;

class UpcomingAppointmentsScreen extends StatefulWidget {
  const UpcomingAppointmentsScreen({Key? key}) : super(key: key);

  @override
  _UpcomingAppointmentsScreenState createState() => _UpcomingAppointmentsScreenState();
}

class _UpcomingAppointmentsScreenState extends State<UpcomingAppointmentsScreen> {
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  List<Consultation> _appointments = [];
  int? _doctorId;
  int? _userId;

  @override
  void initState() {
    super.initState();
    _loadDoctorId();
  }

  Future<void> _loadDoctorId() async {
    try {
      developer.log('Starting to load doctor ID', 
        name: 'UpcomingAppointmentsScreen',
        error: 'Initiating doctor ID retrieval'
      );

      final userId = await ApiService.getCurrentUserId();
      developer.log('Retrieved User ID', 
        name: 'UpcomingAppointmentsScreen',
        error: 'User ID: $userId'
      );
      
      if (userId == null) {
        developer.log('User ID is null', 
          name: 'UpcomingAppointmentsScreen',
          error: 'Failed to retrieve user ID'
        );
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Unable to get current user ID';
        });
        return;
      }
      
      _userId = userId;
      
      final doctorId = await ApiService.getCurrentDoctorId();
      developer.log('Retrieved Doctor ID', 
        name: 'UpcomingAppointmentsScreen',
        error: 'Doctor ID: $doctorId'
      );
      
      if (doctorId == null) {
        developer.log('Doctor ID is null', 
          name: 'UpcomingAppointmentsScreen',
          error: 'Failed to retrieve doctor ID for user $userId'
        );
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Doctor information not found';
        });
        return;
      }
      
      setState(() {
        _doctorId = doctorId;
      });
      
      await _loadAppointments();
    } catch (e) {
      developer.log('Error in _loadDoctorId', 
        name: 'UpcomingAppointmentsScreen',
        error: e.toString()
      );
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Failed to load doctor information: $e';
      });
    }
  }

  Future<void> _loadAppointments() async {
    if (_doctorId == null) {
      developer.log('Doctor ID is null, cannot load appointments', 
        name: 'UpcomingAppointmentsScreen',
        error: 'Attempted to load appointments with null doctor ID'
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    
    try {
      developer.log('Fetching appointments', 
        name: 'UpcomingAppointmentsScreen',
        error: 'Attempting to fetch appointments for Doctor ID: $_doctorId'
      );

      final appointments = await ConsultationService.fetchUpcomingConsultations(_doctorId!);
      
      developer.log('Appointments fetched', 
        name: 'UpcomingAppointmentsScreen',
        error: 'Fetched ${appointments.length} appointments'
      );

      setState(() {
        _appointments = appointments;
        _isLoading = false;
      });

      if (appointments.isEmpty) {
        developer.log('No appointments found', 
          name: 'UpcomingAppointmentsScreen',
          error: 'Zero appointments retrieved for Doctor ID: $_doctorId'
        );
      }
    } catch (e) {
      developer.log('Error fetching appointments', 
        name: 'UpcomingAppointmentsScreen',
        error: e.toString()
      );
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Error fetching upcoming consultations: $e';
      });
    }
  }

  Future<void> _cancelAppointment(int consultationId) async {
    try {
      await ConsultationService.cancelUpcomingAppointment(consultationId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment cancelled successfully')),
      );
      _loadAppointments();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cancelling appointment: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upcoming Appointments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAppointments,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
              ? _buildErrorView()
              : _appointments.isEmpty
                  ? _buildEmptyView()
                  : _buildAppointmentsList(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red[300], size: 60),
            const SizedBox(height: 16),
            Text(
              'Error loading appointments',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              style: TextStyle(color: Colors.red[700]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Diagnostic Info:\nUser ID: $_userId\nDoctor ID: $_doctorId',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadAppointments,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'No upcoming appointments',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your scheduled appointments will appear here',
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadAppointments,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentsList() {
    return RefreshIndicator(
      onRefresh: _loadAppointments,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _appointments.length,
        itemBuilder: (context, index) {
          final appointment = _appointments[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppColors.primary.withOpacity(0.2),
                              child: Text(
                                appointment.patientName?.isNotEmpty == true
                                    ? appointment.patientName![0]
                                    : 'P',
                                style: const TextStyle(color: AppColors.primary),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    appointment.patientName ?? 'Patient',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (appointment.patientAge != null && appointment.patientGender != null)
                                    Text(
                                      '${appointment.patientAge} years, ${appointment.patientGender}',
                                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getTypeColor(appointment.type).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          appointment.type.toUpperCase(),
                          style: TextStyle(
                            color: _getTypeColor(appointment.type),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Icon(Icons.event, color: Colors.grey[600], size: 18),
                      const SizedBox(width: 8),
                      Text(
                        appointment.consultationDate != null
                            ? _formatDate(appointment.consultationDate!)
                            : 'Date not set',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  if (appointment.isEmergency)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 16),
                          const SizedBox(width: 4),
                          const Text(
                            'EMERGENCY',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  const SizedBox(height: 16),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(
                                consultationId: appointment.id,
                                patientName: appointment.patientName ?? 'Patient',
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.chat_bubble_outline, size: 18),
                        label: const Text('Message'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      
                      OutlinedButton.icon(
                        onPressed: () => _showCancelConfirmation(appointment.id),
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Cancel'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showCancelConfirmation(int consultationId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: const Text('Are you sure you want to cancel this appointment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelAppointment(consultationId);
            },
            child: const Text('Yes', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = _getDayName(date.weekday);
    final month = _getMonthName(date.month);
    final dayOfMonth = date.day;
    final year = date.year;
    final hour = date.hour > 12 ? date.hour - 12 : date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    
    return '$day, $month $dayOfMonth, $year at $hour:$minute $period';
  }

  String _getDayName(int day) {
    switch (day) {
      case 1: return 'Monday';
      case 2: return 'Tuesday';
      case 3: return 'Wednesday';
      case 4: return 'Thursday';
      case 5: return 'Friday';
      case 6: return 'Saturday';
      case 7: return 'Sunday';
      default: return '';
    }
  }

  String _getMonthName(int month) {
    switch (month) {
      case 1: return 'January';
      case 2: return 'February';
      case 3: return 'March';
      case 4: return 'April';
      case 5: return 'May';
      case 6: return 'June';
      case 7: return 'July';
      case 8: return 'August';
      case 9: return 'September';
      case 10: return 'October';
      case 11: return 'November';
      case 12: return 'December';
      default: return '';
    }
  }

  Color _getTypeColor(String type) {
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
}

class ChatScreen extends StatelessWidget {
  final int consultationId;
  final String patientName;
  
  const ChatScreen({
    Key? key,
    required this.consultationId,
    required this.patientName,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(patientName),
      ),
      body: const Center(
        child: Text('Chat will be implemented here'),
      ),
    );
  }
}