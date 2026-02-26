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

  factory Course.fromApi(Map<String, dynamic> json) {
    // Demo mapping from JSONPlaceholder post -> Course
    const categories = ['Math', 'Science', 'English', 'Coding'];
    final id = (json['id'] as num).toInt();
    final userId = (json['userId'] as num?)?.toInt() ?? 1;

    return Course(
      id: id,
      title: (json['title'] ?? 'Untitled Course').toString(),
      description: (json['body'] ?? '').toString(),
      category: categories[(userId + id) % categories.length],
      lessons: 8 + (id % 15), // fake lesson count for demo
      rating: 4.0 + ((id % 10) / 10), // 4.0 - 4.9
    );
  }
}
