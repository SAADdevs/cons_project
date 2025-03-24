import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:my_app/views/patients/DoctorCategoriesScreen.dart';
import 'package:my_app/views/patients/DoctorsByCategoryScreen.dart';
import 'package:my_app/views/patients/MyConsultationsScreen.dart';
import 'package:my_app/views/patients/HealthAdviceDetailsScreen.dart';
import 'package:my_app/views/profile/profile_screen.dart';
import 'package:my_app/core/models/healthAdvice.dart';
import '../../core/utils/constants.dart';

class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  _PatientHomeScreenState createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  int _selectedIndex = 0;
  
  // Define the pages for bottom navigation
  final List<Widget> _pages = [
    const PatientHomePage(),
    const MyConsultationsScreen(),
    const ProfileScreen(),
  ];
  
  @override
  Widget build(BuildContext context) {
    // Set status bar color
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: AppColors.primary,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: Colors.white,
      body: _pages[_selectedIndex],
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: Colors.grey[400],
      elevation: 10,
      currentIndex: _selectedIndex,
      onTap: (index) {
        setState(() {
          _selectedIndex = index;
        });
      },
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home, color: AppColors.primary),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.medical_services_outlined),
          activeIcon: Icon(Icons.medical_services, color: AppColors.primary),
          label: 'Consultations',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.chat_bubble_outline),
          activeIcon: Icon(Icons.chat_bubble, color: AppColors.primary),
          label: 'Chats',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person, color: AppColors.primary),
          label: 'Profile',
        ),
      ],
    );
  }
}

class PatientHomePage extends StatefulWidget {
  const PatientHomePage({super.key});

  @override
  _PatientHomePageState createState() => _PatientHomePageState();
}

class _PatientHomePageState extends State<PatientHomePage> {
  List<HealthAdvice> _healthTips = [];
  bool _isLoadingTips = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadHealthTips();
  }

  Future<void> _loadHealthTips() async {
  setState(() {
    _isLoadingTips = true;
    _errorMessage = '';
  });

  try {
    // Use the approved endpoint since it's working
    final response = await http.get(
      Uri.parse('http://192.168.1.55:5000/api/health-advice/approved'),
      headers: {"Content-Type": "application/json"},
    );

    print('Response status: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      print('Parsed ${data.length} health tips');
      
      List<HealthAdvice> tips = [];
      
      for (var item in data) {
        tips.add(
          HealthAdvice(
            id: item['id'] ?? 0,
            doctorId: item['doctor_id'] ?? 0,
            title: item['title'] ?? 'Untitled',
            content: item['advice_text'] ?? '',
            category: item['category'] ?? 'General',
            isApproved: item['is_approved'] ?? false,
            createdAt: item['created_at'] != null 
                ? DateTime.parse(item['created_at']) 
                : DateTime.now(),
            doctorName: item['doctor_name'] ?? 'Unknown Doctor',
            doctorSpecialty: item['specialties'] ?? '',
          )
        );
      }
      
      setState(() {
        _healthTips = tips;
        _isLoadingTips = false;
      });
      
      print('Successfully loaded ${_healthTips.length} health tips');
    } else {
      setState(() {
        _errorMessage = 'Failed to load health tips: ${response.statusCode}';
        _isLoadingTips = false;
      });
    }
  } catch (e) {
    print('Error loading health tips: $e');
    setState(() {
      _errorMessage = 'Error: $e';
      _isLoadingTips = false;
    });
  }
}
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadHealthTips,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Personalized Header
            SliverToBoxAdapter(
              child: _buildHeader(context),
            ),

            // Search Bar
            SliverToBoxAdapter(
              child: _buildSearchBar(),
            ),

            // Quick Services
            SliverToBoxAdapter(
              child: _buildQuickServicesSection(context),
            ),

            // Medical Specialties
            SliverToBoxAdapter(
              child: _buildSectionTitle('Medical Specialties'),
            ),
            SliverToBoxAdapter(
              child: _buildMedicalSpecialtiesGrid(context),
            ),

            // Health Tips Section
            SliverToBoxAdapter(
              child: _buildSectionTitle('Health Tips'),
            ),
            SliverToBoxAdapter(
              child: _buildHealthTipsCarousel(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, Colors.blue.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(25),
          bottomRight: Radius.circular(25),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, Sarah',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w300,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Find Your Doctor',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(8),
            child: const Icon(
              Icons.notifications_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: TextField(
          decoration: InputDecoration(
            hintText: 'Search doctors, services...',
            prefixIcon: Icon(
              Icons.search,
              color: AppColors.primary,
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickServicesSection(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildQuickServiceCard(
            context: context,
            icon: Icons.medical_services,
            title: 'Consultation',
            color: Colors.blue,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DoctorCategoriesScreen()),
              );
            },
          ),
          const SizedBox(width: 16),
          _buildQuickServiceCard(
            context: context,
            icon: Icons.calendar_today,
            title: 'Appointments',
            color: Colors.green,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MyConsultationsScreen()),
              );
            },
          ),
          const SizedBox(width: 16),
          _buildQuickServiceCard(
            context: context,
            icon: Icons.chat_bubble_outline,
            title: 'Chat',
            color: Colors.purple,
            onTap: () {
              // Chat functionality
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickServiceCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          TextButton(
            onPressed: () {
              // Navigate to see all health tips or specialties
            },
            child: Text(
              'See All',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalSpecialtiesGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        _buildSpecialtyItem(
          context: context,
          icon: Icons.favorite,
          title: 'Cardiology',
          color: Colors.red,
          specialty: 'Cardiology',
        ),
        _buildSpecialtyItem(
          context: context,
          icon: Icons.face,
          title: 'Dermatology',
          color: Colors.orange,
          specialty: 'Dermatology',
        ),
        _buildSpecialtyItem(
          context: context,
          icon: Icons.child_care,
          title: 'Pediatrics',
          color: Colors.blue,
          specialty: 'Pediatrics',
        ),
        _buildSpecialtyItem(
          context: context,
          icon: Icons.psychology,
          title: 'Neurology',
          color: Colors.green,
          specialty: 'Neurology',
        ),
        _buildSpecialtyItem(
          context: context,
          icon: Icons.accessibility,
          title: 'Orthopedics',
          color: Colors.purple,
          specialty: 'Orthopedics',
        ),
        _buildSpecialtyItem(
          context: context,
          icon: Icons.medical_services,
          title: 'Dentistry',
          color: Colors.teal,
          specialty: 'Dentistry',
        ),
        _buildSpecialtyItem(
          context: context,
          icon: Icons.remove_red_eye,
          title: 'Eye Care',
          color: Colors.indigo,
          specialty: 'Ophthalmology',
        ),
        _buildSpecialtyItem(
          context: context,
          icon: Icons.sentiment_satisfied,
          title: 'Psychiatry',
          color: Colors.amber,
          specialty: 'Psychiatry',
        ),
      ],
    );
  }

  Widget _buildSpecialtyItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Color color,
    required String specialty,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DoctorsBySpecialtyScreen(specialty: specialty),
          ),
        );
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: color.withOpacity(0.3), width: 1),
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthTipsCarousel() {
    if (_isLoadingTips) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            children: [
              Text(
                'Failed to load health tips',
                style: TextStyle(
                  color: Colors.red[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(_errorMessage, style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadHealthTips,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    
    if (_healthTips.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              Text(
                'No health tips available',
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loadHealthTips,
                child: const Text('Refresh'),
              ),
            ],
          ),
        ),
      );
    }

    // Color mapping for different categories
    final Map<String, Color> categoryColors = {
      'General': Colors.blue,
      'Nutrition': Colors.green,
      'Exercise': Colors.orange,
      'Mental Health': Colors.purple,
      'Wellness': Colors.teal,
      'Cardiology': Colors.red,
      'Dermatology': Colors.amber,
      'Pediatrics': Colors.cyan,
    };
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: _healthTips.map((tip) {
          // Get card color based on category or default to blue
          final color = categoryColors[tip.category] ?? Colors.blue;
          
          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _buildHealthTipCard(
              title: tip.title,
              description: tip.content,
              color: color,
              doctor: tip.doctorName ?? 'Unknown Doctor',
              advice: tip,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHealthTipCard({
    required String title,
    required String description,
    required Color color,
    required String doctor,
    required HealthAdvice advice,
  }) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            'By Dr. $doctor',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: TextStyle(
              color: Colors.grey[700],
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () {
                // Navigate to health advice details
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HealthAdviceDetailsScreen(advice: advice),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Read More'),
            ),
          ),
        ],
      ),
    );
  }
}