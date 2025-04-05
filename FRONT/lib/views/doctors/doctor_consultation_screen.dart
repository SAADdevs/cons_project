// import 'package:flutter/material.dart';
// import 'package:my_app/views/doctors/doctor_home_screen.dart';
// import '../../core/models/consultation.dart';
// import '../../services/consultation_service.dart';
// import 'package:intl/intl.dart';
// import '../../services/auth_service_api.dart'; // Import your auth service

// class DoctorConsultationScreen extends StatefulWidget {
//   const DoctorConsultationScreen({super.key});

//   @override
//   _DoctorConsultationScreenState createState() => _DoctorConsultationScreenState();
// }

// class _DoctorConsultationScreenState extends State<DoctorConsultationScreen> {
//   List<Consultation> consultations = [];
//   bool _isLoading = false;
//   int? _doctorId;
//   final DateFormat _dateFormat = DateFormat('MMM dd, yyyy - HH:mm');

//   @override
//   void initState() {
//     super.initState();
//     _loadDoctorIdAndConsultations();
//   }
  
//   // Load doctor ID and then fetch consultations
//   Future<void> _loadDoctorIdAndConsultations() async {
//     try {
//       final doctorId = await ApiService.getCurrentDoctorId();
//       if (mounted) {
//         setState(() => _doctorId = doctorId);
//         await _fetchConsultations();
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Error loading doctor information: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }

//   // Fetch pending consultations
//   Future<void> _fetchConsultations() async {
//     if (_doctorId == null) {
//       // If doctor ID is not available, try to load it first
//       await _loadDoctorIdAndConsultations();
//       return;
//     }
    
//     setState(() => _isLoading = true);
//     try {
//       final fetchedConsultations = await ConsultationService.fetchPendingConsultations(_doctorId!);
//       if (mounted) {
//         setState(() => consultations = fetchedConsultations);
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Failed to load consultations: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() => _isLoading = false);
//       }
//     }
//   }

//   // Safe date formatting helper
//   String _formatDate(dynamic dateValue) {
//     try {
//       if (dateValue == null) {
//         return 'Date not available';
//       }
      
//       DateTime? dateTime;
//       if (dateValue is DateTime) {
//         dateTime = dateValue;
//       } else if (dateValue is String) {
//         dateTime = DateTime.parse(dateValue);
//       }
      
//       if (dateTime != null) {
//         return _dateFormat.format(dateTime);
//       } else {
//         return 'Invalid date format';
//       }
//     } catch (e) {
//       print('Error formatting date: $e');
//       return 'Date format error';
//     }
//   }

//   // Show date and time picker when accepting a consultation
//   Future<void> _showDateTimePicker(int consultationId) async {
//     // Pick date
//     final DateTime? pickedDate = await showDatePicker(
//       context: context,
//       initialDate: DateTime.now(),
//       firstDate: DateTime.now(),
//       lastDate: DateTime.now().add(const Duration(days: 30)),
//       builder: (context, child) {
//         return Theme(
//           data: Theme.of(context).copyWith(
//             colorScheme: const ColorScheme.light(
//               primary: Colors.blue, // Header background color
//               onPrimary: Colors.white, // Header text color
//               onSurface: Colors.black, // Calendar text color
//             ),
//           ),
//           child: child!,
//         );
//       },
//     );
    
//     if (pickedDate == null) return; // User canceled date selection
    
//     // Pick time
//     final TimeOfDay? pickedTime = await showTimePicker(
//       context: context,
//       initialTime: TimeOfDay.now(),
//       builder: (context, child) {
//         return Theme(
//           data: Theme.of(context).copyWith(
//             colorScheme: const ColorScheme.light(
//               primary: Colors.blue, // Header background color
//               onPrimary: Colors.white, // Header text color
//               onSurface: Colors.black, // Dial text color
//             ),
//           ),
//           child: child!,
//         );
//       },
//     );
    
//     if (pickedTime == null) return; // User canceled time selection
    
//     // Combine date and time
//     final DateTime selectedDateTime = DateTime(
//       pickedDate.year,
//       pickedDate.month,
//       pickedDate.day,
//       pickedTime.hour,
//       pickedTime.minute,
//     );
    
//     // Update consultation with selected date
//     _updateConsultationStatus(consultationId, 'accepted', selectedDateTime);
//   }

//   // Update consultation status
//   Future<void> _updateConsultationStatus(
//     int consultationId, 
//     String status, 
//     [DateTime? consultationDate]
//   ) async {
//     setState(() => _isLoading = true);
//     try {
//       await ConsultationService.updateConsultationStatus(
//         consultationId: consultationId,
//         status: status,
//         consultationDate: consultationDate ?? DateTime.now(),
//       );
      
//       // Show success message
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Consultation ${status == 'accepted' ? 'accepted' : 'rejected'} successfully'),
//             backgroundColor: status == 'accepted' ? Colors.green : Colors.orange,
//           ),
//         );
//       }
      
//       // Refresh the list after updating
//       await _fetchConsultations();
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Failed to update consultation: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() => _isLoading = false);
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Pending Consultations'),
//         backgroundColor: Colors.blue,
//         foregroundColor: Colors.white,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back),
//           onPressed: () {
//             Navigator.pushReplacement(
//               context,
//               MaterialPageRoute(builder: (context) => const DoctorHomeScreen()),
//             );
//           },
//           tooltip: 'Back to Home',
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: _fetchConsultations,
//             tooltip: 'Refresh',
//           ),
//         ],
//       ),
//       body: _doctorId == null
//           ? _buildDoctorIdError()
//           : (_isLoading
//               ? const Center(child: CircularProgressIndicator())
//               : consultations.isEmpty
//                   ? _buildEmptyState()
//                   : _buildConsultationsList()),
//     );
//   }

//   Widget _buildDoctorIdError() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             Icons.error_outline,
//             size: 80,
//             color: Colors.red[400],
//           ),
//           const SizedBox(height: 16),
//           Text(
//             'Unable to get doctor ID',
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//               color: Colors.grey[600],
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'Please log in again to continue',
//             style: TextStyle(
//               color: Colors.grey[500],
//             ),
//           ),
//           const SizedBox(height: 24),
//           ElevatedButton.icon(
//             icon: const Icon(Icons.login),
//             label: const Text('Go to Login'),
//             onPressed: () {
//               Navigator.of(context).pushReplacementNamed('/login');
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.blue,
//               foregroundColor: Colors.white,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildEmptyState() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             Icons.calendar_today,
//             size: 80,
//             color: Colors.grey[400],
//           ),
//           const SizedBox(height: 16),
//           Text(
//             'No pending consultations',
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//               color: Colors.grey[600],
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'New consultation requests will appear here',
//             style: TextStyle(
//               color: Colors.grey[500],
//             ),
//           ),
//           const SizedBox(height: 24),
//           ElevatedButton.icon(
//             icon: const Icon(Icons.refresh),
//             label: const Text('Refresh'),
//             onPressed: _fetchConsultations,
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.blue,
//               foregroundColor: Colors.white,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildConsultationsList() {
//     return ListView.builder(
//       padding: const EdgeInsets.all(12),
//       itemCount: consultations.length,
//       itemBuilder: (context, index) {
//         final consultation = consultations[index];
//         return Card(
//           margin: const EdgeInsets.only(bottom: 16),
//           elevation: 2,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12),
//           ),
//           child: Padding(
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     CircleAvatar(
//                       backgroundColor: Colors.blue[100],
//                       child: const Icon(
//                         Icons.person,
//                         color: Colors.blue,
//                       ),
//                     ),
//                     const SizedBox(width: 12),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             consultation.patientName ?? 'Patient ID: ${consultation.patientId}',
//                             style: const TextStyle(
//                               fontWeight: FontWeight.bold,
//                               fontSize: 16,
//                             ),
//                           ),
//                           const SizedBox(height: 4),
//                           Text(
//                             'Type: ${consultation.type}',
//                             style: TextStyle(
//                               color: Colors.grey[600],
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     if (consultation.isEmergency)
//                       Container(
//                         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                         decoration: BoxDecoration(
//                           color: Colors.red[100],
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         child: Row(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             Icon(
//                               Icons.warning_rounded,
//                               color: Colors.red[700],
//                               size: 16,
//                             ),
//                             const SizedBox(width: 4),
//                             Text(
//                               'Emergency',
//                               style: TextStyle(
//                                 color: Colors.red[700],
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: 12,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                   ],
//                 ),
//                 const SizedBox(height: 16),
//                 const Divider(),
//                 const SizedBox(height: 8),
//                 Text(
//                   'Created: ${_formatDate(consultation.createdAt)}',
//                   style: TextStyle(
//                     color: Colors.grey[600],
//                     fontSize: 14,
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.end,
//                   children: [
//                     OutlinedButton.icon(
//                       icon: const Icon(Icons.close),
//                       label: const Text('Refuse'),
//                       onPressed: () => _updateConsultationStatus(consultation.id, 'rejected'),
//                       style: OutlinedButton.styleFrom(
//                         foregroundColor: Colors.red,
//                         side: const BorderSide(color: Colors.red),
//                       ),
//                     ),
//                     const SizedBox(width: 12),
//                     ElevatedButton.icon(
//                       icon: const Icon(Icons.check),
//                       label: const Text('Accept'),
//                       onPressed: () => _showDateTimePicker(consultation.id),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.green,
//                         foregroundColor: Colors.white,
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:my_app/views/doctors/doctor_home_screen.dart';
import '../../core/models/consultation.dart';
import '../../services/consultation_service.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service_api.dart';
import '../../widgets/DoctorHomeWidgets.dart';

class DoctorConsultationScreen extends StatefulWidget {
  const DoctorConsultationScreen({super.key});

  @override
  _DoctorConsultationScreenState createState() => _DoctorConsultationScreenState();
}

class _DoctorConsultationScreenState extends State<DoctorConsultationScreen> {
  List<Consultation> consultations = [];
  bool _isLoading = false;
  int? _doctorId;
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy - HH:mm');

  @override
  void initState() {
    super.initState();
    _loadDoctorIdAndConsultations();
  }
  
  // Load doctor ID and then fetch consultations
  Future<void> _loadDoctorIdAndConsultations() async {
    try {
      final doctorId = await ApiService.getCurrentDoctorId();
      if (mounted) {
        setState(() => _doctorId = doctorId);
        await _fetchConsultations();
      }
    } catch (e) {
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

  // Fetch pending consultations
  Future<void> _fetchConsultations() async {
    if (_doctorId == null) {
      // If doctor ID is not available, try to load it first
      await _loadDoctorIdAndConsultations();
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      final fetchedConsultations = await ConsultationService.fetchPendingConsultations(_doctorId!);
      if (mounted) {
        setState(() => consultations = fetchedConsultations);
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

  // Safe date formatting helper
  String _formatDate(dynamic dateValue) {
    try {
      if (dateValue == null) {
        return 'Date not available';
      }
      
      DateTime? dateTime;
      if (dateValue is DateTime) {
        dateTime = dateValue;
      } else if (dateValue is String) {
        dateTime = DateTime.parse(dateValue);
      }
      
      if (dateTime != null) {
        return _dateFormat.format(dateTime);
      } else {
        return 'Invalid date format';
      }
    } catch (e) {
      print('Error formatting date: $e');
      return 'Date format error';
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
            colorScheme: ColorScheme.light(
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
            colorScheme: ColorScheme.light(
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
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
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
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
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
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 150.0,
            floating: false,
            pinned: true,
            backgroundColor: Colors.blue,
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
                onPressed: _fetchConsultations,
                tooltip: 'Refresh',
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              title: const Text(
                'Pending Consultations',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: DoctorHomeWidgets.buildAppBarBackground(),
            ),
          ),
          SliverToBoxAdapter(
            child: _doctorId == null
                ? _buildDoctorIdError()
                : (_isLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : consultations.isEmpty
                        ? _buildEmptyState()
                        : _buildConsultationsList()),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorIdError() {
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
              child: Icon(
                Icons.error_outline,
                size: 60,
                color: Colors.red[400],
              ),
            ),
            const SizedBox(height: 24),
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

  Widget _buildEmptyState() {
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
                Icons.calendar_today,
                size: 60,
                color: Colors.blue[300],
              ),
            ),
            const SizedBox(height: 24),
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
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              onPressed: _fetchConsultations,
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

  Widget _buildConsultationsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
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
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Colors.blue,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            consultation.patientName ?? 'Patient ID: ${consultation.patientId}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getConsultationTypeColor(consultation.type).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _getConsultationTypeIcon(consultation.type),
                                      color: _getConsultationTypeColor(consultation.type),
                                      size: 12,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      consultation.type.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: _getConsultationTypeColor(consultation.type),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (consultation.patientAge != null || consultation.patientGender != null)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: Text(
                                    _buildPatientDetails(consultation.patientAge, consultation.patientGender),
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (consultation.isEmergency)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.warning_rounded,
                              color: Colors.red,
                              size: 14,
                            ),
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
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      'Created: ${_formatDate(consultation.createdAt)}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                if (consultation.patientGender != null && consultation.patientAge != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      children: [
                        const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          '${consultation.patientGender}, ${consultation.patientAge} years old',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => _updateConsultationStatus(consultation.id, 'rejected'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.close, size: 16),
                          SizedBox(width: 8),
                          Text('Refuse'),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () => _showDateTimePicker(consultation.id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.check, size: 16),
                          SizedBox(width: 8),
                          Text('Accept'),
                        ],
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

  String _buildPatientDetails(int? age, String? gender) {
    List<String> details = [];
    if (age != null) details.add('$age y.o.');
    if (gender != null) details.add(gender);
    return details.join(', ');
  }

  Color _getConsultationTypeColor(String type) {
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

  IconData _getConsultationTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'video':
        return Icons.videocam;
      case 'voice':
        return Icons.phone;
      case 'text':
        return Icons.chat;
      default:
        return Icons.help_outline;
    }
  }
}