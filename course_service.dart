import 'course_api_service.dart';
import 'course_model.dart';

class CourseServiceException implements Exception {
  final String message;
  CourseServiceException(this.message);

  @override
  String toString() => message;
}

class CourseService {
  static Future<List<Course>> fetchCourses({
    String? search,
    String? category,
  }) async {
    try {
      return await CourseApiService.instance.fetchCourses(
        search: search,
        category: category,
      );
    } catch (e) {
      throw CourseServiceException(
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  static Future<Course> fetchCourseDetail(int id) async {
    try {
      return await CourseApiService.instance.fetchCourseDetail(id);
    } catch (e) {
      throw CourseServiceException(
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  static Future<void> enrollCourse(int id) async {
    try {
      await CourseApiService.instance.enrollCourse(id);
    } catch (e) {
      throw CourseServiceException(
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }
}
