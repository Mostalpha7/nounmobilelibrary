import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/course.dart';
import '../services/database_helper.dart';
import '../utils/constants.dart';
import '../widgets/course_card.dart';
import 'course_detail_screen.dart';

/// Course List Screen - Shows courses filtered by category or level
class CourseListScreen extends StatefulWidget {
  final String? category;
  final String? level;
  final String title;

  const CourseListScreen({
    super.key,
    this.category,
    this.level,
    required this.title,
  });

  @override
  State<CourseListScreen> createState() => _CourseListScreenState();
}

class _CourseListScreenState extends State<CourseListScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  List<Course> _courses = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Filters
  String _selectedLevel = 'All Levels';
  String _sortBy = 'Course Code';

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  /// Load courses based on filter
  Future<void> _loadCourses() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      List<Course> courses;

      if (widget.category != null) {
        courses = await _dbHelper.getCoursesByCategory(widget.category!);
      } else if (widget.level != null) {
        courses = await _dbHelper.getCoursesByLevel(widget.level!);
      } else {
        courses = await _dbHelper.getAllCourses();
      }

      // Apply level filter if selected
      if (_selectedLevel != 'All Levels') {
        courses = courses.where((c) => c.level == _selectedLevel).toList();
      }

      // Apply sorting
      _sortCourses(courses);

      setState(() {
        _courses = courses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load courses: $e';
        _isLoading = false;
      });
    }
  }

  /// Sort courses based on selected criteria
  void _sortCourses(List<Course> courses) {
    switch (_sortBy) {
      case 'Course Code':
        courses.sort((a, b) => a.courseCode.compareTo(b.courseCode));
        break;
      case 'Title':
        courses.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'Level':
        courses.sort((a, b) => a.level.compareTo(b.level));
        break;
      case 'Recently Added':
        courses.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }
  }

  /// Show filter bottom sheet
  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.listFilter,
                        color: AppConstants.primaryColor,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Filter & Sort',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Level Filter (only if showing by category)
                  if (widget.category != null) ...[
                    Text(
                      'Level',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: ['All Levels', ...AppConstants.courseLevels]
                          .map((level) {
                            final isSelected = _selectedLevel == level;
                            return FilterChip(
                              label: Text(level),
                              selected: isSelected,
                              onSelected: (selected) {
                                setModalState(() {
                                  setState(() {
                                    _selectedLevel = level;
                                  });
                                });
                              },
                              selectedColor: AppConstants.primaryColor
                                  .withOpacity(0.2),
                              checkmarkColor: AppConstants.primaryColor,
                            );
                          })
                          .toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Sort By
                  Text(
                    'Sort By',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children:
                        ['Course Code', 'Title', 'Level', 'Recently Added'].map(
                          (sort) {
                            final isSelected = _sortBy == sort;
                            return FilterChip(
                              label: Text(sort),
                              selected: isSelected,
                              onSelected: (selected) {
                                setModalState(() {
                                  setState(() {
                                    _sortBy = sort;
                                  });
                                });
                              },
                              selectedColor: AppConstants.primaryColor
                                  .withOpacity(0.2),
                              checkmarkColor: AppConstants.primaryColor,
                            );
                          },
                        ).toList(),
                  ),

                  const SizedBox(height: 24),

                  // Apply Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _loadCourses();
                      },
                      child: const Text('Apply Filters'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.listFilter),
            onPressed: _showFilterSheet,
            tooltip: 'Filter & Sort',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  /// Build main body content
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.bell,
              size: 64,
              color: AppConstants.errorColor.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppConstants.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadCourses,
              icon: const Icon(LucideIcons.refreshCw),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_courses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.bookX,
              size: 64,
              color: AppConstants.textTertiary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No courses found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppConstants.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppConstants.textTertiary,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Course count header
        Container(
          padding: const EdgeInsets.all(16),
          color: AppConstants.surfaceColor,
          child: Row(
            children: [
              Text(
                '${_courses.length} ${_courses.length == 1 ? 'course' : 'courses'} found',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppConstants.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (_selectedLevel != 'All Levels')
                Chip(
                  label: Text(_selectedLevel),
                  onDeleted: () {
                    setState(() {
                      _selectedLevel = 'All Levels';
                    });
                    _loadCourses();
                  },
                  deleteIcon: const Icon(LucideIcons.x, size: 16),
                ),
            ],
          ),
        ),

        // Course List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 16),
            itemCount: _courses.length,
            itemBuilder: (context, index) {
              final course = _courses[index];
              return CourseCard(
                course: course,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CourseDetailScreen(course: course),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
