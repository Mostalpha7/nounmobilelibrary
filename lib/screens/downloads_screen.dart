import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/course.dart';
import '../services/database_helper.dart';
import '../services/download_manager.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../widgets/course_card.dart';
import 'course_detail_screen.dart';

/// Downloads Screen - Manage all downloaded courses
class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final DownloadManager _downloadManager = DownloadManager();

  List<Course> _downloadedCourses = [];
  bool _isLoading = true;
  int _totalStorageUsed = 0;

  @override
  void initState() {
    super.initState();
    _loadDownloads();
  }

  /// Load all downloaded courses
  Future<void> _loadDownloads() async {
    try {
      setState(() => _isLoading = true);

      final downloaded = await _dbHelper.getDownloadedCourses();
      final storage = await _downloadManager.getTotalStorageUsed();

      setState(() {
        _downloadedCourses = downloaded;
        _totalStorageUsed = storage;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load downloads: $e');
    }
  }

  /// Delete all downloads
  Future<void> _deleteAllDownloads() async {
    final confirmed = await _showConfirmDialog(
      title: 'Delete All Downloads',
      content:
          'Are you sure you want to delete all downloaded courses? Bundled courses will not be affected.',
    );

    if (confirmed == true) {
      final success = await _downloadManager.clearAllDownloads();
      if (success) {
        await _loadDownloads();
        _showSuccessSnackBar('All downloads deleted');
      } else {
        _showErrorSnackBar('Failed to delete downloads');
      }
    }
  }

  /// Show more options menu
  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(LucideIcons.trash2, color: Colors.red),
              title: const Text(
                'Delete All Downloads',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _deleteAllDownloads();
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.info),
              title: const Text('Storage Info'),
              subtitle: Text(
                'Total: ${Helpers.formatFileSize(_totalStorageUsed)}',
              ),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  /// Show confirmation dialog
  Future<bool?> _showConfirmDialog({
    required String title,
    required String content,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.errorColor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  /// Show success snackbar
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  /// Show error snackbar
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppConstants.errorColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Downloads'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.moveVertical400),
            onPressed: _showOptionsMenu,
            tooltip: 'More options',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  /// Build main body
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_downloadedCourses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.download400,
              size: 80,
              color: AppConstants.textTertiary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No Downloads Yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppConstants.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Text(
                'Browse courses and download them for offline access',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppConstants.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDownloads,
      child: Column(
        children: [
          // Storage Info Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppConstants.primaryColor.withOpacity(0.1),
                  AppConstants.secondaryColor.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppConstants.primaryColor.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    LucideIcons.hardDrive,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_downloadedCourses.length} ${_downloadedCourses.length == 1 ? 'Course' : 'Courses'}',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppConstants.textPrimary,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Storage: ${Helpers.formatFileSize(_totalStorageUsed)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppConstants.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Downloaded Courses List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 16),
              itemCount: _downloadedCourses.length,
              itemBuilder: (context, index) {
                final course = _downloadedCourses[index];
                return CourseCard(
                  course: course,
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            CourseDetailScreen(course: course),
                      ),
                    );
                    // Refresh if course was deleted
                    if (result == true) {
                      _loadDownloads();
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
