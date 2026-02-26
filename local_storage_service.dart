import 'package:shared_preferences/shared_preferences.dart';

class AppUser {
  final String? id;
  final String? name;
  final String? email;

  const AppUser({
    this.id,
    this.name,
    this.email,
  });

  bool get isEmpty =>
      (id == null || id!.isEmpty) &&
      (name == null || name!.isEmpty) &&
      (email == null || email!.isEmpty);

  AppUser copyWith({
    String? id,
    String? name,
    String? email,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
    );
  }
}

class CourseProgress {
  final bool isEnrolled;
  final Set<int> completedLessons;

  const CourseProgress({
    required this.isEnrolled,
    required this.completedLessons,
  });

  double progressPercent(int totalLessons) {
    if (totalLessons <= 0) return 0;
    return completedLessons.length / totalLessons;
  }

  CourseProgress copyWith({
    bool? isEnrolled,
    Set<int>? completedLessons,
  }) {
    return CourseProgress(
      isEnrolled: isEnrolled ?? this.isEnrolled,
      completedLessons: completedLessons ?? this.completedLessons,
    );
  }

  static const empty = CourseProgress(
    isEnrolled: false,
    completedLessons: <int>{},
  );
}

class AppSettings {
  final bool darkMode;
  final bool notificationsEnabled;
  final String languageCode; // e.g. 'en', 'vi'

  const AppSettings({
    required this.darkMode,
    required this.notificationsEnabled,
    required this.languageCode,
  });

  AppSettings copyWith({
    bool? darkMode,
    bool? notificationsEnabled,
    String? languageCode,
  }) {
    return AppSettings(
      darkMode: darkMode ?? this.darkMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      languageCode: languageCode ?? this.languageCode,
    );
  }

  static const defaults = AppSettings(
    darkMode: false,
    notificationsEnabled: true,
    languageCode: 'en',
  );
}

class LocalStorageService {
  LocalStorageService._();
  static final LocalStorageService instance = LocalStorageService._();

  SharedPreferences? _prefs;

  // ---------------------------
  // KEYS
  // ---------------------------
  static const String _kAuthToken = 'auth_token';
  static const String _kUserId = 'user_id';
  static const String _kUserName = 'user_name';
  static const String _kUserEmail = 'user_email';

  static const String _kFavoriteCourseIds = 'favorite_course_ids';

  static const String _kDarkMode = 'settings_dark_mode';
  static const String _kNotificationsEnabled = 'settings_notifications_enabled';
  static const String _kLanguageCode = 'settings_language_code';

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  SharedPreferences get _sp {
    final prefs = _prefs;
    if (prefs == null) {
      throw StateError(
        'LocalStorageService is not initialized. Call LocalStorageService.instance.init() in main() before using it.',
      );
    }
    return prefs;
  }

  // ---------------------------
  // AUTH
  // ---------------------------
  Future<void> saveAuthSession({
    String? token,
    String? userId,
    String? userName,
    String? userEmail,
  }) async {
    if (token != null) await _sp.setString(_kAuthToken, token);
    if (userId != null) await _sp.setString(_kUserId, userId);
    if (userName != null) await _sp.setString(_kUserName, userName);
    if (userEmail != null) await _sp.setString(_kUserEmail, userEmail);
  }

  String? getAuthToken() => _sp.getString(_kAuthToken);

  bool get isLoggedIn {
    final token = getAuthToken();
    return token != null && token.isNotEmpty;
  }

  AppUser getUser() {
    return AppUser(
      id: _sp.getString(_kUserId),
      name: _sp.getString(_kUserName),
      email: _sp.getString(_kUserEmail),
    );
  }

  Future<void> clearAuthSession() async {
    await _sp.remove(_kAuthToken);
    await _sp.remove(_kUserId);
    await _sp.remove(_kUserName);
    await _sp.remove(_kUserEmail);
  }

  // ---------------------------
  // FAVORITES
  // ---------------------------
  Set<int> getFavoriteCourseIds() {
    final raw = _sp.getStringList(_kFavoriteCourseIds) ?? [];
    return raw.map(int.tryParse).whereType<int>().toSet();
  }

  Future<void> saveFavoriteCourseIds(Set<int> ids) async {
    await _sp.setStringList(
      _kFavoriteCourseIds,
      ids.map((e) => e.toString()).toList(),
    );
  }

  Future<bool> toggleFavoriteCourseId(int courseId) async {
    final ids = getFavoriteCourseIds();
    final nowFavorite = !ids.contains(courseId);

    if (nowFavorite) {
      ids.add(courseId);
    } else {
      ids.remove(courseId);
    }

    await saveFavoriteCourseIds(ids);
    return nowFavorite;
  }

  bool isFavoriteCourse(int courseId) {
    return getFavoriteCourseIds().contains(courseId);
  }

  // ---------------------------
  // COURSE PROGRESS
  // ---------------------------
  String _enrolledKey(int courseId) => 'course_enrolled_$courseId';
  String _completedLessonsKey(int courseId) => 'course_completed_lessons_$courseId';

  CourseProgress getCourseProgress(int courseId) {
    final enrolled = _sp.getBool(_enrolledKey(courseId)) ?? false;
    final raw = _sp.getStringList(_completedLessonsKey(courseId)) ?? [];
    final completed = raw.map(int.tryParse).whereType<int>().toSet();

    return CourseProgress(
      isEnrolled: enrolled,
      completedLessons: completed,
    );
  }

  Future<void> saveCourseProgress(int courseId, CourseProgress progress) async {
    await _sp.setBool(_enrolledKey(courseId), progress.isEnrolled);
    await _sp.setStringList(
      _completedLessonsKey(courseId),
      progress.completedLessons.map((e) => e.toString()).toList(),
    );
  }

  Future<void> setCourseEnrolled(int courseId, bool isEnrolled) async {
    final current = getCourseProgress(courseId);
    await saveCourseProgress(
      courseId,
      current.copyWith(isEnrolled: isEnrolled),
    );
  }

  Future<void> toggleLessonCompleted({
    required int courseId,
    required int lessonIndex,
  }) async {
    final current = getCourseProgress(courseId);
    final nextCompleted = Set<int>.from(current.completedLessons);

    if (nextCompleted.contains(lessonIndex)) {
      nextCompleted.remove(lessonIndex);
    } else {
      nextCompleted.add(lessonIndex);
    }

    await saveCourseProgress(
      courseId,
      current.copyWith(
        isEnrolled: true, // auto-enroll when interacting with lessons
        completedLessons: nextCompleted,
      ),
    );
  }

  Future<void> markAllLessonsCompleted({
    required int courseId,
    required int totalLessons,
  }) async {
    final all = Set<int>.from(List.generate(totalLessons, (i) => i));
    await saveCourseProgress(
      courseId,
      CourseProgress(
        isEnrolled: true,
        completedLessons: all,
      ),
    );
  }

  Future<void> clearCourseProgress(int courseId) async {
    await _sp.remove(_enrolledKey(courseId));
    await _sp.remove(_completedLessonsKey(courseId));
  }

  // ---------------------------
  // SETTINGS
  // ---------------------------
  AppSettings getSettings() {
    return AppSettings(
      darkMode: _sp.getBool(_kDarkMode) ?? AppSettings.defaults.darkMode,
      notificationsEnabled: _sp.getBool(_kNotificationsEnabled) ??
          AppSettings.defaults.notificationsEnabled,
      languageCode: _sp.getString(_kLanguageCode) ??
          AppSettings.defaults.languageCode,
    );
  }

  Future<void> saveSettings(AppSettings settings) async {
    await _sp.setBool(_kDarkMode, settings.darkMode);
    await _sp.setBool(
      _kNotificationsEnabled,
      settings.notificationsEnabled,
    );
    await _sp.setString(_kLanguageCode, settings.languageCode);
  }

  Future<void> setDarkMode(bool value) async {
    final current = getSettings();
    await saveSettings(current.copyWith(darkMode: value));
  }

  Future<void> setNotificationsEnabled(bool value) async {
    final current = getSettings();
    await saveSettings(current.copyWith(notificationsEnabled: value));
  }

  Future<void> setLanguageCode(String value) async {
    final current = getSettings();
    await saveSettings(current.copyWith(languageCode: value));
  }

  // ---------------------------
  // DEBUG / RESET (optional)
  // ---------------------------
  Future<void> clearAll() async {
    await _sp.clear();
  }
}
