import 'package:flutter/material.dart';
import '../../core/utils/constants.dart';
import '../../services/auth_service_api.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String userRole;

  const EditProfileScreen({
    super.key,
    required this.userData,
    required this.userRole,
  });

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fullNameController;
  late TextEditingController _emailController;
  
  // Patient specific controllers
  TextEditingController? _ageController;
  String? _selectedGender;
  
  bool _isLoading = false;
  String _errorMessage = '';
  bool _showError = false;
  
  // Define valid gender options
  final List<String> _genderOptions = ['Male', 'Female'];
  
  @override
  void initState() {
    super.initState();
    
    // Initialize basic controllers
    _fullNameController = TextEditingController(text: widget.userData['full_name'] ?? '');
    _emailController = TextEditingController(text: widget.userData['email'] ?? '');
    
    // Initialize patient-specific controllers
    if (widget.userRole == 'patient') {
      _ageController = TextEditingController(
        text: widget.userData['age'] != null ? widget.userData['age'].toString() : ''
      );
      
      // Check if the gender from userData is in our valid options
      String? userGender = widget.userData['gender'];
      if (userGender != null && _genderOptions.contains(userGender)) {
        _selectedGender = userGender;
      } else {
        // Default to null if not valid
        _selectedGender = null;
      }
      
      print("Initial gender value: $_selectedGender");
    }
  }
  
  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _ageController?.dispose();
    super.dispose();
  }
  
  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _showError = false;
      });
      
      try {
        print("Starting profile update process");
        
        // First update basic user info
        final updatedUserData = await ApiService.updateUserProfile(
          fullName: _fullNameController.text,
          email: _emailController.text,
        );
        
        print("User profile updated: ${updatedUserData.toString()}");
        
        // Then update patient-specific info if needed
        if (widget.userRole == 'patient') {
          final userId = await ApiService.getCurrentUserId();
          
          if (userId != null) {
            print("Updating patient profile with gender: $_selectedGender");
            
            final updatedPatientData = await ApiService.updatePatientProfile(
              userId: userId,
              age: _ageController != null && _ageController!.text.isNotEmpty 
                  ? int.tryParse(_ageController!.text) 
                  : null,
              gender: _selectedGender,
            );
            
            print("Patient profile updated: ${updatedPatientData.toString()}");
          } else {
            print("Could not update patient profile: User ID is null");
          }
        }
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Navigate back with updated data
          Navigator.pop(context, true); // true indicates refresh is needed
        }
      } catch (e) {
        print("Error updating profile: $e");
        if (mounted) {
          setState(() {
            _errorMessage = 'Failed to update profile: $e';
            _showError = true;
            _isLoading = false;
          });
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Edit Your Profile',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Update your personal information',
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Error message
                    if (_showError)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red.shade700),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'An error occurred, but your profile will be updated locally.',
                                style: TextStyle(color: Colors.red.shade700),
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    // Full Name Field
                    _buildTextField(
                      controller: _fullNameController,
                      label: 'Full Name',
                      prefixIcon: Icons.person,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your full name';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Email Field
                    _buildTextField(
                      controller: _emailController,
                      label: 'Email Address',
                      prefixIcon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!value.contains('@') || !value.contains('.')) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    
                    // Patient-specific fields
                    if (widget.userRole == 'patient') ...[
                      const SizedBox(height: 20),
                      
                      // Age field
                      _buildTextField(
                        controller: _ageController!,
                        label: 'Age',
                        prefixIcon: Icons.cake,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final age = int.tryParse(value);
                            if (age == null || age <= 0 || age > 120) {
                              return 'Please enter a valid age';
                            }
                          }
                          return null; // Optional field
                        },
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Gender dropdown - FIXED VERSION
                      DropdownButtonFormField<String>(
                        value: _selectedGender,
                        decoration: InputDecoration(
                          labelText: 'Gender',
                          prefixIcon: const Icon(Icons.person_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: _genderOptions.map((String gender) {
                          return DropdownMenuItem<String>(
                            value: gender,
                            child: Text(gender),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          print("Gender changed to: $newValue");
                          setState(() {
                            _selectedGender = newValue;
                          });
                        },
                        hint: const Text("Select gender"),
                        isExpanded: true,
                      ),
                    ],
                    
                    const SizedBox(height: 32),
                    
                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _updateProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                'Save Changes',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
  
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData prefixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(prefixIcon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
      validator: validator,
    );
  }
}