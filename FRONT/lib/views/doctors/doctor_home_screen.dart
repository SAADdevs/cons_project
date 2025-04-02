import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:my_app/basrel.dart' show baseUrl;
import 'package:my_app/services/consultation_service.dart';
import 'package:my_app/views/appointments/UpcomingAppointmentsScreen.dart';
import 'package:my_app/views/doctors/DoctorAdviceScreen%20.dart';
import 'package:my_app/views/doctors/doctor_consultation_screen.dart';
import 'package:my_app/widgets/DoctorHomeWidgets.dart';
import '../../basrel.dart';
import '../../services/auth_service_api.dart';

class DoctorHomeScreen extends StatefulWidget {
  const DoctorHomeScreen({super.key});

  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
  String doctorName = "Doctor";
  int? doctorId;
  bool isLoading = true;
  bool isAvailable = true;
  int pendingConsultations = 0;
  int upcomingAppointments = 0;

  @override
  void initState() {
    super.initState();
    _loadDoctorInfo();
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
        print("Loaded doctor name from auth service: $doctorName");
      }
      
      if (doctorId != null) {
        // Get doctor profile from API (as a fallback or for additional data)
        final token = await ApiService.getAuthToken();
        if (token != null) {
        // Try different endpoint formats if the original doesn't work
          final List<String> endpoints = [
            "$baseUrl/doctor",
            "$baseUrl/doctors/$doctorId",
            "$baseUrl/doctors/profile",
          ];
          
          for (final endpoint in endpoints) {
            try {
              print("Attempting to fetch doctor profile from: $endpoint");
              final response = await http.get(
                Uri.parse(endpoint),
                headers: {
                  "Content-Type": "application/json",
                  "Authorization": "Bearer $token"
                },
              );
              
              if (response.statusCode == 200) {
                print("Doctor profile response: ${response.body}");
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
                print("Final doctor name: $doctorName");
                
                // Break out of the loop if successful
                break;
              }
            } catch (e) {
              print("Error fetching from $endpoint: $e");
              // Continue to the next endpoint
            }
          }
        }
        
        // Fetch consultations counts regardless of profile response
        await _fetchConsultationsCounts();
      }
    } catch (e) {
      print("Error in _loadDoctorInfo: $e");
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching consultations: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
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
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _navigateToScreen(String route) {
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
          MaterialPageRoute(builder: (context) => const UpcomingAppointmentsScreen()),
        );
        break;
      case 'advice':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const DoctorAdviceScreen()),
        );
      case 'statistics':
        Navigator.pushNamed(context, '/doctor/statistics');
        break;
      case 'profile':
        Navigator.pushNamed(context, '/doctor/profile');
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
          ? const Center(child: CircularProgressIndicator())
          : _buildHomeContent(),
    );
  }

  Widget _buildHomeContent() {
    return RefreshIndicator(
      onRefresh: _loadDoctorInfo,
      child: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  DoctorHomeWidgets.buildAvailabilityCard(
                    isAvailable: isAvailable,
                    onToggle: _toggleAvailability,
                  ),
                  const SizedBox(height: 24),
                  _buildStatsRow(),
                  const SizedBox(height: 24),
                  const Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureGrid(),
                  const SizedBox(height: 24),
                  _buildUpcomingSection(),
                  const SizedBox(height: 100), // Bottom padding
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 200.0,
      floating: false,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        title: Text(
          doctorName.isEmpty 
              ? 'Doctor Dashboard' 
              : 'Dr. ${doctorName.split(' ').first}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            DoctorHomeWidgets.buildAppBarBackground(),
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              right: 20,
              child: CircleAvatar(
                backgroundColor: Colors.white,
                radius: 20,
                child: IconButton(
                  icon: const Icon(Icons.person, color: Color(0xFF1976D2), size: 20),
                  onPressed: () => _navigateToScreen('profile'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: DoctorHomeWidgets.buildStatsCard(
            title: 'Pending Requests',
            value: pendingConsultations.toString(),
            icon: Icons.medical_services_outlined,
            color: const Color(0xFFF57C00),
            onTap: () => _navigateToScreen('consultations'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: DoctorHomeWidgets.buildStatsCard(
            title: 'Upcoming Appointments',
            value: upcomingAppointments.toString(),
            icon: Icons.event_note_outlined,
            color: const Color(0xFF7B1FA2),
            onTap: () => _navigateToScreen('appointments'),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureGrid() {
    final List<Map<String, dynamic>> features = [
      {
        'title': 'Consultations',
        'icon': Icons.medical_services_outlined,
        'color': const Color(0xFFF57C00),
        'route': 'consultations',
      },
      {
        'title': 'Chat',
        'icon': Icons.chat_outlined,
        'color': const Color(0xFF43A047),
        'route': 'chat',
      },
      {
        'title': 'Appointments',
        'icon': Icons.calendar_today_outlined,
        'color': const Color(0xFF7B1FA2),
        'route': 'appointments',
      },
      {
        'title': 'Post Advice',
        'icon': Icons.tips_and_updates_outlined,
        'color': const Color(0xFF1976D2),
        'route': 'advice',
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: features.length,
      itemBuilder: (context, index) {
        final feature = features[index];
        return DoctorHomeWidgets.buildFeatureCard(
          title: feature['title'],
          icon: feature['icon'],
          color: feature['color'],
          onTap: () => _navigateToScreen(feature['route']),
        );
      },
    );
  }

  Widget _buildUpcomingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Additional Tools',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 16),
        DoctorHomeWidgets.buildActionCard(
          title: 'View Statistics',
          description: 'Track your consultation metrics',
          icon: Icons.bar_chart,
          color: const Color(0xFF00897B),
          onTap: () => _navigateToScreen('statistics'),
        ),
      ],
    );
  }
}