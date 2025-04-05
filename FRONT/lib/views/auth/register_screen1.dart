import 'package:flutter/material.dart';
import 'package:my_app/services/auth_service_api.dart';
import 'package:my_app/views/auth/login_screen1.dart';
import '../../routes/app_routes.dart';
import '../../widgets/auth_widgets.dart';
import '../../core/utils/constants.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  // Doctor-specific controllers
  final _licenseController = TextEditingController();
  final _specialtyController = TextEditingController();
  final _hospitalController = TextEditingController();

  final _ageController = TextEditingController();
  final _genderController = TextEditingController();
  
  bool _isDoctor = false;
  bool _isLoading = false;
  bool _showPassword = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _licenseController.dispose();
    _specialtyController.dispose();
    _hospitalController.dispose();
    _ageController.dispose();
    _genderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Arch-shaped top section
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ClipPath(
                clipper: ArchClipper(),
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.35,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF2196F3),
                        const Color(0xFF2196F3).withOpacity(0.9),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 2,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Health logo
            Positioned(
              top: MediaQuery.of(context).size.height * 0.08,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.medical_services,
                    size: 60,
                    color: Color(0xFF2196F3),
                  ),
                ),
              ),
            ),

            // Main content
            Positioned.fill(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.22),
                      
                      // Welcome text
                      const Center(
                        child: Text(
                          'Create Account',
                          style: TextStyle(
                            color: Color.fromARGB(255, 255, 255, 255),
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Center(
                        child: Text(
                          'Join HealthConnect today',
                          style: TextStyle(
                            color: Color.fromARGB(255, 255, 255, 255),
                            fontSize: 16,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Account Type Toggle
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            children: [
                              const Text(
                                'I am a medical professional',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Spacer(),
                              Switch(
                                value: _isDoctor,
                                activeColor: const Color(0xFF2196F3),
                                onChanged: (v) => setState(() => _isDoctor = v),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Register Card with proper spacing
                      Container(
                        margin: const EdgeInsets.only(top: 20),
                        child: Card(
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Full Name Input
                                  TextFormField(
                                    controller: _nameController,
                                    decoration: InputDecoration(
                                      labelText: 'Full Name',
                                      labelStyle: const TextStyle(color: Color(0xFF5A5A5A)),
                                      prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF5A5A5A)),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: Color(0xFF2196F3)),
                                      ),
                                    ),
                                    validator: (value) => value!.isEmpty ? 'Please enter your full name' : null,
                                  ),

                                  const SizedBox(height: 16),

                                  // Email Input
                                  TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    decoration: InputDecoration(
                                      labelText: 'Email',
                                      labelStyle: const TextStyle(color: Color(0xFF5A5A5A)),
                                      prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF5A5A5A)),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: Color(0xFF2196F3)),
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your email';
                                      }
                                      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                                      if (!emailRegex.hasMatch(value)) {
                                        return 'Please enter a valid email';
                                      }
                                      return null;
                                    },
                                  ),

                                  const SizedBox(height: 16),

                                  // Conditional Fields based on Doctor/Patient
                                  if (_isDoctor) ...[
                                    // License Number for Doctors
                                    TextFormField(
                                      controller: _licenseController,
                                      decoration: InputDecoration(
                                        labelText: 'License Number',
                                        labelStyle: const TextStyle(color: Color(0xFF5A5A5A)),
                                        prefixIcon: const Icon(Icons.badge_outlined, color: Color(0xFF5A5A5A)),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: const BorderSide(color: Color(0xFF2196F3)),
                                        ),
                                      ),
                                      validator: (value) => value!.isEmpty ? 'Please enter your license number' : null,
                                    ),
                                    const SizedBox(height: 16),

                                    // Specialty for Doctors
                                    TextFormField(
                                      controller: _specialtyController,
                                      decoration: InputDecoration(
                                        labelText: 'Medical Specialty',
                                        labelStyle: const TextStyle(color: Color(0xFF5A5A5A)),
                                        prefixIcon: const Icon(Icons.medical_services_outlined, color: Color(0xFF5A5A5A)),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: const BorderSide(color: Color(0xFF2196F3)),
                                        ),
                                      ),
                                      validator: (value) => value!.isEmpty ? 'Please enter your specialty' : null,
                                    ),
                                    const SizedBox(height: 16),

                                    // Hospital/Clinic for Doctors
                                    TextFormField(
                                      controller: _hospitalController,
                                      decoration: InputDecoration(
                                        labelText: 'Hospital/Clinic',
                                        labelStyle: const TextStyle(color: Color(0xFF5A5A5A)),
                                        prefixIcon: const Icon(Icons.local_hospital_outlined, color: Color(0xFF5A5A5A)),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: const BorderSide(color: Color(0xFF2196F3)),
                                        ),
                                      ),
                                      validator: (value) => value!.isEmpty ? 'Please enter your hospital/clinic' : null,
                                    ),
                                    const SizedBox(height: 16),
                                  ] else ...[
                                    // Age for Patients
                                    TextFormField(
                                      controller: _ageController,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        labelText: 'Age',
                                        labelStyle: const TextStyle(color: Color(0xFF5A5A5A)),
                                        prefixIcon: const Icon(Icons.calendar_today_outlined, color: Color(0xFF5A5A5A)),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: const BorderSide(color: Color(0xFF2196F3)),
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value!.isEmpty) return 'Please enter your age';
                                        final age = int.tryParse(value);
                                        if (age == null || age < 0 || age > 120) {
                                          return 'Please enter a valid age';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),

                                    // Gender for Patients
                                    TextFormField(
                                      controller: _genderController,
                                      decoration: InputDecoration(
                                        labelText: 'Gender',
                                        labelStyle: const TextStyle(color: Color(0xFF5A5A5A)),
                                        prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF5A5A5A)),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: const BorderSide(color: Color(0xFF2196F3)),
                                        ),
                                      ),
                                      validator: (value) => value!.isEmpty ? 'Please enter your gender' : null,
                                    ),
                                    const SizedBox(height: 16),
                                  ],

                                  // Password Input
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: !_showPassword,
                                    decoration: InputDecoration(
                                      labelText: 'Password',
                                      labelStyle: const TextStyle(color: Color(0xFF5A5A5A)),
                                      prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF5A5A5A)),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _showPassword 
                                            ? Icons.visibility 
                                            : Icons.visibility_off,
                                          color: const Color(0xFF5A5A5A),
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _showPassword = !_showPassword;
                                          });
                                        },
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: Color(0xFF2196F3)),
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter a password';
                                      }
                                      if (value.length < 6) {
                                        return 'Password must be at least 6 characters';
                                      }
                                      return null;
                                    },
                                  ),

                                  const SizedBox(height: 24),

                                  // Register Button
                                  ElevatedButton(
                                    onPressed: _isLoading ? null : _handleRegister,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF2196F3),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 4,
                                    ),
                                    child: _isLoading
                                      ? const CircularProgressIndicator(color: Colors.white)
                                      : const Text(
                                          'Create Account',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Login Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Already have an account? ",
                            style: TextStyle(color: Color(0xFF5A5A5A)),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => const LoginScreen()),
                              );
                            },
                            child: const Text(
                              'Login',
                              style: TextStyle(
                                color: Color(0xFF2196F3),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final String role = _isDoctor ? 'doctor' : 'patient';

      try {
        final response = await ApiService.register(
          fullName: _nameController.text,
          email: _emailController.text,
          password: _passwordController.text,
          role: role,
          IMPE: _isDoctor ? _licenseController.text : null,
          specialties: _isDoctor ? _specialtyController.text : null,
          hospital: _isDoctor ? _hospitalController.text : null,
          age: _isDoctor ? null : int.tryParse(_ageController.text),
          gender: _isDoctor ? null : _genderController.text,
        );

        if (response.containsKey('user')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Registration successful!"),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? "Registration failed"),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }
}

// Custom clipper for the arch shape (same as in LoginScreen)
class ArchClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height * 0.7);
    path.quadraticBezierTo(
      size.width / 2,
      size.height * 1.1,
      size.width,
      size.height * 0.7,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}