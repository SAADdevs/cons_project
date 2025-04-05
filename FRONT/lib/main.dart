import 'package:flutter/material.dart';
import 'package:my_app/views/auth/login_screen1.dart';
// Import the DoctorConsultationScreen

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Doctor Consultation App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const LoginScreen(),// Set the DoctorConsultationScreen as the home screen
    );             
  }  
} 