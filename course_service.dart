import 'dart:convert';
import 'package:http/http.dart' as http;
import 'course_model.dart';

class CourseServiceException implements Exception {
  final String message;
  CourseServiceException(this.message);

  @override
  String toString() => message;
}

class CourseService {
  // Demo public API
  static const String _url = 'https://jsonplaceholder.typicode.com/posts';

  static Future<List<Course>> fetchCourses() async {
    try {
      final response = await http.get(Uri.parse(_url));

      if (response.statusCode != 200) {
        throw CourseServiceException('Failed to load courses (${response.statusCode})');
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! List) {
        throw CourseServiceException('Invalid course data format');
      }

      return decoded
          .take(30) // limit for UI demo
          .map((e) => Course.fromApi(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      if (e is CourseServiceException) rethrow;
      throw CourseServiceException('Unable to fetch courses. Check your internet connection.');
    }
  }
}
