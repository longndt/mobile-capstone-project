import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'course_model.dart';

class CourseDetailScreen extends StatefulWidget {
  final Course course;
  final bool initialIsFavorite;
  final Future<void> Function() onToggleFavorite;

  const CourseDetailScreen({
    super.key,
    required this.course,
    required this.initialIsFavorite,
    required this.onToggleFavorite,
  });

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  bool _isFavorite = false;
  bool _isEnrolled = false;
  bool _isLoadingState = true;
  bool _expandedDescription = false;

  /// store completed lesson indexes (0-based)
  Set<int> _completedLessons = {};

  List<String> get _lessonTitles {
    // Generate demo lessons based on course.lessons count
    return List.generate(
      widget.course.lessons,
      (i) => 'Lesson ${i + 1}: ${_lessonTopic(i)}',
    );
  }

  double get _progress {
    if (_lessonTitles.isEmpty) return 0;
    return _completedLessons.length / _lessonTitles.length;
  }

  int get _completedCount => _completedLessons.length;

  String get _enrollKey => 'course_enrolled_${widget.course.id}';
  String get _completedKey => 'course_completed_lessons_${widget.course.id}';

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.initialIsFavorite;
    _loadLocalLearningState();
  }

  Future<void> _loadLocalLearningState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enrolled = prefs.getBool(_enrollKey) ?? false;
      final raw = prefs.getStringList(_completedKey) ?? [];

      final parsed = raw.map(int.tryParse).whereType<int>().toSet();

      if (!mounted) return;
      setState(() {
        _isEnrolled = enrolled;
        _completedLessons = parsed;
        _isLoadingState = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingState = false;
      });
    }
  }

  Future<void> _persistState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enrollKey, _isEnrolled);
    await prefs.setStringList(
      _completedKey,
      _completedLessons.map((e) => e.toString()).toList(),
    );
  }

  Future<void> _toggleFavorite() async {
    await widget.onToggleFavorite();
    if (!mounted) return;
    setState(() {
      _isFavorite = !_isFavorite;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isFavorite ? 'Added to favorites' : 'Removed from favorites',
        ),
        duration: const Duration(milliseconds: 900),
      ),
    );
  }

  Future<void> _enrollOrContinue() async {
    if (!_isEnrolled) {
      setState(() => _isEnrolled = true);
      await _persistState();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enrollment successful ✅')),
      );
      return;
    }

    // Continue learning -> open first incomplete lesson
    final nextIndex = _nextIncompleteLessonIndex();
    if (nextIndex == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You completed all lessons 🎉')),
      );
      return;
    }

    _showLessonSheet(nextIndex);
  }

  int? _nextIncompleteLessonIndex() {
    for (int i = 0; i < _lessonTitles.length; i++) {
      if (!_completedLessons.contains(i)) return i;
    }
    return null;
  }

  Future<void> _toggleLessonCompleted(int lessonIndex) async {
    if (!_isEnrolled) {
      // Optional UX: auto-enroll on first lesson interaction
      _isEnrolled = true;
    }

    setState(() {
      if (_completedLessons.contains(lessonIndex)) {
        _completedLessons.remove(lessonIndex);
      } else {
        _completedLessons.add(lessonIndex);
      }
    });

    await _persistState();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _completedLessons.contains(lessonIndex)
              ? 'Marked lesson as completed'
              : 'Marked lesson as not completed',
        ),
        duration: const Duration(milliseconds: 800),
      ),
    );
  }

  void _showLessonSheet(int lessonIndex) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) {
        final completed = _completedLessons.contains(lessonIndex);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _lessonTitles[lessonIndex],
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 10),
                Text(
                  'This is a placeholder lesson preview. In the real app, this opens video/content/quiz.',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          Navigator.pop(context);
                          await _toggleLessonCompleted(lessonIndex);
                        },
                        icon: Icon(
                          completed
                              ? Icons.radio_button_unchecked
                              : Icons.check_circle,
                        ),
                        label: Text(
                          completed ? 'Mark Incomplete' : 'Mark Complete',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _lessonTopic(int index) {
    // Demo topics (cycled)
    const topics = [
      'Introduction',
      'Core Concepts',
      'Examples & Practice',
      'Exercises',
      'Tips & Tricks',
      'Mini Quiz',
      'Advanced Notes',
      'Summary',
      'Real-world Application',
      'Review',
    ];
    return topics[index % topics.length];
  }

  @override
  Widget build(BuildContext context) {
    final course = widget.course;
    final progressPercent = (_progress * 100).round();
    final descText = course.description.trim();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Course Detail'),
        actions: [
          IconButton(
            onPressed: _toggleFavorite,
            icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border),
            color: _isFavorite ? Colors.red : null,
            tooltip: 'Favorite',
          ),
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share feature coming soon')),
              );
            },
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share',
          ),
        ],
      ),
      body: _isLoadingState
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadLocalLearningState,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Hero/Banner
                        Container(
                          height: 180,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.indigo.shade100,
                                Colors.indigo.shade50,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.school_rounded,
                              size: 80,
                              color: Colors.indigo.shade400,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Title
                        Text(
                          course.title,
                          style:
                              Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 8),

                        // Meta chips
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Chip(
                              avatar: const Icon(Icons.category_outlined, size: 18),
                              label: Text(course.category),
                            ),
                            Chip(
                              avatar: const Icon(Icons.menu_book_outlined, size: 18),
                              label: Text('${course.lessons} lessons'),
                            ),
                            Chip(
                              avatar: const Icon(Icons.star_outline, size: 18),
                              label: Text(course.rating.toStringAsFixed(1)),
                            ),
                            Chip(
                              avatar: Icon(
                                _isEnrolled
                                    ? Icons.verified_outlined
                                    : Icons.lock_outline,
                                size: 18,
                              ),
                              label: Text(_isEnrolled ? 'Enrolled' : 'Not enrolled'),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Progress Card
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Your Progress',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 10),
                                LinearProgressIndicator(
                                  value: _progress,
                                  minHeight: 10,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '$_completedCount / ${_lessonTitles.length} lessons completed ($progressPercent%)',
                                  style: TextStyle(color: Colors.grey.shade700),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Description
                        Text(
                          'Description',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          descText.isEmpty
                              ? 'No description available.'
                              : (_expandedDescription || descText.length <= 180)
                                  ? descText
                                  : '${descText.substring(0, 180)}...',
                          style: TextStyle(color: Colors.grey.shade800, height: 1.4),
                        ),
                        if (descText.length > 180)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _expandedDescription = !_expandedDescription;
                              });
                            },
                            child: Text(
                              _expandedDescription ? 'Show less' : 'Read more',
                            ),
                          ),

                        const SizedBox(height: 8),

                        // Lessons header
                        Row(
                          children: [
                            Text(
                              'Lessons',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: _lessonTitles.isEmpty
                                  ? null
                                  : () async {
                                      setState(() {
                                        _completedLessons =
                                            Set<int>.from(List.generate(
                                          _lessonTitles.length,
                                          (i) => i,
                                        ));
                                        _isEnrolled = true;
                                      });
                                      await _persistState();
                                    },
                              icon: const Icon(Icons.done_all, size: 18),
                              label: const Text('Complete all'),
                            ),
                          ],
                        ),

                        const SizedBox(height: 4),

                        // Lesson list
                        ...List.generate(_lessonTitles.length, (index) {
                          final completed = _completedLessons.contains(index);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: completed
                                    ? Colors.green.shade100
                                    : Colors.indigo.shade50,
                                child: Icon(
                                  completed
                                      ? Icons.check
                                      : Icons.play_arrow_rounded,
                                  color: completed
                                      ? Colors.green.shade700
                                      : Colors.indigo.shade400,
                                ),
                              ),
                              title: Text(
                                _lessonTitles[index],
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                completed ? 'Completed' : 'Tap to preview',
                              ),
                              trailing: Checkbox(
                                value: completed,
                                onChanged: (_) => _toggleLessonCompleted(index),
                              ),
                              onTap: () => _showLessonSheet(index),
                            ),
                          );
                        }),

                        const SizedBox(height: 90), // space for bottom button
                      ],
                    ),
                  ),
                ),

                // Bottom CTA
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _enrollOrContinue,
                        icon: Icon(
                          _isEnrolled ? Icons.play_arrow_rounded : Icons.school,
                        ),
                        label: Text(
                          _isEnrolled ? 'Continue Learning' : 'Enroll Now',
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
