import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:my_app/basrel.dart';
import 'package:my_app/services/auth_service_api.dart';

class AdminDoctorsPage extends StatefulWidget {
  const AdminDoctorsPage({Key? key}) : super(key: key);

  @override
  State<AdminDoctorsPage> createState() => _AdminDoctorsPageState();
}

class _AdminDoctorsPageState extends State<AdminDoctorsPage> {
  bool _isLoading = true;
  List<dynamic> _allDoctors = [];
  String _searchQuery = '';
  String _errorMessage = '';
  
  Map<int, String> _userNames = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final token = await ApiService.getAuthToken();
      
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final doctorResponse = await http.get(
        Uri.parse('$baseUrl/doctors'),
        headers: headers,
      );
      
      if (doctorResponse.statusCode != 200) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load doctors: ${doctorResponse.statusCode}';
        });
        _showSnackBar('Failed to load doctors: ${doctorResponse.statusCode}');
        return;
      }
      
      final doctorsData = json.decode(doctorResponse.body);
      
      final namesResponse = await http.get(
        Uri.parse('$baseUrl/doctors/get/with-names'),
        headers: headers,
      );
      
      if (namesResponse.statusCode != 200) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load user names: ${namesResponse.statusCode}';
          _allDoctors = doctorsData;
        });
        _showSnackBar('Failed to load user names: ${namesResponse.statusCode}');
        return;
      }
      
      final namesData = json.decode(namesResponse.body);
      
      final Map<int, String> userNameMap = {};
      for (var doctor in namesData) {
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
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: $e';
      });
      _showSnackBar('Error: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

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
      final url = Uri.parse('$baseUrl/doctors/$endpoint/$doctorId');
      
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

  String _getDoctorName(int userId) {
    String? fullName = _userNames[userId];
    return fullName ?? 'Doctor $userId';
  }

  // Doctor Details Popup
  void _showDoctorDetails(dynamic doctor) {
    final doctorName = _getDoctorName(doctor['user_id']);
    final isVerified = doctor['is_verified'] == true;
    final license = doctor['IMPE'] ?? 'Not specified';
    final specialty = doctor['specialties'] ?? 'General';
    final hospital = doctor['hospital'] ?? 'Not specified';
    final status = isVerified ? 'Verified' : 'Pending Verification';
    final availability = doctor['is_available'] == true ? 'Available' : 'Not available';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(doctorName, style: const TextStyle(fontSize: 22)),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // License Information
                _buildDetailSection(
                  icon: Icons.medical_information,
                  title: 'Medical License (IMPE)',
                  content: license,
                  isImportant: true,
                ),
                
                // Specialty Information
                _buildDetailSection(
                  icon: Icons.medical_services,
                  title: 'Specialty',
                  content: specialty,
                  isImportant: true,
                ),
                
                const SizedBox(height: 16),
                
                // Other Details
                _buildDetailRow(Icons.person, 'Doctor ID:', doctor['id'].toString()),
                _buildDetailRow(Icons.work, 'Hospital:', hospital),
                _buildDetailRow(Icons.verified, 'Status:', status),
                _buildDetailRow(Icons.event_available, 'Availability:', availability),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _toggleVerification(doctor['id'], !isVerified);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isVerified ? Colors.orange : Colors.green,
              ),
              child: Text(isVerified ? 'Unverify' : 'Verify'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailSection({
    required IconData icon,
    required String title,
    required String content,
    bool isImportant = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isImportant ? Colors.blue.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isImportant ? Colors.blue.withOpacity(0.3) : Colors.grey.withOpacity(0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: isImportant ? Colors.blue : Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isImportant ? Colors.blue : Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: isImportant ? 16 : 14,
                    color: isImportant ? Colors.blue[800] : Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
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
          
          if (_errorMessage.isNotEmpty && !_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(8),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.5)),
                ),
                child: Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ),
          
          if (!_isLoading)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _buildStatCard(
                    title: 'Total',
                    count: _allDoctors.length,
                    icon: Icons.people,
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    title: 'Pending',
                    count: _allDoctors.where((d) => d['is_verified'] != true).length,
                    icon: Icons.pending_actions,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    title: 'Verified',
                    count: _allDoctors.where((d) => d['is_verified'] == true).length,
                    icon: Icons.verified_user,
                    color: Colors.green,
                  ),
                ],
              ),
            ),
          
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
                            onTap: () => _showDoctorDetails(doctor),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
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
    return Expanded(
      child: Container(
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
     ),
);
}
}