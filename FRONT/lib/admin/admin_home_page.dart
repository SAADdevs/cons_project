import 'package:flutter/material.dart';
import 'package:my_app/basrel.dart';
import 'admin_doctors_page.dart';
import 'admin_advice_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/auth_service_api.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({Key? key}) : super(key: key);

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  bool _isLoading = true;
  Map<String, dynamic> _stats = {
    'doctors': 45,
    'patients': 1200,
    'consultations': 320,
    'pendingVerifications': 12,
    'pendingAdvice': 8,
  };

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
  setState(() => _isLoading = true);
  
  try {
    
    
    // Fetch all dashboard statistics in one call
    final response = await http.get(
      Uri.parse('$baseUrl/dashboard'),
      headers: {
        "Content-Type": "application/json",
        // "Authorization": "Bearer $token"
      },
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      // Print the response to debug
      print("Statistics data: $data");
      
      setState(() {
        _stats = {
          'doctors': data['doctors']['total'] ?? 0,
          'patients': data['patients']['total'] ?? 0,
          'consultations': data['consultations']['total'] ?? 0,
          'pendingVerifications': data['doctors']['pending'] ?? 0,
          'pendingAdvice': data['healthAdvice']['pending'] ?? 0,
        };
        _isLoading = false;
      });
    } else {
      print("API error: ${response.statusCode} - ${response.body}");
      throw Exception('Failed to load statistics: ${response.statusCode}');
    }
  } catch (e) {
    print('Error loading statistics: $e');
    // Fallback to sample data on error
    setState(() {
      _stats = {
        'doctors': 0,  // Using 0 instead of sample data to clearly show when API is not working
        'patients': 0,
        'consultations': 0,
        'pendingVerifications': 0,
        'pendingAdvice': 0,
      };
      _isLoading = false;
    });
  }
}

  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStatistics,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStatistics,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildWelcomeSection(),
                      const SizedBox(height: 24),
                      _buildStatisticsSection(),
                      const SizedBox(height: 24),
                      _buildManagementSection(),
                      const SizedBox(height: 24),
                      // _buildRecentActivitiesSection(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildWelcomeSection() {
    final now = DateTime.now();
    final greeting = now.hour < 12 
        ? 'Good Morning'
        : now.hour < 17 
            ? 'Good Afternoon' 
            : 'Good Evening';
            
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.blue.shade100,
              child: const Icon(
                Icons.admin_panel_settings,
                color: Colors.blue,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$greeting, Admin',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Welcome to your dashboard',
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${now.day}/${now.month}/${now.year}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
 Widget _buildStatisticsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Statistics Overview',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Doctors',
                count: _stats['doctors'],
                icon: Icons.medical_services,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'Patients',
                count: _stats['patients'],
                icon: Icons.people,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'Consultations',
                count: _stats['consultations'],
                icon: Icons.calendar_today,
                color: Colors.purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Pending Doctor Verifications',
                count: _stats['pendingVerifications'],
                icon: Icons.verified_user,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'Pending Health Advice',
                count: _stats['pendingAdvice'],
                icon: Icons.article,
                color: Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }


  Widget _buildStatCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManagementSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Management',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildManagementCard(
                title: 'Manage Doctors',
                icon: Icons.medical_services,
                color: Colors.blue,
                pendingCount: _stats['pendingVerifications'],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AdminDoctorsPage()),
                  ).then((_) => _loadStatistics()); // Refresh stats when returning
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildManagementCard(
                title: 'Manage Health Advice',
                icon: Icons.article,
                color: Colors.orange,
                pendingCount: _stats['pendingAdvice'],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AdminAdvicePage()),
                  ).then((_) => _loadStatistics()); // Refresh stats when returning
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildManagementCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    int? pendingCount,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                if (pendingCount != null && pendingCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      pendingCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}