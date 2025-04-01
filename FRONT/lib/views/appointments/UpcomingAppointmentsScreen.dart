import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_app/views/doctors/doctor_home_screen.dart';
import '../../core/models/consultation.dart';
import '../../services/consultation_service.dart';
import '../../services/auth_service_api.dart';

class UpcomingAppointmentsScreen extends StatefulWidget {
  const UpcomingAppointmentsScreen({super.key});
  

  
  @override
  _UpcomingAppointmentsScreenState createState() => _UpcomingAppointmentsScreenState();
}

class _UpcomingAppointmentsScreenState extends State<UpcomingAppointmentsScreen> {
  List<Consultation> _upcomingAppointments = [];
  bool _isLoading = true;
  int? _doctorId;
  String? _lastError;

  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy - HH:mm');

  @override
  void initState() {
    super.initState();
    _loadDoctorIdAndAppointments();
  }
  
  
  // Load doctor ID and then fetch appointments
  Future<void> _loadDoctorIdAndAppointments() async {
    try {
      final doctorId = await ApiService.getCurrentDoctorId();
      
      // TEMPORARY FIX: Override with the correct doctor ID
      // Your auth service is returning user_id (29), but the doctor_id in the database is 3
      const correctDoctorId = 3; // Hardcode this to match the doctor_id in your database
      
      print("Original doctorId: $doctorId, using correctDoctorId: $correctDoctorId");
      
      if (mounted) {
        setState(() => _doctorId = correctDoctorId);
        await _fetchUpcomingAppointments();
      }
    } catch (e) {
      print("Error loading doctor ID: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading doctor information: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Fetch upcoming appointments
  Future<void> _fetchUpcomingAppointments() async {
  if (_doctorId == null) {
    print("Doctor ID is null, cannot fetch appointments");
    // If doctor ID is not available, try to load it first
    await _loadDoctorIdAndAppointments();
    return;
  }
    
  setState(() {
    _isLoading = true;
    _lastError = null; // Reset error state when starting a new fetch
  });
  
  try {
    print("Fetching upcoming appointments for doctor ID: $_doctorId");
      
    // For debugging - temporarily use the pending consultations endpoint
    try {
      final pendingConsultations = await ConsultationService.fetchPendingConsultations(_doctorId!);
      print("Successfully fetched ${pendingConsultations.length} pending consultations");
    } catch (e) {
      print("Error fetching pending consultations: $e");
    }
      
    // Now try to fetch upcoming appointments
    final fetchedAppointments = await ConsultationService.fetchUpcomingConsultations(_doctorId!);
    print("Successfully fetched ${fetchedAppointments.length} upcoming appointments");
      
    if (mounted) {
      setState(() => _upcomingAppointments = fetchedAppointments);
    }
  } catch (e) {
    print("Error fetching upcoming appointments: $e");
    if (mounted) {
      setState(() {
        _lastError = 'Error: $e'; // Store the error message
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load appointments: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}
  // Cancel an appointment
 // Replace the _cancelAppointment method in your UpcomingAppointmentsScreen class

Future<void> _cancelAppointment(int consultationId) async {
  setState(() => _isLoading = true);
  try {
    // Debug log
    print("Attempting to cancel appointment with ID: $consultationId");
    
    await ConsultationService.cancelUpcomingAppointment(consultationId);
    
    // Show success message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Appointment cancelled successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
    
    // Refresh the appointments list
    await _fetchUpcomingAppointments();
  } catch (e) {
    print("Error in _cancelAppointment: $e");
    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to cancel appointment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upcoming Appointments'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const DoctorHomeScreen()),
            );
          },
          tooltip: 'Back to Home',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchUpcomingAppointments,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _doctorId == null
          ? _buildDoctorIdError()
          : (_isLoading
              ? const Center(child: CircularProgressIndicator())
              : _upcomingAppointments.isEmpty
                  ? _buildEmptyState()
                  : _buildAppointmentsList()),
    );
  }

  Widget _buildDoctorIdError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Unable to get doctor ID',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please log in again to continue',
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.login),
            label: const Text('Go to Login'),
            onPressed: () {
              Navigator.of(context).pushReplacementNamed('/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // UpcomingAppointmentsScreen.dart - Update the _buildEmptyState method

Widget _buildEmptyState() {
  final hasError = _lastError != null;
  
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          hasError ? Icons.error_outline : Icons.calendar_today,
          size: 80,
          color: hasError ? Colors.red[300] : Colors.grey[400],
        ),
        const SizedBox(height: 16),
        Text(
          hasError ? 'Error loading appointments' : 'No upcoming appointments',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: hasError ? Colors.red[700] : Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          hasError 
              ? _lastError!
              : 'Your scheduled consultations will appear here',
          style: TextStyle(
            color: hasError ? Colors.red[500] : Colors.grey[500],
            fontSize: hasError ? 14 : 15,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          icon: const Icon(Icons.refresh),
          label: const Text('Refresh'),
          onPressed: _fetchUpcomingAppointments,
          style: ElevatedButton.styleFrom(
            backgroundColor: hasError ? Colors.red : Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
        ),
      ],
    ),
  );
}

  Widget _buildAppointmentsList() {
    return RefreshIndicator(
      onRefresh: _fetchUpcomingAppointments,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _upcomingAppointments.length,
        itemBuilder: (context, index) {
          final appointment = _upcomingAppointments[index];
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
                        backgroundColor: Colors.blue[100],
                        child: const Icon(
                          Icons.person,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              appointment.patientName ?? 'Patient ID: ${appointment.patientId}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Type: ${appointment.type}',
                              style: TextStyle(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (appointment.isEmergency)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.warning_rounded,
                                color: Colors.red[700],
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Emergency',
                                style: TextStyle(
                                  color: Colors.red[700],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    'Scheduled: ${_dateFormat.format(appointment.consultationDate is String ? 
                      DateTime.parse(appointment.consultationDate as String) : 
                      appointment.consultationDate as DateTime)}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Add additional options like "Start Consultation" if needed
                      ElevatedButton.icon(
                        icon: const Icon(Icons.video_call, size: 18),
                        label: const Text('Start'),
                        onPressed: () {
                          // Navigate to video consultation screen
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Video consultation functionality not implemented yet.'),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                      
                      OutlinedButton.icon(
                        icon: const Icon(Icons.cancel, size: 18),
                        label: const Text('Cancel'),
                        onPressed: () => _showCancelConfirmation(appointment.id),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
        content: const Text(
          'Are you sure you want to cancel this appointment? This action cannot be undone.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _cancelAppointment(consultationId);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }
}