import 'package:flutter/material.dart';
import 'package:my_app/services/auth_service_api.dart';
import 'package:my_app/views/auth/login_screen.dart';
import '../../routes/app_routes.dart';
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
  bool _obscurePassword = true;

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
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo or App Icon
                Icon(
                  Icons.medical_services,
                  size: 80,
                  color: Theme.of(context).primaryColor,
                ),
                
                const SizedBox(height: 24),
                
                // Welcome Text
                Text(
                  "Create Account",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 8),
                
                // Subtitle
                const Text(
                  "Start your health journey",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 40),
                
                // Doctor Toggle
                SwitchListTile(
                  title: const Text(
                    "I am a medical professional",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  value: _isDoctor,
                  activeColor: Theme.of(context).primaryColor,
                  onChanged: (v) => setState(() => _isDoctor = v),
                ),

                const SizedBox(height: 20),

                // Registration Form
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Full Name Field
                      TextFormField(
                        controller: _nameController,
                        decoration: _inputDecoration(
                          context, 
                          labelText: "Full Name", 
                          hintText: "Enter your full name",
                          prefixIcon: Icons.person_outline,
                        ),
                        validator: (value) => value!.isEmpty 
                          ? "Please enter your full name" 
                          : null,
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Email Field
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: _inputDecoration(
                          context, 
                          labelText: "Email Address", 
                          hintText: "example@email.com",
                          prefixIcon: Icons.email_outlined,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please enter your email";
                          }
                          if (!value.contains('@')) {
                            return "Please enter a valid email";
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Conditional Fields based on Role
                      if (_isDoctor) ...[
                        // License Number Field
                        TextFormField(
                          controller: _licenseController,
                          decoration: _inputDecoration(
                            context, 
                            labelText: "License Number", 
                            hintText: "Enter your medical license number",
                            prefixIcon: Icons.badge_outlined,
                          ),
                          validator: (value) => value!.isEmpty 
                            ? "Please enter your license number" 
                            : null,
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Specialty Field
                        TextFormField(
                          controller: _specialtyController,
                          decoration: _inputDecoration(
                            context, 
                            labelText: "Medical Specialty", 
                            hintText: "Enter your medical specialty",
                            prefixIcon: Icons.medical_services_outlined,
                          ),
                          validator: (value) => value!.isEmpty 
                            ? "Please enter your medical specialty" 
                            : null,
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Hospital/Clinic Field
                        TextFormField(
                          controller: _hospitalController,
                          decoration: _inputDecoration(
                            context, 
                            labelText: "Hospital/Clinic", 
                            hintText: "Enter your hospital or clinic name",
                            prefixIcon: Icons.local_hospital_outlined,
                          ),
                          validator: (value) => value!.isEmpty 
                            ? "Please enter your hospital/clinic" 
                            : null,
                        ),
                      ] else ...[
                        // Age Field for Patients
                        TextFormField(
                          controller: _ageController,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration(
                            context, 
                            labelText: "Age", 
                            hintText: "Enter your age",
                            prefixIcon: Icons.calendar_today_outlined,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Please enter your age";
                            }
                            final age = int.tryParse(value);
                            if (age == null || age < 0 || age > 120) {
                              return "Please enter a valid age";
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Gender Field for Patients
                        TextFormField(
                          controller: _genderController,
                          decoration: _inputDecoration(
                            context, 
                            labelText: "Gender", 
                            hintText: "Enter your gender",
                            prefixIcon: Icons.person_outline,
                          ),
                          validator: (value) => value!.isEmpty 
                            ? "Please enter your gender" 
                            : null,
                        ),
                      ],
                      
                      const SizedBox(height: 20),
                      
                      // Password Field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: "Password",
                          hintText: "Enter your password",
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword 
                                ? Icons.visibility_off 
                                : Icons.visibility,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Theme.of(context).primaryColor,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          contentPadding: const EdgeInsets.all(16),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please enter your password";
                          }
                          if (value.length < 6) {
                            return "Password must be at least 6 characters";
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Register Button
                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleRegister,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                          minimumSize: const Size(double.infinity, 50),
                          disabledBackgroundColor: Colors.grey.shade300,
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
                                "REGISTER",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Login Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Already have an account?",
                            style: TextStyle(color: Colors.grey),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LoginScreen()
                                ),
                              );
                            },
                            child: Text(
                              "Login",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper method for input decoration
  InputDecoration _inputDecoration(
    BuildContext context, {
    required String labelText, 
    required String hintText,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: Icon(prefixIcon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Theme.of(context).primaryColor,
          width: 2,
        ),
      ),
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: const EdgeInsets.all(16),
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