class HealthAdvice {
  final int id;
  final String title;
  final String content;
  final String category;
  final DateTime createdAt;
  final String? doctorName;
  final String? doctorSpecialty;

  HealthAdvice({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.createdAt,
    this.doctorName,
    this.doctorSpecialty,
  });

  // Factory constructor to create a HealthAdvice from a JSON map
  factory HealthAdvice.fromJson(Map<String, dynamic> json) {
    return HealthAdvice(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      category: json['category'] ?? 'General',
      createdAt: json['created_at'] != null 
        ? DateTime.parse(json['created_at']) 
        : DateTime.now(),
      doctorName: json['doctor_name'],
      doctorSpecialty: json['doctor_specialty'],
    );
  }

  // Method to convert HealthAdvice to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'category': category,
      'created_at': createdAt.toIso8601String(),
      'doctor_name': doctorName,
      'doctor_specialty': doctorSpecialty,
    };
  }
}