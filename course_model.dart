class Course {
  final int id;
  final String title;
  final String description;
  final String category;
  final int lessons;
  final double rating;

  const Course({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.lessons,
    required this.rating,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? json['body'] ?? '').toString(),
      category: (json['category'] ?? 'General').toString(),
      lessons: (json['lessons'] as num?)?.toInt() ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'category': category,
        'lessons': lessons,
        'rating': rating,
      };
}
