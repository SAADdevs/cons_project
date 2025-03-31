import 'package:flutter/foundation.dart';

class Doctor {
  final int id;
  final int userId;
  final String name;
  final String specialty;
  final bool isVerified;
  final bool isAvailable;
  final String? hospital;

  Doctor({
    required this.id,
    required this.userId,
    required this.name,
    required this.specialty,
    required this.isVerified,
    required this.isAvailable,
    this.hospital,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    try {
      // Add debug logs to see what we're getting
      debugPrint('Processing doctor JSON: ${json.toString().substring(0, min(100, json.toString().length))}...');
      
      return Doctor(
        id: json['id'] ?? 0,
        userId: json['user_id'] ?? 0,
        // Try to get name from full_name first, then fall back to other possibilities
        name: json['full_name'] ?? json['name'] ?? 'Unknown Doctor',
        // For specialty, use specialties field if available
        specialty: json['specialties'] ?? json['specialty'] ?? 'General',
        isVerified: json['is_verified'] ?? false,
        isAvailable: json['is_available'] ?? false,
        hospital: json['hospital'],
      );
    } catch (e) {
      debugPrint('Error parsing doctor: $e');
      return Doctor(
        id: 0,
        userId: 0,
        name: 'Error',
        specialty: 'Error',
        isVerified: false,
        isAvailable: false,
      );
    }
  }
  
  // Helper method to limit string length for logging
  static int min(int a, int b) => a < b ? a : b;
}