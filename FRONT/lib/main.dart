import 'package:flutter/material.dart';
import 'package:my_app/admin/admin_home_page.dart';
import 'package:my_app/views/auth/login_screen1.dart';
import 'package:my_app/views/auth/register_screen.dart';
import 'package:my_app/views/auth/welkoming.dart';
import 'package:my_app/views/chat/chatlTestScreen.dart';
import 'package:my_app/views/doctors/doctor_consultation_screen.dart';
import 'package:my_app/views/doctors/doctor_home_screen.dart';
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
      home: ConsultationChatScreen(receiverName: 'Othmane', receiverTitle: 'Dr ', isDoctor: true, consultationTime: DateTime(2024, 4, 4, 21, 8),consultationDuration:  const Duration(minutes: 30),), // Set the DoctorConsultationScreen as the home screen
    );             
  }  
} 