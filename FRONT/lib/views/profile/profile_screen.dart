import 'package:flutter/material.dart';
import '../../core/utils/constants.dart';
import '../../services/auth_service_api.dart';
import '../../widgets/custom_button.dart';
import 'ChangePasswordScreen .dart';
import 'EditProfileScreen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _userData = {};
  String _userRole = 'user';
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }
  
  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    
    try {
      // Get user role to determine what data to fetch
      final userRole = await ApiService.getUserRole();
      
      if (userRole != null) {
        setState(() => _userRole = userRole);
      }
      
      // Get user full name and email from secure storage first
      final fullName = await ApiService.getUserFullName();
      final email = await ApiService.getUserEmail();
      
      // Initialize user data with basic info
      Map<String, dynamic> userData = {
        'full_name': fullName ?? 'User',
        'email': email ?? 'email@example.com',
      };
      
      // Get additional info based on role
      Map<String, dynamic> additionalInfo = {};
      
      if (_userRole == 'doctor') {
        additionalInfo = await _getDoctorInfo();
      } else if (_userRole == 'patient') {
        additionalInfo = await _getPatientInfo();
      }
      
      // Merge the basic info with role-specific info
      userData.addAll(additionalInfo);
      
      setState(() {
        _userData = userData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Error loading profile data: $e');
    }
  }
  
  // Get additional doctor info - IMPROVED VERSION
  Future<Map<String, dynamic>> _getDoctorInfo() async {
    // Default values to use if API call fails or returns incomplete data
    final Map<String, dynamic> defaultDoctorInfo = {
      'specialty': 'General Practice',
      'hospital': 'Not specified',
      'is_verified': false,
    };
    
    try {
      // Fetch doctor profile from API
      final doctorProfile = await ApiService.getDoctorProfile();
      
      // Check if doctorProfile is null or empty
      if (doctorProfile == null || doctorProfile.isEmpty) {
        print('Doctor profile data is null or empty');
        return defaultDoctorInfo;
      }
      
      // Return formatted doctor info with proper null checking
      return {
        'specialty': doctorProfile['specialties'] ?? defaultDoctorInfo['specialty'],
        'hospital': doctorProfile['hospital'] ?? defaultDoctorInfo['hospital'],
        'is_verified': doctorProfile['is_verified'] ?? defaultDoctorInfo['is_verified'],
      };
    } catch (e) {
      print('Error loading doctor info: $e');
      _showErrorSnackBar('Error loading doctor info: $e');
      return defaultDoctorInfo;
    }
  }
  
  // Get additional patient info
  Future<Map<String, dynamic>> _getPatientInfo() async {
    try {
      // Fetch patient profile from API
      final patientId = await ApiService.getCurrentUserId();
      
      if (patientId == null) {
        throw Exception('Patient ID not found');
      }
      
      // Use the patientId to fetch the patient profile
      final response = await ApiService.getPatientProfile(patientId);
      
      // Return formatted patient info
      return {
        'age': response['age'] ?? 'Not specified',
        'gender': response['gender'] ?? 'Not specified',
        'patient_id': patientId,
        'created_at': response['created_at'] ?? '',
      };
    } catch (e) {
      print('Error loading patient info: $e');
      _showErrorSnackBar('Error loading patient info: $e');
      return {};
    }
  }
  
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
  
  // Handle logout functionality
  Future<void> _handleLogout() async {
    setState(() => _isLoading = true);
    
    try {
      await ApiService.clearAuthData();
      
      // Navigate to login screen after successful logout
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      _showErrorSnackBar('Error logging out: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUserData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildProfileHeader(),
                    const SizedBox(height: 20),
                    Text(
                      _userData['full_name'] ?? 'User',
                      style: AppTextStyles.heading,
                    ),
                    Text(
                      _getRoleDisplayText(),
                      style: AppTextStyles.body,
                    ),
                    const SizedBox(height: 30),
                    
                    _buildProfileSection("Personal Information", [
                      _buildInfoRow(Icons.person, "Full Name", _userData['full_name'] ?? 'User'),
                      _buildInfoRow(Icons.email, "Email", _userData['email'] ?? 'email@example.com'),
                      if (_userRole == 'doctor') ...[
                        _buildInfoRow(Icons.medical_services, "Specialty", _userData['specialty'] ?? 'General Practice'),
                        _buildInfoRow(Icons.local_hospital, "Hospital", _userData['hospital'] ?? 'City Hospital'),
                        _buildInfoRow(
                          Icons.verified_user, 
                          "Verification Status", 
                          _userData['is_verified'] == true ? 'Verified' : 'Pending Verification'
                        ),
                      ],
                      if (_userRole == 'patient') ...[
                        _buildInfoRow(Icons.cake, "Age", _userData['age']?.toString() ?? 'Not specified'),
                        _buildInfoRow(Icons.person_outline, "Gender", _userData['gender'] ?? 'Not specified'),
                        if (_userData['created_at'] != null && _userData['created_at'].toString().isNotEmpty)
                          _buildInfoRow(
                            Icons.calendar_today, 
                            "Member Since", 
                            _formatDate(_userData['created_at'])
                          ),
                      ],
                    ]),
                    
                    const SizedBox(height: 24),
                    _buildProfileSection("Security", [
                      _buildActionRow(Icons.lock, "Change Password", () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ChangePasswordScreen(),
                          ),
                        );
                      }),
                      _buildActionRow(Icons.security, "Two-Factor Authentication", () {
                        // Add 2FA functionality
                      }),
                    ]),
                    
                    const SizedBox(height: 24),
                    if (_userRole == 'doctor') ...[
                      _buildProfileSection("Doctor Settings", [
                        _buildActionRow(Icons.event_available, "Manage Availability", () {
                          // Navigate to availability management
                        }),
                        _buildActionRow(Icons.pending_actions, "Manage Consultations", () {
                          // Navigate to consultation management
                        }),
                      ]),
                      const SizedBox(height: 24),
                    ],
                    
                    if (_userRole == 'patient') ...[
                      _buildProfileSection("Patient Options", [
                        _buildActionRow(Icons.medical_services, "My Consultations", () {
                          // Navigate to patient consultations
                        }),
                        _buildActionRow(Icons.history, "Medical History", () {
                          // Navigate to medical history
                        }),
                      ]),
                      const SizedBox(height: 24),
                    ],
                    
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: CustomButton(
                        text: "Log Out",
                        onPressed: _handleLogout,
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }
  
  String _formatDate(dynamic dateString) {
    try {
      if (dateString == null) return 'Not available';
      
      final DateTime date = DateTime.parse(dateString.toString());
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      print('Error formatting date: $e');
      return 'Invalid date';
    }
  }
  
  String _getRoleDisplayText() {
    switch (_userRole) {
      case 'doctor':
        return 'Medical Professional';
      case 'patient':
        return 'Patient';
      case 'admin':
        return 'Administrator';
      default:
        return 'User';
    }
  }
  
  Widget _buildProfileHeader() {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: AppColors.primary.withOpacity(0.2),
          child: Text(
            _getInitials(_userData['full_name'] ?? 'U'),
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () {
              // Navigate to edit profile screen
              _navigateToEditProfile();
            },
          ),
        ),
      ],
    );
  }
  
  Future<void> _navigateToEditProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(
          userData: _userData,
          userRole: _userRole,
        ),
      ),
    );
    
    // If the result is true, refresh the profile data
    if (result == true) {
      _loadUserData();
    }
  }
  
  String _getInitials(String fullName) {
    List<String> names = fullName.split(' ');
    String initials = '';
    
    for (var name in names) {
      if (name.isNotEmpty) {
        initials += name[0];
      }
      
      if (initials.length >= 2) break;
    }
    
    return initials.toUpperCase();
  }

  Widget _buildProfileSection(String title, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title, 
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold
              )
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label, 
                  style: TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 12
                  )
                ),
                Text(
                  value, 
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500
                  )
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 16),
            Text(label, style: const TextStyle(fontSize: 16)),
            const Spacer(),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}