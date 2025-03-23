import 'package:flutter/material.dart';
import 'package:my_app/services/doctor_service.dart';
import 'package:my_app/views/patients/DoctorsByCategoryScreen.dart';
import '../../core/utils/constants.dart';


class DoctorCategoriesScreen extends StatefulWidget {
  const DoctorCategoriesScreen({super.key});

  @override
  _DoctorCategoriesScreenState createState() => _DoctorCategoriesScreenState();
}

class _DoctorCategoriesScreenState extends State<DoctorCategoriesScreen> {
  // List of medical specialties with icons and colors
  final List<Map<String, dynamic>> _specialties = [
    {
      'name': 'Cardiology',
      'icon': Icons.favorite,
      'color': Colors.red,
      'description': 'Heart and blood vessel specialists'
    },
    {
      'name': 'Dermatology',
      'icon': Icons.face,
      'color': Colors.orange,
      'description': 'Skin, hair, and nail experts'
    },
    {
      'name': 'Pediatrics',
      'icon': Icons.child_care,
      'color': Colors.blue,
      'description': 'Specialized care for children'
    },
    {
      'name': 'Neurology',
      'icon': Icons.psychology,
      'color': Colors.green,
      'description': 'Brain and nervous system specialists'
    },
    {
      'name': 'Orthopedics',
      'icon': Icons.accessibility,
      'color': Colors.purple,
      'description': 'Bone and joint health experts'
    },
    {
      'name': 'Dentistry',
      'icon': Icons.medical_services,
      'color': Colors.teal,
      'description': 'Oral health and dental care'
    },
    {
      'name': 'Ophthalmology',
      'icon': Icons.remove_red_eye,
      'color': Colors.indigo,
      'description': 'Eye care and vision specialists'
    },
    {
      'name': 'Psychiatry',
      'icon': Icons.sentiment_satisfied,
      'color': Colors.amber,
      'description': 'Mental health and wellness'
    },
    {
      'name': 'Gynecology',
      'icon': Icons.pregnant_woman,
      'color': Colors.pink,
      'description': 'Women\'s health specialists'
    },
    {
      'name': 'Oncology',
      'icon': Icons.health_and_safety,
      'color': Colors.deepPurple,
      'description': 'Cancer treatment experts'
    },
  ];

  // Text editing controller for search
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredSpecialties = [];

  @override
  void initState() {
    super.initState();
    _filteredSpecialties = _specialties;
    _searchController.addListener(_filterSpecialties);
  }

  void _filterSpecialties() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredSpecialties = _specialties
          .where((specialty) => 
            specialty['name'].toLowerCase().contains(query) ||
            specialty['description'].toLowerCase().contains(query))
          .toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Medical Specialties',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search specialties...',
                prefixIcon: Icon(Icons.search, color: AppColors.primary),
                filled: true,
                fillColor: Colors.grey[100],
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

          // Specialties Grid
          Expanded(
            child: _filteredSpecialties.isEmpty
                ? _buildEmptyState()
                : GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    physics: const BouncingScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.8,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: _filteredSpecialties.length,
                    itemBuilder: (context, index) {
                      final specialty = _filteredSpecialties[index];
                      return _buildSpecialtyCard(specialty);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialtyCard(Map<String, dynamic> specialty) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DoctorsBySpecialtyScreen(specialty: specialty['name']),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: specialty['color'].withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: specialty['color'].withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Circular icon container
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: specialty['color'].withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                specialty['icon'],
                size: 40,
                color: specialty['color'],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              specialty['name'],
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: specialty['color'],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                specialty['description'],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No specialties found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different search term',
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}