import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/course.dart';
import '../models/download_progress.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import 'database_helper.dart';
import 'firebase_service.dart';

/// Download Manager - Handles course PDF downloads from Firebase Storage
class DownloadManager {
  static final DownloadManager _instance = DownloadManager._internal();
  factory DownloadManager() => _instance;
  DownloadManager._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper();
  final FirebaseService _firebaseService = FirebaseService();
  final Dio _dio = Dio();

  // Active downloads tracking
  final Map<String, CancelToken> _activeDownloads = {};
  final Map<String, DownloadProgress> _downloadProgresses = {};

  // Download queue
  final List<Course> _downloadQueue = [];
  int _activeDownloadCount = 0;

  // ==================== DOWNLOAD OPERATIONS ====================

  /// Start downloading a course
  Future<DownloadResult> downloadCourse(
    Course course, {
    Function(DownloadProgress)? onProgress,
  }) async {
    try {
      // Validate course
      if (course.isBundled) {
        return DownloadResult(
          success: false,
          message: 'Course is already bundled with the app',
        );
      }

      if (course.isDownloaded) {
        return DownloadResult(
          success: false,
          message: 'Course is already downloaded',
        );
      }

      if (course.firebasePath == null || course.firebasePath!.isEmpty) {
        return DownloadResult(
          success: false,
          message: 'No download link available for this course',
        );
      }

      // Check if already downloading
      if (_activeDownloads.containsKey(course.id)) {
        return DownloadResult(
          success: false,
          message: 'Course is already being downloaded',
        );
      }

      // Check if queue is full
      if (_activeDownloadCount >= AppConstants.maxSimultaneousDownloads) {
        _downloadQueue.add(course);
        print('DownloadManager: Added ${course.courseCode} to queue');
        return DownloadResult(
          success: true,
          message: 'Added to download queue',
          queued: true,
        );
      }

      // Start download
      return await _startDownload(course, onProgress: onProgress);
    } catch (e) {
      print('DownloadManager: Error initiating download - $e');
      return DownloadResult(
        success: false,
        message: 'Failed to start download: $e',
      );
    }
  }

  /// Internal method to start actual download
  Future<DownloadResult> _startDownload(
    Course course, {
    Function(DownloadProgress)? onProgress,
  }) async {
    final CancelToken cancelToken = CancelToken();
    _activeDownloads[course.id] = cancelToken;
    _activeDownloadCount++;

    try {
      print('DownloadManager: Starting download for ${course.courseCode}');

      // Create initial progress record
      final initialProgress = DownloadProgress(
        courseId: course.id,
        courseCode: course.courseCode,
        title: course.title,
        status: DownloadStatus.downloading,
        totalBytes: course.fileSize,
      );

      _downloadProgresses[course.id] = initialProgress;
      await _dbHelper.insertDownloadProgress(initialProgress);
      onProgress?.call(initialProgress);

      // Get download URL from Google Drive
      final downloadUrl = await _firebaseService.getDownloadUrl(
        course.firebasePath!,
      );

      if (downloadUrl == null) {
        throw Exception('Failed to get download URL');
      }

      // Prepare local file path
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String coursesDir = path.join(appDocDir.path, 'courses');
      await Directory(coursesDir).create(recursive: true);

      final String fileName =
          '${Helpers.sanitizeFilename(course.courseCode)}.pdf';
      final String filePath = path.join(coursesDir, fileName);

      // Download file with progress tracking
      await _dio.download(
        downloadUrl,
        filePath,
        cancelToken: cancelToken,
        options: Options(
          receiveTimeout: AppConstants.downloadTimeout,
          sendTimeout: AppConstants.downloadTimeout,
        ),
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            final updatedProgress = DownloadProgress(
              courseId: course.id,
              courseCode: course.courseCode,
              title: course.title,
              status: DownloadStatus.downloading,
              totalBytes: total,
              downloadedBytes: received,
              progress: progress,
            );

            _downloadProgresses[course.id] = updatedProgress;
            onProgress?.call(updatedProgress);

            // Update database periodically (every 10%)
            if ((progress * 100).toInt() % 10 == 0) {
              _dbHelper.updateDownloadProgress(updatedProgress);
            }
          }
        },
      );

      // Download completed successfully
      final completedProgress = DownloadProgress(
        courseId: course.id,
        courseCode: course.courseCode,
        title: course.title,
        status: DownloadStatus.completed,
        totalBytes: course.fileSize,
        downloadedBytes: course.fileSize,
        progress: 1.0,
        completedAt: DateTime.now(),
      );

      _downloadProgresses[course.id] = completedProgress;
      await _dbHelper.updateDownloadProgress(completedProgress);
      onProgress?.call(completedProgress);

      // Update course record in database
      await _dbHelper.updateCourseDownloadStatus(
        courseId: course.id,
        isDownloaded: true,
        localPath: filePath,
      );

      print('DownloadManager: Download completed for ${course.courseCode}');

      // Clean up
      _activeDownloads.remove(course.id);
      _downloadProgresses.remove(course.id);
      _activeDownloadCount--;

      // Process next in queue
      _processQueue(onProgress: onProgress);

      return DownloadResult(
        success: true,
        message: 'Download completed successfully',
        filePath: filePath,
      );
    } catch (e) {
      print('DownloadManager: Download failed for ${course.courseCode} - $e');

      // Update progress with error
      final failedProgress = DownloadProgress(
        courseId: course.id,
        courseCode: course.courseCode,
        title: course.title,
        status: DownloadStatus.failed,
        errorMessage: e.toString(),
      );

      _downloadProgresses[course.id] = failedProgress;
      await _dbHelper.updateDownloadProgress(failedProgress);
      onProgress?.call(failedProgress);

      // Clean up
      _activeDownloads.remove(course.id);
      _downloadProgresses.remove(course.id);
      _activeDownloadCount--;

      // Process next in queue
      _processQueue(onProgress: onProgress);

      return DownloadResult(success: false, message: 'Download failed: $e');
    }
  }

  /// Process download queue
  void _processQueue({Function(DownloadProgress)? onProgress}) {
    if (_downloadQueue.isNotEmpty &&
        _activeDownloadCount < AppConstants.maxSimultaneousDownloads) {
      final nextCourse = _downloadQueue.removeAt(0);
      _startDownload(nextCourse, onProgress: onProgress);
    }
  }

  /// Cancel a download
  Future<bool> cancelDownload(String courseId) async {
    try {
      if (_activeDownloads.containsKey(courseId)) {
        _activeDownloads[courseId]?.cancel('Download cancelled by user');
        _activeDownloads.remove(courseId);
        _downloadProgresses.remove(courseId);
        _activeDownloadCount--;

        // Update database
        await _dbHelper.deleteDownloadProgress(courseId);

        print('DownloadManager: Download cancelled for $courseId');

        // Process next in queue
        _processQueue();

        return true;
      }

      // Remove from queue if present
      _downloadQueue.removeWhere((course) => course.id == courseId);

      return false;
    } catch (e) {
      print('DownloadManager: Error cancelling download - $e');
      return false;
    }
  }

  /// Pause a download (not fully supported by Dio, cancels instead)
  Future<bool> pauseDownload(String courseId) async {
    // For now, pause is same as cancel
    // In future, can implement resumable downloads
    return await cancelDownload(courseId);
  }

  /// Delete downloaded course file
  Future<bool> deleteDownload(Course course) async {
    try {
      if (!course.isDownloaded || course.isBundled) {
        return false;
      }

      // Delete file from storage
      if (course.localPath != null) {
        final file = File(course.localPath!);
        if (await file.exists()) {
          await file.delete();
          print('DownloadManager: Deleted file ${course.localPath}');
        }
      }

      // Update database
      await _dbHelper.updateCourseDownloadStatus(
        courseId: course.id,
        isDownloaded: false,
        localPath: null,
      );

      await _dbHelper.deleteDownloadProgress(course.id);

      print('DownloadManager: Download deleted for ${course.courseCode}');
      return true;
    } catch (e) {
      print('DownloadManager: Error deleting download - $e');
      return false;
    }
  }

  // ==================== QUERY OPERATIONS ====================

  /// Get download progress for a course
  DownloadProgress? getDownloadProgress(String courseId) {
    return _downloadProgresses[courseId];
  }

  /// Check if course is currently downloading
  bool isDownloading(String courseId) {
    return _activeDownloads.containsKey(courseId);
  }

  /// Check if course is in queue
  bool isInQueue(String courseId) {
    return _downloadQueue.any((course) => course.id == courseId);
  }

  /// Get active download count
  int get activeDownloadCount => _activeDownloadCount;

  /// Get queue size
  int get queueSize => _downloadQueue.length;

  /// Get all active downloads
  List<DownloadProgress> getActiveDownloads() {
    return _downloadProgresses.values.toList();
  }

  // ==================== UTILITY OPERATIONS ====================

  /// Calculate total storage used by downloads
  Future<int> getTotalStorageUsed() async {
    try {
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String coursesDir = path.join(appDocDir.path, 'courses');
      final Directory dir = Directory(coursesDir);

      if (!await dir.exists()) return 0;

      int totalSize = 0;
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }

      return totalSize;
    } catch (e) {
      print('DownloadManager: Error calculating storage - $e');
      return 0;
    }
  }

  /// Clear all downloads
  Future<bool> clearAllDownloads() async {
    try {
      // Cancel all active downloads
      for (final courseId in _activeDownloads.keys.toList()) {
        await cancelDownload(courseId);
      }

      // Delete all downloaded files
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String coursesDir = path.join(appDocDir.path, 'courses');
      final Directory dir = Directory(coursesDir);

      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }

      // Update all downloaded courses in database
      final downloadedCourses = await _dbHelper.getDownloadedCourses();
      for (final course in downloadedCourses) {
        if (!course.isBundled) {
          await _dbHelper.updateCourseDownloadStatus(
            courseId: course.id,
            isDownloaded: false,
            localPath: null,
          );
        }
      }

      print('DownloadManager: All downloads cleared');
      return true;
    } catch (e) {
      print('DownloadManager: Error clearing downloads - $e');
      return false;
    }
  }

  /// Cancel all downloads
  Future<void> cancelAllDownloads() async {
    for (final courseId in _activeDownloads.keys.toList()) {
      await cancelDownload(courseId);
    }
    _downloadQueue.clear();
    print('DownloadManager: All downloads cancelled');
  }
}

/// Result of a download operation
class DownloadResult {
  final bool success;
  final String message;
  final String? filePath;
  final bool queued;

  DownloadResult({
    required this.success,
    required this.message,
    this.filePath,
    this.queued = false,
  });

  @override
  String toString() {
    return 'DownloadResult(success: $success, message: $message, '
        'filePath: $filePath, queued: $queued)';
  }
}
