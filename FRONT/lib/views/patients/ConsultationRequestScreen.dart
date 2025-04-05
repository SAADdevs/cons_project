import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_app/core/models/doctor_model.dart';
import 'package:my_app/services/DoctorService.dart';
import '../../core/utils/constants.dart';
import '../../services/consultation_service.dart';

enum ConsultationType {
  video,
  audio,
  chat
}

class ConsultationRequestScreen extends StatefulWidget {
  final Doctor doctor;

  const ConsultationRequestScreen({
    super.key, 
    required this.doctor
  });

  @override
  _ConsultationRequestScreenState createState() => _ConsultationRequestScreenState();
}

class _ConsultationRequestScreenState extends State<ConsultationRequestScreen> {
  // Consultation type
  ConsultationType _selectedType = ConsultationType.video;
  
  // Reason text controller
  final TextEditingController _reasonController = TextEditingController();
  
  // Is this an emergency consultation
  bool _isEmergency = false;
  
  // Selected date and time
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  // Consultation type labels
  final Map<ConsultationType, String> _consultationTypeLabels = {
    ConsultationType.video: 'Video Consultation',
    ConsultationType.audio: 'Audio Consultation',
    ConsultationType.chat: 'Chat Consultation'
  };

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Book Consultation',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Doctor Header
              _buildDoctorHeader(),

              // Consultation Type Selection
              _buildConsultationTypeSection(),

              // Emergency Consultation Option
              _buildEmergencySection(),

              // Date and Time Selection
              _buildDateTimeSelection(),

              // Consultation Reason
              _buildReasonSection(),

              // Submit Button
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitConsultationRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    'Request Consultation',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDoctorHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            child: Icon(
              Icons.person,
              color: AppColors.primary,
              size: 50,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.doctor.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.doctor.specialty,
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.verified,
                      color: widget.doctor.isVerified ? Colors.green : Colors.grey,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.doctor.isVerified ? 'Verified' : 'Not Verified',
                      style: TextStyle(
                        color: widget.doctor.isVerified ? Colors.green : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsultationTypeSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Consultation Type',
            style: TextStyle(
              fontSize: 16,
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
                    selected: _selectedType == type,
                    onSelected: (bool selected) {
                      setState(() {
                        _selectedType = type;
                      });
                    },
                    selectedColor: AppColors.primary.withOpacity(0.2),
                    backgroundColor: Colors.grey[200],
                    labelStyle: TextStyle(
                      color: _selectedType == type 
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

  Widget _buildEmergencySection() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
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

  Widget _buildDateTimeSelection() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Date and Time',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDatePickerButton(),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTimePickerButton(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDatePickerButton() {
    return ElevatedButton(
      onPressed: _pickDate,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey[100],
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            _selectedDate == null 
              ? 'Select Date' 
              : DateFormat('dd MMM yyyy').format(_selectedDate!),
            style: TextStyle(
              color: _selectedDate == null ? Colors.grey : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimePickerButton() {
    return ElevatedButton(
      onPressed: _pickTime,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey[100],
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.access_time, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            _selectedTime == null 
              ? 'Select Time' 
              : _selectedTime!.format(context),
            style: TextStyle(
              color: _selectedTime == null ? Colors.grey : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReasonSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Consultation Reason',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _reasonController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Describe your health concern...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  Future<void> _pickTime() async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime != null) {
      setState(() {
        _selectedTime = pickedTime;
      });
    }
  }

  void _submitConsultationRequest() async {
    // Validate inputs
    if (_selectedDate == null || _selectedTime == null) {
      _showValidationError('Please select date and time');
      return;
    }

    if (_reasonController.text.trim().isEmpty) {
      _showValidationError('Please provide a reason for consultation');
      return;
    }

    // Combine date and time
    final DateTime consultationDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    try {
      // TODO: Replace with actual patient ID from authentication
      const int patientId = 1; 

      // Request consultation
      final consultation = await ConsultationService.requestConsultation(
  patientId: patientId,
  doctorId: widget.doctor.id,
  type: _selectedType.name,
  isEmergency: _isEmergency,
  consultationDate: consultationDateTime,
  reason: _reasonController.text.trim(),
);

      // Show success dialog
      _showSuccessDialog(consultation);
    } catch (e) {
      // Show error dialog
      _showErrorDialog(e.toString());
    }
  }

  void _showValidationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
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