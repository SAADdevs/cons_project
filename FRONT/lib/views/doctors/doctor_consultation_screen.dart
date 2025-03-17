import 'package:flutter/material.dart';
import '../../core/models/consultation.dart';
import '../../services/consultation_service.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service_api.dart'; // Import your auth service

class DoctorConsultationScreen extends StatefulWidget {
  const DoctorConsultationScreen({super.key});

  @override
  _DoctorConsultationScreenState createState() => _DoctorConsultationScreenState();
}

class _DoctorConsultationScreenState extends State<DoctorConsultationScreen> {
  List<Consultation> consultations = [];
  bool _isLoading = false;
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy - HH:mm');

  @override
  void initState() {
    super.initState();
    _fetchConsultations();
  }

  // Fetch pending consultations
  Future<void> _fetchConsultations() async {
    setState(() => _isLoading = true);
    try {
      // Get the doctor ID asynchronously
      final doctorId = await ApiService.getCurrentDoctorId();
      
      if (doctorId != null) {
        final fetchedConsultations = await ConsultationService.fetchPendingConsultations(doctorId);
        setState(() => consultations = fetchedConsultations);
      } else {
        // Handle the case where doctor ID is null
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to get doctor ID. Please log in again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load consultations: $e'),
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

  // Show date and time picker when accepting a consultation
  Future<void> _showDateTimePicker(int consultationId) async {
    // Pick date
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blue, // Header background color
              onPrimary: Colors.white, // Header text color
              onSurface: Colors.black, // Calendar text color
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (pickedDate == null) return; // User canceled date selection
    
    // Pick time
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blue, // Header background color
              onPrimary: Colors.white, // Header text color
              onSurface: Colors.black, // Dial text color
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (pickedTime == null) return; // User canceled time selection
    
    // Combine date and time
    final DateTime selectedDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
    
    // Update consultation with selected date
    _updateConsultationStatus(consultationId, 'accepted', selectedDateTime);
  }

  // Update consultation status
  Future<void> _updateConsultationStatus(
    int consultationId, 
    String status, 
    [DateTime? consultationDate]
  ) async {
    setState(() => _isLoading = true);
    try {
      await ConsultationService.updateConsultationStatus(
        consultationId: consultationId,
        status: status,
        consultationDate: consultationDate ?? DateTime.now(),
      );
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Consultation ${status == 'accepted' ? 'accepted' : 'rejected'} successfully'),
            backgroundColor: status == 'accepted' ? Colors.green : Colors.orange,
          ),
        );
      }
      
      // Refresh the list after updating
      await _fetchConsultations();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update consultation: $e'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Consultations'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
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
          : consultations.isEmpty
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
            Icons.calendar_today,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No pending consultations',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'New consultation requests will appear here',
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            onPressed: _fetchConsultations,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsultationsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: consultations.length,
      itemBuilder: (context, index) {
        final consultation = consultations[index];
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
                              consultation.patientName != null 
                                  ? '${consultation.patientName}'
                                  : 'Patient ID: ${consultation.patientId}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          const SizedBox(height: 4),
                          Text(
                            'Type: ${consultation.type}',
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (consultation.isEmergency)
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
                   'Created: ${_dateFormat.format(DateTime.parse(consultation.createdAt.toString()))}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.close),
                      label: const Text('Refuse'),
                      onPressed: () => _updateConsultationStatus(consultation.id, 'refused'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.check),
                      label: const Text('Accept'),
                      onPressed: () => _showDateTimePicker(consultation.id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}