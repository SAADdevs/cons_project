import 'package:flutter/material.dart';
import 'package:my_app/services/doctor_service.dart';
import '../../core/utils/constants.dart';
import '../../core/models/doctor_model.dart';
import '../../services/consultation_service.dart';

enum ConsultationType {
  video,
  audio,
  chat
}

class DoctorDetailsScreen extends StatefulWidget {
  final Doctor doctor;

  const DoctorDetailsScreen({super.key, required this.doctor});

  @override
  _DoctorDetailsScreenState createState() => _DoctorDetailsScreenState();
}

class _DoctorDetailsScreenState extends State<DoctorDetailsScreen> {
  // Consultation type selection
  ConsultationType _selectedConsultationType = ConsultationType.video;
  bool _isEmergency = false;

  // Consultation type mapping
  final Map<ConsultationType, String> _consultationTypeLabels = {
    ConsultationType.video: 'Video Consultation',
    ConsultationType.audio: 'Audio Consultation',
    ConsultationType.chat: 'Chat Consultation'
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.doctor.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: _buildDoctorHeader(),
            ),
          ),

          // Rest of the implementation remains the same as in the previous submission
          SliverList(
            delegate: SliverChildListDelegate([
              // Doctor Info Section
              _buildDoctorInfoSection(),

              // Consultation Type Selection
              _buildConsultationTypeSection(),

              // Emergency Consultation Option
              _buildEmergencyConsultationSection(),

              // Book Consultation Button
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: _bookConsultation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    'Book Consultation',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorHeader() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, Colors.blue.shade700],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),

        // Doctor Avatar and Details
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Doctor Avatar
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 4),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      size: 60,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Doctor Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.doctor.specialty,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.verified,
                          color: widget.doctor.isVerified 
                              ? Colors.green 
                              : Colors.grey,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.doctor.isVerified 
                              ? 'Verified Doctor' 
                              : 'Not Verified',
                          style: TextStyle(
                            color: widget.doctor.isVerified 
                                ? Colors.green 
                                : Colors.white70,
                            fontWeight: FontWeight.bold,
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
      ],
    );
  }

  Widget _buildDoctorInfoSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About Doctor',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoCard(
                icon: Icons.work,
                title: 'Experience',
                subtitle: '5+ Years',
              ),
              _buildInfoCard(
                icon: Icons.people,
                title: 'Patients',
                subtitle: '1200+',
              ),
              _buildInfoCard(
                icon: Icons.star,
                title: 'Rating',
                subtitle: '4.8',
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Professional Summary',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'A highly skilled ${widget.doctor.specialty} specialist with extensive experience in providing comprehensive medical care. Committed to patient-centered approach and cutting-edge medical treatments.',
            style: TextStyle(
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: AppColors.primary,
            size: 30,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsultationTypeSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Consultation Type',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ConsultationType.values.map((type) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: ChoiceChip(
                    label: Text(_consultationTypeLabels[type]!),
                    selected: _selectedConsultationType == type,
                    onSelected: (bool selected) {
                      setState(() {
                        _selectedConsultationType = type;
                      });
                    },
                    selectedColor: AppColors.primary.withOpacity(0.2),
                    backgroundColor: Colors.grey[200],
                    labelStyle: TextStyle(
                      color: _selectedConsultationType == type 
                          ? AppColors.primary 
                          : Colors.grey[700],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyConsultationSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Text(
            'Emergency Consultation',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Switch(
            value: _isEmergency,
            onChanged: (bool value) {
              setState(() {
                _isEmergency = value;
              });
            },
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  void _bookConsultation() async {
    // Validate doctor availability
    if (!widget.doctor.isAvailable) {
      _showUnavailableDialog();
      return;
    }

    try {
      // TODO: Replace with actual patient ID from authentication
      const int patientId = 1; 

      // Prepare consultation details
      final consultation = await ConsultationService.requestConsultation(
        patientId: patientId,
        doctorId: widget.doctor.id,
        type: _selectedConsultationType.name,
        isEmergency: _isEmergency,
      );

      // Show success dialog
      _showSuccessDialog(consultation);
    } catch (e) {
      // Show error dialog
      _showErrorDialog(e.toString());
    }
  }

  void _showUnavailableDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Doctor Unavailable'),
        content: const Text('This doctor is currently not available for consultations.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(dynamic consultation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Consultation Requested'),
        content: const Text('Your consultation request has been sent successfully.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String errorMessage) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Consultation Error'),
        content: Text(errorMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}