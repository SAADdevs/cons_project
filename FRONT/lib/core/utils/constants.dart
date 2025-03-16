// core/utils/constants.dart

import 'package:flutter/material.dart';

// core/utils/constants.dart
class AppColors {
static const Color primary = Color(0xFF4A90E2);
  static const Color primaryText = Color(0xFF2D3436);
  static const Color secondaryText = Color(0xFF636E72);
  static const Color scaffoldBackground = Color(0xFFF8F9FA);
  static const Color fieldBackground = Color(0xFFF5F5F5);
  static const Color error = Color(0xFFE74C3C);
  static const Color success = Color(0xFF2ECC71);

}

class Constants {
  static const String apiUrl = 'http://localhost:5000'; // Change to your actual API URL
  static const Color primaryColor = Color(0xFF4A90E2);
  
  // API endpoints
  static const String loginEndpoint = '/api/auth/login';
  static const String registerEndpoint = '/api/auth/register';
  static const String doctorConsultationsEndpoint = '/api/consultations/doctor';
  static const String updateConsultationStatusEndpoint = '/api/consultations/update-status';
  static const String updateDoctorAvailabilityEndpoint = '/api/doctors/availability';
}

class AppTextStyles {
  static TextStyle heading = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.primaryText,
  );

  static TextStyle body = TextStyle(
    fontSize: 16,
    color: AppColors.secondaryText,
  );

  static  TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
}
// core/utils/constants.dart
class AppIcons {
  static const IconData medicalServices = Icons.medical_services_outlined;
  static const IconData email = Icons.email_outlined;
  static const IconData lock = Icons.lock_outlined;
  static const IconData person = Icons.person_outlined;
  static const IconData phone = Icons.phone_outlined;
}

class AppImages {
  static const String userAvatar = 'assets/images/user_avatar.png';
}