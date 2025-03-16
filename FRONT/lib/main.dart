import 'package:flutter/material.dart';
import 'package:my_app/views/doctors/doctor_consultation_screen.dart';
import 'package:my_app/views/auth/login_screen.dart';// Import the DoctorConsultationScreen

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
      home:const DoctorConsultationScreen(), // Set the DoctorConsultationScreen as the home screen
    );
  }
}