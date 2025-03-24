// core/models/healthAdvice.dart
class HealthAdvice {
  final int id;
  final int doctorId;
  final String title;
  final String content;
  final String category;
  final bool isApproved;
  final DateTime createdAt;
  final String? doctorName;
  final String? doctorSpecialty;

  HealthAdvice({
    required this.id,
    required this.doctorId,
    required this.title,
    required this.content,
    required this.category,
    required this.isApproved,
    required this.createdAt,
    this.doctorName,
    this.doctorSpecialty,
  });

  factory HealthAdvice.fromJson(Map<String, dynamic> json) {
    return HealthAdvice(
      id: json['id'] ?? 0,
      doctorId: json['doctor_id'] ?? 0,
      title: json['title'] ?? 'Untitled',
      content: json['advice_text'] ?? '',
      category: json['category'] ?? 'General',
      isApproved: json['is_approved'] ?? false,
      createdAt: json['created_at'] != null 
        ? DateTime.parse(json['created_at']) 
        : DateTime.now(),
      doctorName: json['doctor_name'],
      doctorSpecialty: json['specialties'],
    );
  }
}