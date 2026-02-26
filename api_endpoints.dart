class ApiEndpoints {
  // Auth
  static const String login = '/auth/login';
  static const String signup = '/auth/signup';
  static const String me = '/auth/me';

  // Courses
  static const String courses = '/courses'; // GET list
  static String courseDetail(int id) => '/courses/$id'; // GET detail
  static String enrollCourse(int id) => '/courses/$id/enroll'; // POST
}
