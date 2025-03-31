import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:my_app/basrel.dart';
import 'dart:convert';
import 'package:my_app/views/patients/DoctorCategoriesScreen.dart';
import 'package:my_app/views/patients/DoctorsByCategoryScreen.dart';
import 'package:my_app/views/patients/MyConsultationsScreen.dart';
import 'package:my_app/views/patients/HealthAdviceDetailsScreen.dart';
import 'package:my_app/views/profile/profile_screen.dart';
import 'package:my_app/core/models/healthAdvice.dart';
import 'package:my_app/services/auth_service_api.dart'; // Import auth service
import '../../core/utils/constants.dart';

class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  _PatientHomeScreenState createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  int _selectedIndex = 0;

  // Add a fourth page for the chat tab
  late final List<Widget> _pages;
  
  @override
  void initState() {
    super.initState();
    _pages = [
      const PatientHomePage(),
      const MyConsultationsScreen(),
      const Center(child: Text('Chat feature coming soon')), // Placeholder for Chat tab
      const ProfileScreen(),
    ];
  }
  
  @override
  Widget build(BuildContext context) {
    // Set status bar color
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // Make status bar transparent
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      extendBodyBehindAppBar: true, // Extend content behind app bar
      backgroundColor: Colors.white,
      // Use IndexedStack to maintain page state when switching tabs
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
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
  bool _isLoadingUserData = true;
  String _errorMessage = '';
  bool _showError = false;
  String _patientName = '';
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadHealthTips();
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Load the current user's name
  Future<void> _loadUserData() async {
    try {
      final name = await ApiService.getUserFullName();
      
      setState(() {
        // Extract first name if there's a space in the full name
        if (name != null && name.isNotEmpty) {
          final nameParts = name.split(' ');
          _patientName = nameParts.first.toLowerCase(); // Convert to lowercase to match design
        } else {
          _patientName = 'patient'; // Default if no name is found, lowercase to match design
        }
        _isLoadingUserData = false;
        _showError = false;
      });
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        _patientName = 'patient'; // Default in case of error
        _isLoadingUserData = false;
      });
    }
  }

  Future<void> _loadHealthTips() async {
    setState(() {
      _isLoadingTips = true;
      _errorMessage = '';
      _showError = false;
    });

    try {
      // Use the approved endpoint
      final response = await http.get(
        Uri.parse('$baseUrl/health-advice/approved'),
        headers: {"Content-Type": "application/json"},
      );

      print('Health tips response status: ${response.statusCode}');
      
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
          _showError = false;
        });
        
        print('Successfully loaded ${_healthTips.length} health tips');
      } else {
        setState(() {
          _errorMessage = 'Failed to load health tips: ${response.statusCode}';
          _isLoadingTips = false;
          
          // We'll show health tips UI anyway, just without data
          _healthTips = [];
        });
      }
    } catch (e) {
      print('Error loading health tips: $e');
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoadingTips = false;
        _healthTips = []; // Empty list instead of null
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        // Refresh both user data and health tips
        await Future.wait([
          _loadUserData(),
          _loadHealthTips(),
        ]);
      },
      child: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                // Header at the very top of screen
                _buildHeader(context),
        
                // Search Bar
                _buildSearchBar(),
        
                // Quick Services
                _buildQuickServicesSection(context),
        
                // Medical Specialties
                _buildSectionTitle('Medical Specialties'),
                _buildMedicalSpecialtiesGrid(context),
        
                // Health Tips Section
                _buildSectionTitle('Health Tips'),
                _buildHealthTipsCarousel(),
                
                // Add bottom padding to ensure content is not hidden behind the navigation bar
                const SizedBox(height: 30),
              ],
            ),
          ),
          
          // Error notification that doesn't block the UI
          if (_showError)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.red.shade700,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Could not load patient info. Using local data.',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.white),
                      onPressed: () {
                        setState(() {
                          _showError = false;
                        });
                      },
                    )
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        left: 16, 
        right: 16, 
        // Add padding at the top for status bar
        top: MediaQuery.of(context).padding.top + 20,
        bottom: 20
      ),
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
              _isLoadingUserData 
                ? const SizedBox(
                    height: 20, 
                    width: 100, 
                    child: LinearProgressIndicator(backgroundColor: Colors.white24, color: Colors.white)
                  )
                : Text(
                    'Hello, $_patientName',
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chat feature coming soon!')),
              );
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
    
    // Instead of showing an error, we'll just show empty state
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