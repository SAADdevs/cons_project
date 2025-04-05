// lib/core/models/doctor_model.dart
import 'package:flutter/foundation.dart';

class Doctor {
  final int id;
  final int userId;
  final String name;
  final String specialty;
  final bool isVerified;
  final bool isAvailable;
  final String? hospital;
  final String? imageUrl;
  final double? rating;
  final String? experience;
  final int? patientsCount;

  Doctor({
    required this.id,
    required this.userId,
    required this.name,
    required this.specialty,
    required this.isVerified,
    required this.isAvailable,
    this.hospital,
    this.imageUrl,
    this.rating,
    this.experience,
    this.patientsCount,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    try {
      return Doctor(
        id: json['id'] is String ? int.parse(json['id']) : (json['id'] ?? 0),
        userId: json['user_id'] is String ? int.parse(json['user_id']) : (json['user_id'] ?? 0),
        // Get name from full_name field or related fields
        name: json['full_name'] ?? json['doctor_name'] ?? 'Unknown Doctor',
        // Get specialty
        specialty: json['specialties'] ?? json['specialty'] ?? 'General',
        isVerified: json['is_verified'] ?? false,
        isAvailable: json['is_available'] ?? false,
        hospital: json['hospital'],
        imageUrl: json['image_url'],
        rating: json['rating'] != null ? (json['rating'] is double ? json['rating'] : double.tryParse(json['rating'].toString())) : null,
        experience: json['experience'],
        patientsCount: json['patients_count'] is String ? int.tryParse(json['patients_count']) : json['patients_count'],
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
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'full_name': name,
      'specialty': specialty,
      'is_verified': isVerified,
      'is_available': isAvailable,
      'hospital': hospital,
      'image_url': imageUrl,
      'rating': rating,
      'experience': experience,
      'patients_count': patientsCount,
    };
  }
}