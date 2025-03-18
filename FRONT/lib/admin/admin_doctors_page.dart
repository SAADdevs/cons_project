import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AdminDoctorsPage extends StatefulWidget {
  const AdminDoctorsPage({Key? key}) : super(key: key);

  @override
  State<AdminDoctorsPage> createState() => _AdminDoctorsPageState();
}

class _AdminDoctorsPageState extends State<AdminDoctorsPage> {
  bool _isLoading = true;
  List<dynamic> _allDoctors = [];
  String _searchQuery = '';
  
  // Map to store user names - will be populated dynamically
  Map<int, String> _userNames = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  // Load both doctors and users
  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // First load doctors
      final doctorResponse = await http.get(Uri.parse('http://192.168.158.178:5000/api/doctors'));
      
      if (doctorResponse.statusCode != 200) {
        setState(() => _isLoading = false);
        _showSnackBar('Failed to load doctors: ${doctorResponse.statusCode}');
        return;
      }
      
      final doctorsData = json.decode(doctorResponse.body);
      
      // Then load users to get names
      final userResponse = await http.get(Uri.parse('http://192.168.158.178:5000/api/with-names'));
      
      if (userResponse.statusCode != 200) {
        setState(() => _isLoading = false);
        _showSnackBar('Failed to load user names: ${userResponse.statusCode}');
        return;
      }
      
      final doctorsWithNames = json.decode(userResponse.body);
      
      // Create a map of user IDs to names
      final Map<int, String> userNameMap = {};
      for (var doctor in doctorsWithNames) {
        if (doctor['user_id'] != null && doctor['full_name'] != null) {
          userNameMap[doctor['user_id']] = doctor['full_name'];
        }
      }
      
      setState(() {
        _userNames = userNameMap;
        _allDoctors = doctorsData;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() => _isLoading = false);
      _showSnackBar('Error: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  // Filter doctors based on search query
  List<dynamic> get _filteredDoctors {
    if (_searchQuery.isEmpty) return _allDoctors;
    
    return _allDoctors.where((doctor) {
      final name = _getDoctorName(doctor['user_id']).toLowerCase();
      final specialty = (doctor['specialties'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery.toLowerCase()) || 
             specialty.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  Future<void> _toggleVerification(int doctorId, bool shouldVerify) async {
    final action = shouldVerify ? 'Verifying' : 'Unverifying';
    _showSnackBar('$action doctor...');
    
    try {
      final endpoint = shouldVerify ? 'approve' : 'unverify';
      final url = Uri.parse('http://192.168.158.178:5000/api/doctors/$endpoint/$doctorId');
      
      final response = await http.put(url);
      
      if (response.statusCode == 200) {
        _showSnackBar('Doctor ${shouldVerify ? 'verified' : 'unverified'} successfully');
        _loadData();
      } else {
        _showSnackBar('Operation failed: ${response.statusCode}');
      }
    } catch (e) {
      _showSnackBar('Error: $e');
    }
  }

  // Get doctor's name from our map
  String _getDoctorName(int userId) {
    return _userNames[userId] ?? 'Doctor $userId';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Manage Doctors'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search doctors...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          
          // Stats cards
          if (!_isLoading)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      title: 'Total',
                      count: _allDoctors.length,
                      icon: Icons.people,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      title: 'Pending',
                      count: _allDoctors.where((d) => d['is_verified'] != true).length,
                      icon: Icons.pending_actions,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      title: 'Verified',
                      count: _allDoctors.where((d) => d['is_verified'] == true).length,
                      icon: Icons.verified_user,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          
          // Main content
          Expanded(
            child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredDoctors.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty 
                              ? 'No doctors found' 
                              : 'No doctors match your search',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredDoctors.length,
                      itemBuilder: (context, index) {
                        final doctor = _filteredDoctors[index];
                        final doctorName = _getDoctorName(doctor['user_id']);
                        final isVerified = doctor['is_verified'] == true;
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {}, // For potential profile view
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  // Doctor avatar
                                  CircleAvatar(
                                    radius: 28,
                                    backgroundColor: isVerified 
                                        ? Colors.green.withOpacity(0.2)
                                        : Colors.orange.withOpacity(0.2),
                                    child: Text(
                                      doctorName.isNotEmpty ? doctorName[0].toUpperCase() : '?',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: isVerified ? Colors.green[800] : Colors.orange[800],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  
                                  // Doctor info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          doctorName,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Specialty: ${doctor['specialties'] ?? 'General'}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        // Status chip
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: isVerified 
                                                ? Colors.green.withOpacity(0.2) 
                                                : Colors.orange.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            isVerified ? 'Verified' : 'Pending Approval',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: isVerified ? Colors.green[800] : Colors.orange[800],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // Verification action button
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isVerified ? Colors.orange : Colors.green,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    ),
                                    onPressed: () => _toggleVerification(doctor['id'], !isVerified),
                                    child: Text(isVerified ? 'Unverify' : 'Verify'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
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
}