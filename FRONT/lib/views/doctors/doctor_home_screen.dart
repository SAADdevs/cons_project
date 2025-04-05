// import 'package:flutter/material.dart';
// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:my_app/basrel.dart' show baseUrl;
// import 'package:my_app/views/appointments/UpcomingAppointmentsScreen.dart';
// import 'package:my_app/views/doctors/doctor_chat_list_screen.dart';
// import 'package:my_app/views/doctors/doctor_consultation_screen.dart';
// import 'package:my_app/views/chat/chat_list_screen.dart'; // Add this import
// import '../../basrel.dart';
// import '../../core/models/consultation.dart';
// import '../../services/auth_service_api.dart';
// import '../../services/consultation_service.dart';

// class DoctorHomeScreen extends StatefulWidget {
//   const DoctorHomeScreen({super.key});

//   @override
//   State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
// }

// class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
//   String doctorName = "Doctor";
//   int? doctorId;
//   bool isLoading = true;
//   bool isAvailable = true;
//   int pendingConsultations = 0;
//   int upcomingAppointments = 0;

//   @override
//   void initState() {
//     super.initState();
//     _loadDoctorInfo();
//   }

//   Future<void> _loadDoctorInfo() async {
//     setState(() => isLoading = true);
//     try {
//       // Get doctor ID from API service
//       doctorId = await ApiService.getCurrentDoctorId();
      
//       if (doctorId != null) {
//         // Get doctor profile from API
//         final token = await ApiService.getAuthToken();
//         if (token != null) {
//           final response = await http.get(
//             Uri.parse("$baseUrl/doctor"),
//             headers: {
//               "Content-Type": "application/json",
//               "Authorization": "Bearer $token"
//             },
//           );
          
//           if (response.statusCode == 200) {
//             final doctorData = jsonDecode(response.body);
//             setState(() {
//               doctorName = doctorData['full_name'] ?? "Doctor";
//               isAvailable = doctorData['is_available'] ?? true;
//             });
            
//             // Fetch consultations counts
//             await _fetchConsultationsCounts();
//           }
//         }
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
//     } finally {
//       if (mounted) {
//         setState(() => isLoading = false);
//       }
//     }

//   }  
//   Future<void> _fetchConsultationsCounts() async {
//     try {
//       if (doctorId != null) {
//         // Fetch pending consultations
//         final pendingConsultations = await ConsultationService.fetchPendingConsultations(doctorId!);
        
//         // Fetch upcoming appointments
//         final upcomingAppointments = await ConsultationService.fetchUpcomingConsultations(doctorId!);
        
//         setState(() {
//           this.pendingConsultations = pendingConsultations.length;
//           this.upcomingAppointments = upcomingAppointments.length;
//         });
        
//         print("Updated counts - Pending: ${pendingConsultations.length}, Upcoming: ${upcomingAppointments.length}");
//       }
//     } catch (e) {
//       print('Error fetching consultation counts: $e');
//       // Optionally show a snackbar to the user
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Error fetching consultations: $e'),
//             backgroundColor: Colors.orange,
//           ),
//         );
//       }
//     }
//   }

//   Future<void> _toggleAvailability() async {
//     if (doctorId == null) return;
    
//     try {
//       setState(() => isLoading = true);
      
//       // Get the token
//       final token = await ApiService.getAuthToken();
//       if (token == null) throw Exception('Authentication token not found');
      
//       // Print doctor ID and current availability for debugging
//       print("Doctor ID: $doctorId, Current availability: $isAvailable");
      
//       // Print the request URL and body for debugging

//       final url = "$baseUrl/doctors/update-availability";
//       final body = {
//         "doctor_id": doctorId,
//         "is_available": !isAvailable
//       };
//       print("Making request to: $url");
//       print("Request body: ${jsonEncode(body)}");
      
//       // Make the API call to update availability
//       final response = await http.put(
//         Uri.parse(url),
//         headers: {
//           "Content-Type": "application/json",
//           "Authorization": "Bearer $token"
//         },
//         body: jsonEncode(body),
//       );
      
//       // Print the response for debugging
//       print("Response status: ${response.statusCode}");
//       print("Response body: ${response.body}");
      
//       if (response.statusCode == 200) {
//         // Only try to decode if the status is 200
//         setState(() => isAvailable = !isAvailable);
        
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Status updated to ${isAvailable ? 'Available' : 'Not Available'}'),
//             backgroundColor: Colors.green,
//           ),
//         );
//       } else {
//         // Don't try to decode JSON if the response might be HTML
//         throw Exception('Failed to update availability: ${response.statusCode}');
//       }
//     } catch (e) {
//       print("Error in _toggleAvailability: $e");
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Failed to update availability: $e'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     } finally {
//       if (mounted) {
//         setState(() => isLoading = false);
//       }
//     }


//   }  @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Welcome, Dr. ${doctorName.split(' ').first}'),
//         backgroundColor: Colors.blue,
//         foregroundColor: Colors.white,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.person),
//             onPressed: () {
//               // Navigate to profile screen
//               Navigator.pushNamed(context, '/doctor/profile');
//             },
//           ),
//         ],
//       ),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : _buildHomeContent(),
//     );
//   }

//   Widget _buildHomeContent() {
//     return RefreshIndicator(
//       onRefresh: _loadDoctorInfo,
//       child: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildWelcomeCard(),
//             const SizedBox(height: 16),
//             _buildAvailabilityCard(),
//             const SizedBox(height: 16),
//             _buildStatsRow(),
//             const SizedBox(height: 24),
//             _buildFeatureGrid(),
//             const SizedBox(height: 24),
//             _buildAdviceSection(),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildWelcomeCard() {
//     return Card(
//       elevation: 4,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: Container(
//         width: double.infinity,
//         padding: const EdgeInsets.all(20),
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(16),
//           gradient: LinearGradient(
//             colors: [Colors.blue.shade700, Colors.blue.shade500],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//           ),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Doctor Dashboard',
//               style: TextStyle(
//                 fontSize: 24,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.white,
//               ),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               'Manage your consultations, appointments, and patient interactions',
//               style: TextStyle(
//                 fontSize: 14,
//                 color: Colors.white.withOpacity(0.9),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildAvailabilityCard() {
//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Row(
//           children: [
//             Icon(
//               isAvailable ? Icons.check_circle : Icons.do_not_disturb_on,
//               color: isAvailable ? Colors.green : Colors.red,
//               size: 28,
//             ),
//             const SizedBox(width: 16),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'Current Status: ${isAvailable ? 'Available' : 'Not Available'}',
//                     style: const TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   Text(
//                     isAvailable
//                         ? 'You can receive new consultation requests'
//                         : 'You are not receiving new consultation requests',
//                     style: TextStyle(
//                       fontSize: 14,
//                       color: Colors.grey[600],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             Switch(
//               value: isAvailable,
//               onChanged: (value) => _toggleAvailability(),
//               activeColor: Colors.green,
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildStatsRow() {
//     return Row(
//       children: [
//         Expanded(
//           child: _buildStatsCard(
//             'Pending Consultations',
//             pendingConsultations.toString(),
//             Icons.medical_services,
//             Colors.orange,
//             onTap: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (context) => const DoctorConsultationScreen()),
//               );
//             },
//           ),
//         ),
//         const SizedBox(width: 16),
//         Expanded(
//           child: _buildStatsCard(
//             'Upcoming Appointments',
//             upcomingAppointments.toString(),
//             Icons.event,
//             Colors.purple,
//             onTap: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (context) => const UpcomingAppointmentsScreen()),
//               );
//             },
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildStatsCard(String title, String value, IconData icon, Color color, {VoidCallback? onTap}) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(12),
//       child: Card(
//         elevation: 2,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(12),
//         ),
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 children: [
//                   Icon(icon, color: color, size: 20),
//                   const SizedBox(width: 8),
//                   Text(
//                     title, 
//                     style: TextStyle(
//                       color: Colors.grey[600],
//                       fontSize: 14
//                     )
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 value,
//                 style: const TextStyle(
//                   fontSize: 24,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildFeatureGrid() {
//     return GridView.count(
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       crossAxisCount: 2,
//       mainAxisSpacing: 16,
//       crossAxisSpacing: 16,
//       children: [
//               _buildFeatureCard(
//           title: 'Chat Consultations',
//           icon: Icons.chat,
//           color: Colors.green,
//           onTap: () {
//             Navigator.push(
//               context,
//               MaterialPageRoute(builder: (context) => const ChatListScreen()),
//             );
//           },
//         ),
//         _buildFeatureCard(
//           title: 'Chat Consultations',
//           icon: Icons.chat,
//           color: Colors.green,
//           onTap: () {
//             Navigator.push(
//               context,
//               MaterialPageRoute(builder: (context) => const ChatListScreen()),
//             );
//           },
//         ),
//         _buildFeatureCard(
//           title: 'Upcoming Appointments',
//           icon: Icons.calendar_today,
//           color: Colors.purple,
//           onTap: () {
//             Navigator.push(
//               context,
//               MaterialPageRoute(builder: (context) => const UpcomingAppointmentsScreen()),
//             );
//           },
//         ),
//         _buildFeatureCard(
//           title: 'Post Advice',
//           icon: Icons.tips_and_updates,
//           color: Colors.blue,
//           onTap: () {
//             Navigator.pushNamed(context, '/doctor/advice');
//           },
//         ),
//       ],
//     );
//   }

//   Widget _buildFeatureCard({
//     required String title,
//     required IconData icon,
//     required Color color,
//     required VoidCallback onTap,
//   }) {
//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: InkWell(
//         onTap: onTap,
//         borderRadius: BorderRadius.circular(12),
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: color.withOpacity(0.2),
//                   shape: BoxShape.circle,
//                 ),
//                 child: Icon(
//                   icon,
//                   size: 36,
//                   color: color,
//                 ),
//               ),
//               const SizedBox(height: 12),
//               Text(
//                 title,
//                 textAlign: TextAlign.center,
//                 style: const TextStyle(
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildAdviceSection() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'Quick Actions',
//           style: TextStyle(
//             fontSize: 18,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         const SizedBox(height: 16),
//         Row(
//           children: [
//             Expanded(
//               child: _buildQuickActionCard(
//                 title: 'Post Health Tip',
//                 icon: Icons.lightbulb_outline,
//                 onTap: () {
//                   Navigator.pushNamed(context, '/doctor/advice');
//                 },
//               ),
//             ),
//             const SizedBox(width: 16),
//             Expanded(
//               child: _buildQuickActionCard(
//                 title: 'View Statistics',
//                 icon: Icons.bar_chart,
//                 onTap: () {
//                   Navigator.pushNamed(context, '/doctor/statistics');
//                 },
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _buildQuickActionCard({
//     required String title,
//     required IconData icon,
//     required VoidCallback onTap,
//   }) {
//     return Card(
//       elevation: 1,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//         side: BorderSide(color: Colors.grey.shade300),
//       ),
//       child: InkWell(
//         onTap: onTap,
//         borderRadius: BorderRadius.circular(12),
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Row(
//             children: [
//               Icon(icon, color: Colors.blue),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: Text(
//                   title,
//                   style: const TextStyle(
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ),
//               const Icon(Icons.arrow_forward_ios, size: 16),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }




import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:my_app/basrel.dart' show baseUrl;
import 'package:my_app/core/utils/constants.dart';
import 'package:my_app/services/auth_service_api.dart';
import 'package:my_app/services/consultation_service.dart';
import 'package:my_app/views/appointments/UpcomingAppointmentsScreen.dart';
import 'package:my_app/views/chat/chat_list_screen.dart';
import 'package:my_app/views/doctors/DoctorAdviceScreen%20.dart';
import 'package:my_app/views/doctors/doctor_consultation_screen.dart';
import 'package:intl/intl.dart';
import 'package:my_app/views/profile/profile_screen.dart';

class DoctorHomeScreen extends StatefulWidget {
  const DoctorHomeScreen({Key? key}) : super(key: key);

  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

// Tab Bar Delegate
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverTabBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> with SingleTickerProviderStateMixin {
  // General state variables
  String doctorName = "Doctor";
  int? doctorId;
  bool isLoading = true;
  bool isAvailable = true;
  int pendingConsultations = 0;
  int upcomingAppointments = 0;
  int unreadMessages = 0;
  List<Map<String, dynamic>> todaysAppointments = [];
  
  // Tab controller
  late TabController _tabController;
  final List<String> _tabTitles = ['Dashboard', 'Patients', 'Appointments', 'Chats'];
  final List<IconData> _tabIcons = [
    Icons.dashboard_rounded,
    Icons.people_alt_rounded,
    Icons.calendar_today_rounded,
    Icons.chat_rounded
  ];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadDoctorInfo();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDoctorInfo() async {
    setState(() => isLoading = true);
    try {
      // Get doctor ID from API service
      doctorId = await ApiService.getCurrentDoctorId();
      
      // Get user name directly from auth service
      final userName = await ApiService.getUserFullName();
      if (userName != null && userName.isNotEmpty) {
        setState(() {
          doctorName = userName;
        });
      }
      
      if (doctorId != null) {
        // Get doctor profile from API
        final token = await ApiService.getAuthToken();
        if (token != null) {
          // Try different endpoint formats
          final List<String> endpoints = [
            "$baseUrl/doctor",
            "$baseUrl/doctors/$doctorId",
            "$baseUrl/doctors/profile",
          ];
          
          for (final endpoint in endpoints) {
            try {
              final response = await http.get(
                Uri.parse(endpoint),
                headers: {
                  "Content-Type": "application/json",
                  "Authorization": "Bearer $token"
                },
              );
              
              if (response.statusCode == 200) {
                final dynamic data = jsonDecode(response.body);
                final doctorData = data is List ? data[0] : data;
                
                setState(() {
                  // Only update name if it hasn't been set or is still default
                  if (doctorName == "Doctor") {
                    if (doctorData.containsKey('full_name')) {
                      doctorName = doctorData['full_name'] ?? "Doctor";
                    } else if (doctorData.containsKey('name')) {
                      doctorName = doctorData['name'] ?? "Doctor";
                    }
                  }
                  isAvailable = doctorData['is_available'] ?? true;
                });
                
                // Break out of the loop if successful
                break;
              }
            } catch (e) {
              debugPrint("Error fetching from $endpoint: $e");
              // Continue to the next endpoint
            }
          }
        }
        
        // Fetch consultations counts
        await _fetchConsultationsCounts();
        
        // Fetch today's appointments
        await _fetchTodaysAppointments();
        
        // Simulate unread message count (replace with actual API call)
        setState(() => unreadMessages = 5);
      }
    } catch (e) {
      debugPrint("Error in _loadDoctorInfo: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading doctor information: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _fetchConsultationsCounts() async {
    try {
      if (doctorId != null) {
        // Fetch pending consultations
        final pendingConsultations = await ConsultationService.fetchPendingConsultations(doctorId!);
        
        // Fetch upcoming appointments
        final upcomingAppointments = await ConsultationService.fetchUpcomingConsultations(doctorId!);
        
        setState(() {
          this.pendingConsultations = pendingConsultations.length;
          this.upcomingAppointments = upcomingAppointments.length;
        });
      }
    } catch (e) {
      debugPrint("Error fetching consultations counts: $e");
    }
  }

  Future<void> _fetchTodaysAppointments() async {
    try {
      if (doctorId != null) {
        final allAppointments = await ConsultationService.fetchUpcomingConsultations(doctorId!);
        
        // Filter for today's appointments
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        
        final todaysAppts = allAppointments
            .where((appt) {
              if (appt.consultationDate == null) return false;
              final appointmentDate = DateTime(
                appt.consultationDate!.year,
                appt.consultationDate!.month,
                appt.consultationDate!.day,
              );
              return appointmentDate.isAtSameMomentAs(today);
            })
            .map((appt) => {
              'id': appt.id,
              'patientName': appt.patientName ?? 'Unknown Patient',
              'patientAge': appt.patientAge,
              'patientGender': appt.patientGender,
              'time': appt.consultationDate,
              'type': appt.type,
              'isEmergency': appt.isEmergency,
              'patientId': appt.patientId,
            })
            .toList();
        
        if (mounted) {
          setState(() => todaysAppointments = todaysAppts);
        }
      }
    } catch (e) {
      debugPrint("Error fetching today's appointments: $e");
    }
  }

  Future<void> _toggleAvailability() async {
    if (doctorId == null) return;
    
    try {
      setState(() => isLoading = true);
      
      // Get the token
      final token = await ApiService.getAuthToken();
      if (token == null) throw Exception('Authentication token not found');
      
      final url = "$baseUrl/doctors/update-availability";
      final body = {
        "doctor_id": doctorId,
        "is_available": !isAvailable
      };
      
      // Make the API call to update availability
      final response = await http.put(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
        body: jsonEncode(body),
      );
      
      if (response.statusCode == 200) {
        setState(() => isAvailable = !isAvailable);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status updated to ${isAvailable ? 'Available' : 'Not Available'}'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } else {
        throw Exception('Failed to update availability: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update availability: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _navigateToScreen(String route, [Map<String, dynamic>? arguments]) {
    switch (route) {
      case 'consultations':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const DoctorConsultationScreen()),
        );
        break;
      case 'appointments':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const UpcomingAppointmentsScreen()),
        );
        break;
      case 'chat':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ChatListScreen()),
        );
        break;
      case 'specific_chat':
        if (arguments != null) {
          Navigator.pushNamed(
            context,
            '/doctor/chat',
            arguments: arguments,
          );
        }
        break;
      case 'advice':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const DoctorAdviceScreen()),
        );
        break;
      case 'statistics':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Statistics coming soon')),
        );
        break;
     case 'profile':
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfileScreen()),
      );
      break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : NestedScrollView(
              headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
                return [
                  _buildAppBar(innerBoxIsScrolled),
                  SliverPersistentHeader(
                    delegate: _SliverTabBarDelegate(
                      TabBar(
                        controller: _tabController,
                        labelColor: AppColors.primary,
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: AppColors.primary,
                        indicatorWeight: 3,
                        indicatorSize: TabBarIndicatorSize.label,
                        tabs: List.generate(
                          _tabTitles.length,
                          (index) => Tab(
                            text: _tabTitles[index],
                            icon: Icon(_tabIcons[index]),
                          ),
                        ),
                      ),
                    ),
                    pinned: true,
                  ),
                ];
              },
              body: TabBarView(
                controller: _tabController,
                children: [
                  _buildDashboardTab(),
                  _buildPatientsTab(),
                  _buildAppointmentsTab(),
                  _buildChatsTab(),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Depending on the active tab, open different actions
          switch (_tabController.index) {
            case 0: // Dashboard
              _showQuickActionsMenu();
              break;
            case 1: // Patients
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Add patient feature coming soon')),
              );
              break;
            case 2: // Appointments
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Add appointment feature coming soon')),
              );
              break;
            case 3: // Chats
              _navigateToScreen('chat');
              break;
          }
        },
        backgroundColor: AppColors.primary,
        child: Icon(
          _getFabIcon(),
          color: Colors.white,
        ),
      ),
    );
  }
  
  IconData _getFabIcon() {
    switch (_tabController.index) {
      case 0:
        return Icons.add;
      case 1:
        return Icons.person_add;
      case 2:
        return Icons.add_alarm;
      case 3:
        return Icons.chat;
      default:
        return Icons.add;
    }
  }
  
  void _showQuickActionsMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.green.shade50,
                child: const Icon(Icons.chat, color: Colors.green),
              ),
              title: const Text('New Chat'),
              onTap: () {
                Navigator.pop(context);
                _navigateToScreen('chat');
              },
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.orange.shade50,
                child: const Icon(Icons.medical_services, color: Colors.orange),
              ),
              title: const Text('Pending Consultations'),
              onTap: () {
                Navigator.pop(context);
                _navigateToScreen('consultations');
              },
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue.shade50,
                child: const Icon(Icons.edit_note, color: Colors.blue),
              ),
              title: const Text('Post Medical Advice'),
              onTap: () {
                Navigator.pop(context);
                _navigateToScreen('advice');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(bool innerBoxIsScrolled) {
    return SliverAppBar(
      expandedHeight: 200.0,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.primary,
      elevation: 0,
      actions: [
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications, color: Colors.white),
              onPressed: () {},
            ),
            if (unreadMessages > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    unreadMessages.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        IconButton(
          icon: CircleAvatar(
            backgroundColor: Colors.white,
            child: Text(
              doctorName.isNotEmpty ? doctorName[0].toUpperCase() : 'D',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          onPressed: () => _navigateToScreen('profile'),
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            // Background gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withOpacity(0.8),
                  ],
                ),
              ),
            ),
            // Background pattern
            Opacity(
              opacity: 0.1,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  image: const DecorationImage(
                    image: AssetImage('assets/img1.jpg'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            // Welcome text
            Positioned(
              top: 70,
              left: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome back,',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    doctorName.isNotEmpty ? 'Dr. $doctorName' : 'Doctor',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            // Availability switch
            
            // Stats row
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatItem(
                      label: 'Pending',
                      value: pendingConsultations.toString(),
                      icon: Icons.medical_services_outlined,
                      color: Colors.orange,
                      onTap: () => _navigateToScreen('consultations'),
                    ),
                    _buildDivider(),
                    _buildStatItem(
                      label: 'Upcoming',
                      value: upcomingAppointments.toString(),
                      icon: Icons.calendar_today_outlined,
                      color: Colors.purple,
                      onTap: () => _navigateToScreen('appointments'),
                    ),
                    _buildDivider(),
                    _buildStatItem(
                      label: 'Messages',
                      value: unreadMessages.toString(),
                      icon: Icons.chat_bubble_outline,
                      color: Colors.green,
                      onTap: () => _navigateToScreen('chat'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDivider() {
    return Container(
      height: 30,
      width: 1,
      color: Colors.grey.shade300,
    );
  }
  
  Widget _buildStatItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardTab() {
    return RefreshIndicator(
      onRefresh: _loadDoctorInfo,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status card
            _buildStatusCard(),
            const SizedBox(height: 24),
            
            // Quick actions section
            _buildSectionTitle('Quick Actions', Icons.flash_on),
            const SizedBox(height: 12),
            _buildQuickActionsGrid(),
            const SizedBox(height: 24),
 
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatusCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isAvailable
                ? [
                    Colors.green.shade50,
                    Colors.green.shade100,
                  ]
                : [
                    Colors.red.shade50,
                    Colors.red.shade100,
                  ],
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isAvailable ? Colors.green.shade100 : Colors.red.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isAvailable ? Icons.check_circle : Icons.do_not_disturb,
                    color: isAvailable ? Colors.green.shade800 : Colors.red.shade800,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAvailable ? 'You are available' : 'You are unavailable',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isAvailable ? Colors.green.shade800 : Colors.red.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isAvailable
                            ? 'Patients can request consultations'
                            : 'Patients cannot book consultations with you',
                        style: TextStyle(
                          fontSize: 14,
                          color: isAvailable ? Colors.green.shade700 : Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: isAvailable,
                  onChanged: (value) => _toggleAvailability(),
                  activeColor: Colors.green,
                  activeTrackColor: Colors.green.withOpacity(0.5),
                  inactiveThumbColor: Colors.red,
                  inactiveTrackColor: Colors.red.withOpacity(0.5),
                ),
              ],
            ),
            if (todaysAppointments.isNotEmpty) ...[
              const Divider(height: 24),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.event_note,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'You have ${todaysAppointments.length} appointment${todaysAppointments.length > 1 ? 's' : ''} today',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
      ],
    );
  }
  
  Widget _buildQuickActionsGrid() {
    final List<Map<String, dynamic>> actions = [
      {
        'title': 'Consultations',
        'icon': Icons.medical_services_outlined,
        'color': Colors.orange,
        'route': 'consultations',
      },
      {
        'title': 'Messages',
        'icon': Icons.chat_bubble_outline,
        'color': Colors.green,
        'route': 'chat',
      },
      {
        'title': 'Appointments',
        'icon': Icons.calendar_today_outlined,
        'color': Colors.purple,
        'route': 'appointments',
      },
      {
        'title': 'Post Advice',
        'icon': Icons.lightbulb_outline,
        'color': Colors.blue,
        'route': 'advice',
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            onTap: () => _navigateToScreen(action['route']),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: action['color'].withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      action['icon'],
                      color: action['color'],
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    action['title'],
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  
  
  Widget _buildAppointmentCard(Map<String, dynamic> appointment) {
    final String timeStr = appointment['time'] != null
        ? DateFormat('h:mm a').format(appointment['time'])
        : 'Time not set';
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // Navigate to the specific chat with this patient
          _navigateToScreen('specific_chat', {
            'consultationId': appointment['id'],
            'patientName': appointment['patientName'],
            'patientId': appointment['patientId'] ?? 0,
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Patient avatar
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: Text(
                  appointment['patientName'].isNotEmpty
                      ? appointment['patientName'][0].toUpperCase()
                      : 'P',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // Appointment details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          appointment['patientName'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getConsultationTypeColor(appointment['type']).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            appointment['type'] ?? 'Video',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _getConsultationTypeColor(appointment['type']),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              timeStr,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        if (appointment['patientAge'] != null)
                          Text(
                            '${appointment['patientAge']} years, ${appointment['patientGender'] ?? 'Unknown'}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Action button
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.chat_outlined,
                    color: Colors.green,
                    size: 20,
                  ),
                  onPressed: () {
                    _navigateToScreen('specific_chat', {
                      'consultationId': appointment['id'],
                      'patientName': appointment['patientName'],
                      'patientId': appointment['patientId'] ?? 0,
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Color _getConsultationTypeColor(String? type) {
    switch (type?.toLowerCase()) {
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
  
  
  
 Widget _buildPatientsTab() {
  // Mock patient data (in a real app, this would come from an API)
  final List<Map<String, dynamic>> patients = [
    {
      'id': 1,
      'name': 'Emma Johnson',
      'age': 35,
      'gender': 'Female',
      'lastConsultation': '2 days ago',
      'consultationCount': 3,
      'activeConsultation': true,
    },
    {
      'id': 2,
      'name': 'Michael Rodriguez',
      'age': 42,
      'gender': 'Male',
      'lastConsultation': '1 week ago',
      'consultationCount': 2,
      'activeConsultation': false,
    },
    // Add more patients as needed
  ];

  return Scaffold(
    body: CustomScrollView(
      slivers: [
        // Search and Filter Section
        SliverAppBar(
          floating: true,
          snap: true,
          title: const Text('Patients'),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(70),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search patients...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),
          ),
        ),

        // Patient List
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final patient = patients[index];
                return _buildPatientCard(patient);
              },
              childCount: patients.length,
            ),
          ),
        ),
      ],
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Add patient feature coming soon')),
        );
      },
      backgroundColor: AppColors.primary,
      child: const Icon(Icons.person_add, color: Colors.white),
    ),
  );
}

// Patient Card Widget
Widget _buildPatientCard(Map<String, dynamic> patient) {
  return Card(
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    margin: const EdgeInsets.only(bottom: 16),
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        // TODO: Navigate to patient details
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Viewing ${patient['name']}\'s details')),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: Text(
                patient['name'][0].toUpperCase(),
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    patient['name'],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${patient['age']} years, ${patient['gender']}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (patient['activeConsultation'])
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Active',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    ),
  );
}
  
  // New method for Appointments Tab
  Widget _buildAppointmentsTab() {
    return const UpcomingAppointmentsScreen(showAppBar: false);
  }
  
  
  
 
  
  // Chats Tab UI
  Widget _buildChatsTab() {
    // Simulated chat list
    final List<Map<String, dynamic>> chats = [
      {
        'name': 'Emma Phillips',
        'message': 'Thank you for the consultation, doctor.',
        'time': '10:30 AM',
        'unread': 2,
        'image': null,
      },
      {
        'name': 'John Cooper',
        'message': 'When should I take the medication?',
        'time': 'Yesterday',
        'unread': 0,
        'image': null,
      },
      {
        'name': 'Lisa Wong',
        'message': 'I\'ve been feeling better since last visit',
        'time': 'Yesterday',
        'unread': 0,
        'image': null,
      },
      {
        'name': 'David Garcia',
        'message': 'Here are my recent blood test results',
        'time': 'Monday',
        'unread': 1,
        'image': null,
      },
    ];
    
    return ListView.builder(
      itemCount: chats.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final chat = chats[index];
        return Card(
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              _navigateToScreen('specific_chat', {
                'consultationId': index + 1, // Just for demo
                'patientName': chat['name'],
                'patientId': index + 1, // Just for demo
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        backgroundImage: chat['image'] != null ? NetworkImage(chat['image']) : null,
                        child: chat['image'] == null
                            ? Text(
                                chat['name'].toString().isNotEmpty
                                    ? chat['name'].toString()[0].toUpperCase()
                                    : 'U',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                  fontSize: 18,
                                ),
                              )
                            : null,
                      ),
                      if (chat['unread'] > 0)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              chat['unread'].toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              chat['name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              chat['time'],
                              style: TextStyle(
                                fontSize: 12,
                                color: chat['unread'] > 0 ? Colors.green : Colors.grey[500],
                                fontWeight: chat['unread'] > 0 ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          chat['message'],
                          style: TextStyle(
                            fontSize: 14,
                            color: chat['unread'] > 0 ? Colors.black87 : Colors.grey[600],
                            fontWeight: chat['unread'] > 0 ? FontWeight.w500 : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}