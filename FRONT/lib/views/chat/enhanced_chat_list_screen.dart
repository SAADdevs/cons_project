// // lib/views/chat/enhanced_chat_list_screen.dart
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import '../../core/models/consultation.dart';
// import '../../services/consultation_service.dart';
// import '../../services/auth_service_api.dart';
// import '../../core/utils/constants.dart';
// import 'enhanced_chat_screen.dart';

// class EnhancedChatListScreen extends StatefulWidget {
//   const EnhancedChatListScreen({Key? key}) : super(key: key);

//   @override
//   _EnhancedChatListScreenState createState() => _EnhancedChatListScreenState();
// }

// class _EnhancedChatListScreenState extends State<EnhancedChatListScreen> {
//   bool _isLoading = true;
//   List<Consultation> _consultations = [];
//   int? _userId;
//   String? _userRole;

//   @override
//   void initState() {
//     super.initState();
//     _loadUserDataAndConsultations();
//   }

//   Future<void> _loadUserDataAndConsultations() async {
//     try {
//       // Get current user info
//       setState(() => _isLoading = true);
      
//       final userId = await ApiService.getCurrentUserId();
//       final userRole = await ApiService.getUserRole();
      
//       setState(() {
//         _userId = userId;
//         _userRole = userRole;
//       });
      
//       if (userId == null) {
//         throw Exception('User not authenticated');
//       }
      
//       await _loadConsultations(userId, userRole ?? '');
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error: $e')),
//         );
//         setState(() => _isLoading = false);
//       }
//     }
//   }

//  Future<void> _loadConsultations(int userId, String role) async {
//   try {
//     List<Consultation> consultations = [];
    
//     if (role == 'patient') {
//       // Get patient consultations
//       consultations = await ConsultationService.getPatientConsultations(userId);
//     } else if (role == 'doctor') {
//       try {
//         // Get doctor's consultation requests
//         final pendingConsultations = await ConsultationService.fetchPendingConsultations(userId);
//         consultations.addAll(pendingConsultations);
//       } catch (e) {
//         print('Error fetching pending consultations: $e');
//         // Continue even if this fails
//       }
      
//       try {
//         // Get doctor's upcoming appointments
//         final upcomingConsultations = await ConsultationService.fetchUpcomingConsultations(userId);
//         consultations.addAll(upcomingConsultations);
//       } catch (e) {
//         print('Error fetching upcoming consultations: $e');
//         // Continue even if this fails
//       }
//     }
    
//     // Filter consultations to show only accepted or completed ones
//     final chatableConsultations = consultations.where((c) => 
//       c.status == 'accepted' || c.status == 'completed').toList();
    
//     if (mounted) {
//       setState(() {
//         _consultations = chatableConsultations;
//         _isLoading = false;
//       });
//     }
//   } catch (e) {
//     if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error loading consultations: $e')),
//       );
//       setState(() {
//         _consultations = []; // Empty list
//         _isLoading = false;
//       });
//     }
//   }
// }
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Chat Consultations'),
//         backgroundColor: AppColors.primary,
//         foregroundColor: Colors.white,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: () {
//               if (_userId != null && _userRole != null) {
//                 _loadConsultations(_userId!, _userRole!);
//               } else {
//                 _loadUserDataAndConsultations();
//               }
//             },
//             tooltip: 'Refresh',
//           ),
//         ],
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : _consultations.isEmpty
//               ? _buildEmptyState()
//               : _buildConsultationsList(),
//     );
//   }

//   Widget _buildEmptyState() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             Icons.chat_bubble_outline,
//             size: 80,
//             color: Colors.grey[400],
//           ),
//           const SizedBox(height: 16),
//           Text(
//             'No active consultations',
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//               color: Colors.grey[600],
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'Your accepted consultations will appear here',
//             style: TextStyle(
//               color: Colors.grey[500],
//             ),
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 24),
//           ElevatedButton(
//             onPressed: () {
//               if (_userId != null && _userRole != null) {
//                 _loadConsultations(_userId!, _userRole!);
//               } else {
//                 _loadUserDataAndConsultations();
//               }
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: AppColors.primary,
//               foregroundColor: Colors.white,
//             ),
//             child: const Text('Refresh'),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildConsultationsList() {
//     return ListView.builder(
//       itemCount: _consultations.length,
//       itemBuilder: (context, index) {
//         final consultation = _consultations[index];
//         return _buildConsultationCard(consultation);
//       },
//     );
//   }

//   Widget _buildConsultationCard(Consultation consultation) {
//     // Determine if current user is doctor or patient
//     final bool isDoctor = _userRole == 'doctor';
    
//     // Get the name of the other person in the conversation
//     final String otherPersonName = isDoctor 
//         ? consultation.patientName ?? 'Patient'
//         : consultation.doctorName ?? 'Doctor';
    
//     // Get specialty or other details to show
//     final String subtitle = isDoctor
//         ? 'Type: ${consultation.type}'
//         : consultation.doctorSpecialty ?? 'Medical Professional';
    
//     // Get the ID of the other person for the chat
//     final int? otherPersonId = isDoctor
//         ? consultation.patientId
//         : consultation.doctorId;
    
//     if (otherPersonId == null) {
//       return const SizedBox(); // Skip this consultation if we don't have the other person's ID
//     }
    
//     return Card(
//       margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       elevation: 2,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: ListTile(
//         contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//         leading: CircleAvatar(
//           backgroundColor: AppColors.primary.withOpacity(0.2),
//           child: Icon(
//             Icons.person,
//             color: AppColors.primary,
//           ),
//         ),
//         title: Text(
//           otherPersonName,
//           style: const TextStyle(
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         subtitle: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(subtitle),
//             const SizedBox(height: 4),
//             Text(
//               'Status: ${consultation.status}',
//               style: TextStyle(
//                 fontSize: 12,
//                 color: _getStatusColor(consultation.status),
//               ),
//             ),
//           ],
//         ),
//         trailing: Icon(Icons.chat_bubble_outline, color: AppColors.primary),
//         onTap: () {
//           // Navigate to the chat screen
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (context) => EnhancedChatScreen(
//                 consultationId: consultation.id,
//                 receiverName: otherPersonName,
//                 receiverSpecialty: subtitle,
//                 receiverId: otherPersonId,
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }

//   Color _getStatusColor(String status) {
//     switch (status) {
//       case 'pending':
//         return Colors.orange;
//       case 'accepted':
//         return Colors.green;
//       case 'completed':
//         return Colors.blue;
//       case 'rejected':
//         return Colors.red;
//       default:
//         return Colors.grey;
//     }
//   }
// }