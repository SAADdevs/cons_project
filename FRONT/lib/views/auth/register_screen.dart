import 'package:flutter/material.dart';
import 'package:my_app/services/auth_service_api.dart';
import 'package:my_app/views/auth/login_screen.dart';
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

  final _ageController = TextEditingController(); // Add this line
  final _genderController = TextEditingController(); // Add this line
  
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
  _ageController.dispose(); // Add this line
  _genderController.dispose(); // Add this line
  super.dispose();
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 40),
            // Image.asset('assets/icons/medical_services.svg', height: 100),
            const SizedBox(height: 30),
            Text("Create Account", style: AppTextStyles.heading),
            const SizedBox(height: 10),
            Text("Start your health journey", style: AppTextStyles.body),
            const SizedBox(height: 30),
            // Doctor Toggle
            SwitchListTile(
              title: const Text("I am a medical professional"),
              value: _isDoctor,
              activeColor: AppColors.primary,
              onChanged: (v) => setState(() => _isDoctor = v),
            ),

            Form(
  key: _formKey,
  child: Column(
    children: [
      _buildInput(_nameController, "Full Name", Icons.person),
      _buildInput(_emailController, "Email", Icons.email, TextInputType.emailAddress),
      
      if (_isDoctor) ...[
        _buildInput(_licenseController, "License Number", Icons.badge),
        _buildInput(_specialtyController, "Medical Specialty", Icons.medical_services),
        _buildInput(_hospitalController, "Hospital/Clinic", Icons.local_hospital),
      ] else ...[
        _buildInput(_ageController, "Age", Icons.calendar_today, TextInputType.number),
        _buildInput(_genderController, "Gender", Icons.person_outline),
      ],

      // Password Field
      PasswordField(
        controller: _passwordController,
        label: "Password",
        showPassword: _showPassword,
        toggle: () => setState(() => _showPassword = !_showPassword),
      ),

      const SizedBox(height: 20),
      AuthButton(
        color: Colors.amber,
        text: 'Create Account',
        onPressed: _handleRegister,
        isLoading: _isLoading,
      ),
      TextButton(
        onPressed: () => Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const  LoginScreen()),
),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
        ),
        child: const Text("Already have an account? Login"),
      ),
    ],
  ),
),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(TextEditingController controller, String label, IconData icon, 
                    [TextInputType? type]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppColors.primary),
          border: OutlineInputBorder(),
        ),
        validator: (value) => value!.isEmpty ? '$label is required' : null,
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
        age: _isDoctor ? null : int.tryParse(_ageController.text), // Pass age for patients
        gender: _isDoctor ? null : _genderController.text, // Pass gender for patients
      );

      if (response.containsKey('user')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Registration successful!")),
        );
        //Navigator.pushNamed(context, AppRoutes.login);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const  LoginScreen()),
);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? "Registration failed")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
}

class PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool showPassword;
  final VoidCallback toggle;

  const PasswordField({super.key, 
    required this.controller,
    required this.label,
    required this.showPassword,
    required this.toggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        obscureText: !showPassword,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(Icons.lock, color: AppColors.primary),
          suffixIcon: IconButton(icon: Icon(showPassword ? Icons.visibility : Icons.visibility_off), onPressed: toggle),
          border: OutlineInputBorder(),
        ),
        validator: (value) => value!.length < 6 ? 'Minimum 6 characters' : null,
      ),
    );
  }
}