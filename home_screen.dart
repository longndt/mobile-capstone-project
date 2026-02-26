import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_service.dart';
import 'course_detail_screen.dart';
import 'course_model.dart';
import 'course_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  String? _error;

  List<Course> _allCourses = [];
  Set<int> _favoriteIds = {};

  String _selectedCategory = 'All';
  int _currentTabIndex = 0;

  String _userName = 'Learner';
  String _userEmail = '';

  List<String> get _categories {
    final set = <String>{'All', ..._allCourses.map((e) => e.category)};
    return set.toList();
  }

  @override
  void initState() {
    super.initState();
    _initHome();
    _searchController.addListener(() {
      setState(() {}); // rebuild when typing
    });
  }

  Future<void> _initHome() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _loadUserProfile();
      await _loadFavorites();
      final courses = await CourseService.fetchCourses();

      if (!mounted) return;
      setState(() {
        _allCourses = courses;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    _userName = prefs.getString('user_name') ?? 'Learner';
    _userEmail = prefs.getString('user_email') ?? '';
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('favorite_course_ids') ?? [];
    _favoriteIds = raw.map(int.tryParse).whereType<int>().toSet();
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'favorite_course_ids',
      _favoriteIds.map((e) => e.toString()).toList(),
    );
  }

  Future<void> _toggleFavorite(int courseId) async {
    setState(() {
      if (_favoriteIds.contains(courseId)) {
        _favoriteIds.remove(courseId);
      } else {
        _favoriteIds.add(courseId);
      }
    });
    await _saveFavorites();
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (!mounted) return;

    // Use named route to avoid circular imports (recommended)
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  List<Course> _filteredCourses({bool favoritesOnly = false}) {
    final query = _searchController.text.trim().toLowerCase();

    Iterable<Course> list = _allCourses;

    if (favoritesOnly) {
      list = list.where((c) => _favoriteIds.contains(c.id));
    }

    if (_selectedCategory != 'All') {
      list = list.where((c) => c.category == _selectedCategory);
    }

    if (query.isNotEmpty) {
      list = list.where((c) =>
          c.title.toLowerCase().contains(query) ||
          c.description.toLowerCase().contains(query) ||
          c.category.toLowerCase().contains(query));
    }

    return list.toList();
  }

  void _openCourseDetail(Course course) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CourseDetailScreen(
          course: course,
          isFavorite: _favoriteIds.contains(course.id),
          onToggleFavorite: () async {
            await _toggleFavorite(course.id);
          },
        ),
      ),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search courses...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchController.text.isEmpty
            ? null
            : IconButton(
                onPressed: () => _searchController.clear(),
                icon: const Icon(Icons.clear),
              ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    final categories = _categories;

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          final selected = _selectedCategory == category;

          return ChoiceChip(
            label: Text(category),
            selected: selected,
            onSelected: (_) {
              setState(() {
                _selectedCategory = category;
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildCourseCard(Course course) {
    final isFav = _favoriteIds.contains(course.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openCourseDetail(course),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.school, color: Colors.indigo.shade400, size: 34),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      course.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(
                          label: Text(course.category),
                          visualDensity: VisualDensity.compact,
                        ),
                        Chip(
                          label: Text('${course.lessons} lessons'),
                          visualDensity: VisualDensity.compact,
                        ),
                        Chip(
                          label: Text('⭐ ${course.rating.toStringAsFixed(1)}'),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _toggleFavorite(course.id),
                icon: Icon(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  color: isFav ? Colors.red : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoursesList(List<Course> courses, {required bool favoritesOnly}) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _initHome,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (courses.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            favoritesOnly
                ? 'No favorite courses yet.'
                : 'No courses found for your search/filter.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _initHome,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: courses.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            // header spacing for tabs
            return const SizedBox(height: 8);
          }
          final course = courses[index - 1];
          return _buildCourseCard(course);
        },
      ),
    );
  }

  Widget _buildHomeTab() {
    final courses = _filteredCourses();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hi, $_userName 👋',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'What do you want to learn today?',
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 14),
              _buildSearchBar(),
              const SizedBox(height: 12),
              _buildCategoryChips(),
            ],
          ),
        ),
        Expanded(child: _buildCoursesList(courses, favoritesOnly: false)),
      ],
    );
  }

  Widget _buildFavoritesTab() {
    final favoriteCourses = _filteredCourses(favoritesOnly: true);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Favorites ❤️',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              _buildSearchBar(),
              const SizedBox(height: 12),
              _buildCategoryChips(),
            ],
          ),
        ),
        Expanded(child: _buildCoursesList(favoriteCourses, favoritesOnly: true)),
      ],
    );
  }

  Widget _buildProfileTab() {
    return RefreshIndicator(
      onRefresh: _initHome,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(_userName),
              subtitle: Text(_userEmail.isEmpty ? 'No email saved' : _userEmail),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.settings_outlined),
                  title: const Text('Settings'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Settings screen coming next')),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.notifications_outlined),
                  title: const Text('Notifications'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Notifications screen coming next')),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('About'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: 'Educational App',
                      applicationVersion: '1.0.0',
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: _logout,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabs = <Widget>[
      _buildHomeTab(),
      _buildFavoritesTab(),
      _buildProfileTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentTabIndex == 0
              ? 'Home'
              : _currentTabIndex == 1
                  ? 'Favorites'
                  : 'Profile',
        ),
        actions: [
          IconButton(
            onPressed: _initHome,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: tabs[_currentTabIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentTabIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentTabIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.favorite_border), selectedIcon: Icon(Icons.favorite), label: 'Favorites'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
