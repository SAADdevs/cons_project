

import 'package:flutter/material.dart';
import 'package:my_app/core/models/consultation.dart';
import 'package:my_app/core/utils/constants.dart';
import 'package:my_app/services/auth_service_api.dart';
import 'package:my_app/services/consultation_service.dart';
import 'package:my_app/widgets/DoctorHomeWidgets.dart';
import 'dart:developer' as developer;

class UpcomingAppointmentsScreen extends StatefulWidget {
  final bool showAppBar;
  
  const UpcomingAppointmentsScreen({
    Key? key, 
    this.showAppBar = true
  }) : super(key: key);

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
        SnackBar(
          content: const Text('Appointment cancelled successfully'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      _loadAppointments();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error cancelling appointment: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          if (widget.showAppBar)
            SliverAppBar(
              expandedHeight: 150.0,
              floating: false,
              pinned: true,
              backgroundColor: Colors.blue,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                title: const Text(
                  'Upcoming Appointments',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                background: DoctorHomeWidgets.buildAppBarBackground(),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadAppointments,
                  tooltip: 'Refresh',
                ),
              ],
            ),
          SliverToBoxAdapter(
            child: _isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: CircularProgressIndicator(),
                    ))
                : _hasError
                    ? _buildErrorView()
                    : _appointments.isEmpty
                        ? _buildEmptyView()
                        : _buildAppointmentsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline, color: Colors.red[300], size: 60),
            ),
            const SizedBox(height: 24),
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
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.calendar_today_outlined,
                size: 60,
                color: Colors.blue[300],
              ),
            ),
            const SizedBox(height: 24),
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
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentsList() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Appointments: ${_appointments.length}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _appointments.length,
            itemBuilder: (context, index) {
              final appointment = _appointments[index];
              return _buildAppointmentCard(appointment);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(Consultation appointment) {
  return Container(
    margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.2),
          spreadRadius: 1,
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // Optional: Add navigation to appointment details
          // Navigator.push(context, MaterialPageRoute(...));
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row with Patient Name and Consultation Type
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      appointment.patientName ?? 'Unknown Patient',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _getConsultationTypeColor(appointment.type).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _formatConsultationType(appointment.type),
                      style: TextStyle(
                        color: _getConsultationTypeColor(appointment.type),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Patient Details
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person_outline, 
                      color: Colors.grey[600], 
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${appointment.patientAge ?? 'N/A'} years, ${appointment.patientGender ?? 'N/A'}',
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Consultation Date
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.calendar_today, 
                      color: Colors.blue[600], 
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _formatConsultationDate(appointment.consultationDate),
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Emergency and Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Emergency Badge
                  if (appointment.isEmergency)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning, color: Colors.red[600], size: 16),
                          const SizedBox(width: 4),
                          Text(
                            'Emergency Case',
                            style: TextStyle(
                              color: Colors.red[600],
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  // Cancel Button
                  ElevatedButton(
                    onPressed: () => _showCancelConfirmationDialog(appointment.id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.withOpacity(0.1),
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                      shadowColor: Colors.transparent,
                    ),
                    child: const Text(
                      'Cancel Appointment',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  // Helper method to show cancel confirmation dialog
  // Helper method to show cancel confirmation dialog
void _showCancelConfirmationDialog(int consultationId) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Cancel Appointment'),
        content: const Text('Are you sure you want to cancel this appointment?'),
        actions: [
          TextButton(
            child: const Text('No'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
            onPressed: () {
              Navigator.of(context).pop();
              _cancelAppointment(consultationId);
            },
          ),
        ],
      );
    },
  );
}

// Utility methods for formatting
String _formatConsultationDate(DateTime? date) {
  if (date == null) return 'Date not set';
  
  return '${date.day} ${_getMonthName(date.month)} ${date.year} '
         'at ${_formatTime(date)}';
}

String _getMonthName(int month) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return months[month - 1];
}

String _formatTime(DateTime date) {
  final hour = date.hour;
  final minute = date.minute;
  final period = hour >= 12 ? 'PM' : 'AM';
  final formattedHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
  final formattedMinute = minute.toString().padLeft(2, '0');
  
  return '$formattedHour:$formattedMinute $period';
}

Color _getConsultationTypeColor(String type) {
  switch (type.toLowerCase()) {
    case 'text':
      return Colors.blue;
    case 'voice':
      return Colors.green;
    case 'video':
      return Colors.purple;
    default:
      return Colors.grey;
  }
}

String _formatConsultationType(String type) {
  switch (type.toLowerCase()) {
    case 'text':
      return 'Text Chat';
    case 'voice':
      return 'Voice Call';
    case 'video':
      return 'Video Call';
    default:
      return type.toUpperCase();
  }
}}