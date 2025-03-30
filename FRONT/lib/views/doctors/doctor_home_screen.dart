import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:my_app/basrel.dart' show baseUrl;
import 'package:my_app/views/appointments/UpcomingAppointmentsScreen.dart';
import 'package:my_app/views/doctors/doctor_consultation_screen.dart';
import '../../basrel.dart';
import '../../core/models/consultation.dart';
import '../../services/auth_service_api.dart';
import '../../services/consultation_service.dart';

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
      
      if (doctorId != null) {
        // Get doctor profile from API
        final token = await ApiService.getAuthToken();
        if (token != null) {
          final response = await http.get(
            Uri.parse("$baseUrl/doctor"),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token"
            },
          );
          
          if (response.statusCode == 200) {
            final doctorData = jsonDecode(response.body);
            setState(() {
              doctorName = doctorData['full_name'] ?? "Doctor";
              isAvailable = doctorData['is_available'] ?? true;
            });
            
            // Fetch consultations counts
            await _fetchConsultationsCounts();
          }
        }
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
        
        print("Updated counts - Pending: ${pendingConsultations.length}, Upcoming: ${upcomingAppointments.length}");
      }
    } catch (e) {
      print('Error fetching consultation counts: $e');
      // Optionally show a snackbar to the user
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
      
      // Print doctor ID and current availability for debugging
      print("Doctor ID: $doctorId, Current availability: $isAvailable");
      
      // Print the request URL and body for debugging

      final url = "$baseUrl/doctors/update-availability";
      final body = {
        "doctor_id": doctorId,
        "is_available": !isAvailable
      };
      print("Making request to: $url");
      print("Request body: ${jsonEncode(body)}");
      
      // Make the API call to update availability
      final response = await http.put(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
        body: jsonEncode(body),
      );
      
      // Print the response for debugging
      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");
      
      if (response.statusCode == 200) {
        // Only try to decode if the status is 200
        setState(() => isAvailable = !isAvailable);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status updated to ${isAvailable ? 'Available' : 'Not Available'}'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Don't try to decode JSON if the response might be HTML
        throw Exception('Failed to update availability: ${response.statusCode}');
      }
    } catch (e) {
      print("Error in _toggleAvailability: $e");
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


  }  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, Dr. ${doctorName.split(' ').first}'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              // Navigate to profile screen
              Navigator.pushNamed(context, '/doctor/profile');
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildHomeContent(),
    );
  }

  Widget _buildHomeContent() {
    return RefreshIndicator(
      onRefresh: _loadDoctorInfo,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCard(),
            const SizedBox(height: 16),
            _buildAvailabilityCard(),
            const SizedBox(height: 16),
            _buildStatsRow(),
            const SizedBox(height: 24),
            _buildFeatureGrid(),
            const SizedBox(height: 24),
            _buildAdviceSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.blue.shade700, Colors.blue.shade500],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Doctor Dashboard',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Manage your consultations, appointments, and patient interactions',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailabilityCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              isAvailable ? Icons.check_circle : Icons.do_not_disturb_on,
              color: isAvailable ? Colors.green : Colors.red,
              size: 28,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Status: ${isAvailable ? 'Available' : 'Not Available'}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    isAvailable
                        ? 'You can receive new consultation requests'
                        : 'You are not receiving new consultation requests',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: isAvailable,
              onChanged: (value) => _toggleAvailability(),
              activeColor: Colors.green,
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
          child: _buildStatsCard(
            'Pending Consultations',
            pendingConsultations.toString(),
            Icons.medical_services,
            Colors.orange,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DoctorConsultationScreen()),
              );
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatsCard(
            'Upcoming Appointments',
            upcomingAppointments.toString(),
            Icons.event,
            Colors.purple,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UpcomingAppointmentsScreen()),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCard(String title, String value, IconData icon, Color color, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
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
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        _buildFeatureCard(
          title: 'Consultation Requests',
          icon: Icons.medical_services,
          color: Colors.orange,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const DoctorConsultationScreen()),
            );
          },
        ),
        _buildFeatureCard(
          title: 'Chat Consultations',
          icon: Icons.chat,
          color: Colors.green,
          onTap: () {
           Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const  UpcomingAppointmentsScreen()),
);
          },
        ),
        _buildFeatureCard(
          title: 'Upcoming Appointments',
          icon: Icons.calendar_today,
          color: Colors.purple,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const UpcomingAppointmentsScreen()),
            );
          },
        ),
        _buildFeatureCard(
          title: 'Post Advice',
          icon: Icons.tips_and_updates,
          color: Colors.blue,
          onTap: () {
            Navigator.pushNamed(context, '/doctor/advice');
          },
        ),
      ],
    );
  }

  Widget _buildFeatureCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 36,
                  color: color,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdviceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                title: 'Post Health Tip',
                icon: Icons.lightbulb_outline,
                onTap: () {
                  Navigator.pushNamed(context, '/doctor/advice');
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildQuickActionCard(
                title: 'View Statistics',
                icon: Icons.bar_chart,
                onTap: () {
                  Navigator.pushNamed(context, '/doctor/statistics');
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: Colors.blue),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}