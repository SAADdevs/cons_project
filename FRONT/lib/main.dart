import 'package:flutter/material.dart';
import 'package:my_app/admin/admin_home_page.dart';
import 'package:my_app/views/auth/register_screen.dart';
import 'package:my_app/views/doctors/doctor_consultation_screen.dart';
import 'package:my_app/views/doctors/doctor_home_screen.dart';
import 'package:my_app/views/auth/login_screen.dart';
import 'package:my_app/views/patients/PatientHomeScreen.dart';// Import the DoctorConsultationScreen

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
      home: LoginScreen(), // Set the DoctorConsultationScreen as the home screen
    );             
  }  
} 