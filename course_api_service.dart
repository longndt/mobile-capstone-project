import 'api_client.dart';
import 'api_endpoints.dart';
import 'api_exception.dart';
import 'course_model.dart';

class CourseApiService {
  CourseApiService._();
  static final CourseApiService instance = CourseApiService._();

  /// GET /courses?search=&category=
  ///
  /// Supports multiple backend response formats:
  /// - [ ... ]
  /// - { "data": [ ... ] }
  /// - { "items": [ ... ] }
  Future<List<Course>> fetchCourses({
    String? search,
    String? category,
    int? page,
    int? limit,
  }) async {
    final data = await ApiClient.instance.get(
      ApiEndpoints.courses,
      auth: true, // set false if your courses endpoint is public
      query: {
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (category != null && category != 'All') 'category': category,
        if (page != null) 'page': page,
        if (limit != null) 'limit': limit,
      },
    );

    List<dynamic> rawList;
    if (data is List) {
      rawList = data;
    } else if (data is Map<String, dynamic>) {
      if (data['data'] is List) {
        rawList = data['data'] as List;
      } else if (data['items'] is List) {
        rawList = data['items'] as List;
      } else {
        throw const ApiException(message: 'Invalid courses response format');
      }
    } else {
      throw const ApiException(message: 'Invalid courses response format');
    }

    return rawList
        .map((e) => Course.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<Course> fetchCourseDetail(int courseId) async {
    final data = await ApiClient.instance.get(
      ApiEndpoints.courseDetail(courseId),
      auth: true, // set false if public
    );

    if (data is! Map<String, dynamic>) {
      throw const ApiException(message: 'Invalid course detail response format');
    }

    // Some backends return {data: {...}}
    final payload = (data['data'] is Map<String, dynamic>)
        ? data['data'] as Map<String, dynamic>
        : data;

    return Course.fromJson(payload);
  }

  Future<void> enrollCourse(int courseId) async {
    await ApiClient.instance.post(
      ApiEndpoints.enrollCourse(courseId),
      auth: true,
    );
  }
}
