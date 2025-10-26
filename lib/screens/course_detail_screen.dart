import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/course.dart';
import '../models/download_progress.dart';
import '../services/database_helper.dart';
import '../services/download_manager.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import 'pdf_viewer_screen.dart';

/// Course Detail Screen - Shows detailed course information and actions
class CourseDetailScreen extends StatefulWidget {
  final Course course;

  const CourseDetailScreen({super.key, required this.course});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final DownloadManager _downloadManager = DownloadManager();

  late Course _course;
  DownloadProgress? _downloadProgress;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _course = widget.course;
    _checkDownloadStatus();
  }

  /// Check if course is currently being downloaded
  Future<void> _checkDownloadStatus() async {
    final progress = _downloadManager.getDownloadProgress(_course.id);
    if (progress != null && progress.isInProgress) {
      setState(() {
        _downloadProgress = progress;
        _isDownloading = true;
      });
    }
  }

  /// Open course PDF
  Future<void> _openCourse() async {
    try {
      // Update last accessed time
      await _dbHelper.updateLastAccessed(_course.id);

      // Navigate to PDF viewer
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PDFViewerScreen(course: _course),
          ),
        );
      }
    } catch (e) {
      _showErrorSnackBar('Failed to open course: $e');
    }
  }

  /// Download course
  Future<void> _downloadCourse() async {
    setState(() => _isDownloading = true);

    try {
      final result = await _downloadManager.downloadCourse(
        _course,
        onProgress: (progress) async {
          if (mounted) {
            setState(() {
              _downloadProgress = progress;
            });

            // Check if download completed
            if (progress.isComplete) {
              Future.delayed(const Duration(milliseconds: 750), () {
                _refreshCourseData();
              });

              _showSuccessSnackBar('Download completed!');
            } else if (progress.hasFailed) {
              setState(() => _isDownloading = false);
              _showErrorSnackBar(progress.errorMessage ?? 'Download failed');
            }
          }
        },
      );

      if (result.queued) {
        _showInfoSnackBar('Added to download queue');
      } else if (!result.success && !result.queued) {
        _showErrorSnackBar(result.message);
        setState(() => _isDownloading = false);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to start download: $e');
      setState(() => _isDownloading = false);
    }
  }

  /// Cancel download
  Future<void> _cancelDownload() async {
    final confirmed = await _showConfirmDialog(
      title: 'Cancel Download',
      content: 'Are you sure you want to cancel this download?',
    );

    if (confirmed == true) {
      final success = await _downloadManager.cancelDownload(_course.id);
      if (success) {
        setState(() {
          _isDownloading = false;
          _downloadProgress = null;
        });
        _showInfoSnackBar('Download cancelled');
      }
    }
  }

  /// Delete downloaded course
  Future<void> _deleteDownload() async {
    final confirmed = await _showConfirmDialog(
      title: 'Delete Download',
      content:
          'Are you sure you want to delete this downloaded course? You can download it again later.',
    );

    if (confirmed == true) {
      final success = await _downloadManager.deleteDownload(_course);
      if (success) {
        await _refreshCourseData();
        _showInfoSnackBar('Download deleted');
      } else {
        _showErrorSnackBar('Failed to delete download');
      }
    }
  }

  /// Refresh course data from database
  Future<void> _refreshCourseData() async {
    final updatedCourse = await _dbHelper.getCourseById(_course.id);
    if (updatedCourse != null && mounted) {
      setState(() {
        _course = updatedCourse;
        _isDownloading = false;
        _downloadProgress = null;
      });
    }
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
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  /// Show success snackbar
  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Show error snackbar
  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppConstants.errorColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Show info snackbar
  void _showInfoSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_course.courseCode)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            _buildHeaderCard(),

            const SizedBox(height: 16),

            // Description Section
            _buildSection(
              title: 'Description',
              icon: LucideIcons.fileText,
              child: Text(
                _course.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppConstants.textPrimary,
                  height: 1.6,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Course Details Section
            _buildSection(
              title: 'Course Details',
              icon: LucideIcons.info,
              child: _buildDetailsGrid(),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomActions(),
    );
  }

  /// Build header card with course title and status
  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppConstants.primaryColor,
            AppConstants.primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Course Code Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _course.courseCode,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Course Title
          Text(
            _course.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          // Status Badges
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildWhiteBadge(_course.level, LucideIcons.graduationCap),
              _buildWhiteBadge(_course.category, LucideIcons.tag),
              _buildWhiteBadge(
                Helpers.formatFileSize(_course.fileSize),
                LucideIcons.fileText,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build white badge for header
  Widget _buildWhiteBadge(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Build section with title and content
  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppConstants.primaryColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppConstants.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  /// Build details grid
  Widget _buildDetailsGrid() {
    return Column(
      children: [
        _buildDetailRow('Level', _course.level),
        _buildDetailRow('Category', _course.category),
        _buildDetailRow('File Size', Helpers.formatFileSize(_course.fileSize)),
        _buildDetailRow(
          'Status',
          _course.isBundled
              ? 'Bundled'
              : _course.isDownloaded
              ? 'Downloaded'
              : 'Available in Cloud',
        ),
        if (_course.isDownloaded && _course.downloadedAt != null)
          _buildDetailRow(
            'Downloaded',
            Helpers.formatDate(_course.downloadedAt!),
          ),
        if (_course.lastAccessedAt != null)
          _buildDetailRow(
            'Last Accessed',
            Helpers.formatDate(_course.lastAccessedAt!),
          ),
      ],
    );
  }

  /// Build detail row
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppConstants.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppConstants.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  /// Build bottom action buttons
  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: _isDownloading && _downloadProgress != null
            ? _buildDownloadProgress()
            : _buildActionButtons(),
      ),
    );
  }

  /// Build download progress indicator
  Widget _buildDownloadProgress() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Downloading...',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_downloadProgress!.progressPercentage}% • ${Helpers.formatFileSize(_downloadProgress!.downloadedBytes)} / ${Helpers.formatFileSize(_downloadProgress!.totalBytes)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppConstants.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(LucideIcons.x),
              onPressed: _cancelDownload,
              tooltip: 'Cancel',
            ),
          ],
        ),
        const SizedBox(height: 12),
        LinearProgressIndicator(
          value: _downloadProgress!.progress,
          backgroundColor: AppConstants.surfaceColor,
          valueColor: AlwaysStoppedAnimation<Color>(AppConstants.primaryColor),
        ),
      ],
    );
  }

  /// Build action buttons
  Widget _buildActionButtons() {
    if (_course.isAvailable) {
      // Course is available (bundled or downloaded)
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _openCourse,
              icon: const Icon(LucideIcons.bookOpen),
              label: const Text('Open Course'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          if (_course.isDownloaded && !_course.isBundled) ...[
            const SizedBox(width: 12),
            OutlinedButton(
              onPressed: _deleteDownload,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
              child: const Icon(LucideIcons.trash2),
            ),
          ],
        ],
      );
    } else {
      // Course needs to be downloaded
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _downloadCourse,
          icon: const Icon(LucideIcons.download),
          label: Text('Download (${Helpers.formatFileSize(_course.fileSize)})'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      );
    }
  }
}
