// lib/routes/app_routes.dart

class AppRoutes {
  // Authentication Routes
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  // Doctor Routes
  static const String doctorHome = '/doctor/home';
  static const String doctorProfile = '/doctor/profile';
  static const String doctorConsultations = '/doctor/consultations';
  static const String upcomingAppointments = '/doctor/appointments';
  static const String doctorChat = '/doctor/chat';
  static const String postAdvice = '/doctor/advice';
  static const String doctorStatistics = '/doctor/statistics';

  // Patient Routes
  static const String patientHome = '/patient/home';
  static const String patientProfile = '/patient/profile';
  static const String patientConsultations = '/patient/consultations';

  // Admin Routes
  static const String adminHome = '/admin/home';
  static const String adminDoctors = '/admin/doctors';
  static const String adminAdvice = '/admin/advice';
}