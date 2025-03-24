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
      isApproved: json['is_approved'] ?? true,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      doctorName: json['doctor_name'] ?? 'Unknown Doctor',
      doctorSpecialty: json['specialties'] ?? '',
    );
  }

  void debugPrint() {
    print('HealthAdvice: {');
    print('  id: $id,');
    print('  doctorId: $doctorId,');
    print('  title: $title,');
    print('  content: $content,');
    print('  category: $category,');
    print('  isApproved: $isApproved,');
    print('  createdAt: $createdAt,');
    print('  doctorName: $doctorName,');
    print('  doctorSpecialty: $doctorSpecialty');
    print('}');
  }

  // Helper method to parse from API response
  static List<HealthAdvice> parseFromJson(List<dynamic> jsonList) {
    final List<HealthAdvice> tips = [];
    
    for (var item in jsonList) {
      try {
        print('Processing item: $item');
        final tip = HealthAdvice(
          id: item['id'] ?? 0,
          doctorId: item['doctor_id'] ?? 0,
          title: item['title'] ?? 'Untitled',
          content: item['advice_text'] ?? '',
          category: item['category'] ?? 'General',
          isApproved: true, // If fetched from approved endpoint
          createdAt: item['created_at'] != null 
              ? DateTime.parse(item['created_at']) 
              : DateTime.now(),
          doctorName: item['doctor_name'] ?? 'Unknown Doctor',
          doctorSpecialty: item['specialties'] ?? '',
        );
        tips.add(tip);
      } catch (e) {
        print('Error parsing health advice: $e');
      }
    }
    
    return tips;
  }
}