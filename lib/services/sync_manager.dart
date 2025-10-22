import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/course.dart';
import '../utils/constants.dart';
import 'database_helper.dart';
import 'firebase_service.dart';

/// Sync Manager - Coordinates data synchronization between local DB and Firebase
class SyncManager {
  static final SyncManager _instance = SyncManager._internal();
  factory SyncManager() => _instance;
  SyncManager._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper();
  final FirebaseService _firebaseService = FirebaseService();
  final Connectivity _connectivity = Connectivity();

  bool _isSyncing = false;
  DateTime? _lastSyncTime;

  /// Check if sync is currently in progress
  bool get isSyncing => _isSyncing;

  /// Get last sync time
  DateTime? get lastSyncTime => _lastSyncTime;

  // ==================== CONNECTIVITY CHECKS ====================

  /// Check if device has internet connectivity
  Future<bool> hasInternetConnection() async {
    try {
      final List<ConnectivityResult> connectivityResult = await _connectivity
          .checkConnectivity();

      return connectivityResult.contains(ConnectivityResult.mobile) ||
          connectivityResult.contains(ConnectivityResult.wifi) ||
          connectivityResult.contains(ConnectivityResult.ethernet);
    } catch (e) {
      print('Error checking connectivity: $e');
      return false;
    }
  }

  /// Check if Firebase is reachable
  Future<bool> isFirebaseReachable() async {
    try {
      return await _firebaseService.checkConnection();
    } catch (e) {
      print('Error checking Firebase connection: $e');
      return false;
    }
  }

  // ==================== SYNC OPERATIONS ====================

  /// Perform full catalog synchronization
  Future<SyncResult> syncCatalog({bool forceSync = false}) async {
    if (_isSyncing) {
      return SyncResult(
        success: false,
        message: 'Sync already in progress',
        coursesAdded: 0,
        coursesUpdated: 0,
      );
    }

    _isSyncing = true;

    try {
      // Check internet connectivity
      if (!await hasInternetConnection()) {
        _isSyncing = false;
        return SyncResult(
          success: false,
          message: 'No internet connection',
          coursesAdded: 0,
          coursesUpdated: 0,
        );
      }

      // Check if sync is needed (based on time interval)
      if (!forceSync) {
        final lastSync = await _dbHelper.getLastSyncTime();
        if (lastSync != null) {
          final timeSinceLastSync = DateTime.now().difference(lastSync);
          if (timeSinceLastSync < AppConstants.syncInterval) {
            _isSyncing = false;
            return SyncResult(
              success: true,
              message: 'Catalog is up to date',
              coursesAdded: 0,
              coursesUpdated: 0,
              skipped: true,
            );
          }
        }
      }

      print('SyncManager: Starting catalog synchronization...');

      // Fetch courses from Firebase
      final List<Course> firebaseCourses = await _firebaseService
          .fetchAllCourses();

      if (firebaseCourses.isEmpty) {
        print('SyncManager: No courses found in Firebase');
        _isSyncing = false;
        return SyncResult(
          success: true,
          message: 'No courses available in cloud',
          coursesAdded: 0,
          coursesUpdated: 0,
        );
      }

      int coursesAdded = 0;
      int coursesUpdated = 0;

      // Process each course
      for (final firebaseCourse in firebaseCourses) {
        try {
          // Check if course exists locally
          final existingCourse = await _dbHelper.getCourseByCourseCode(
            firebaseCourse.courseCode,
          );

          if (existingCourse == null) {
            // New course - insert
            await _dbHelper.insertCourse(firebaseCourse);
            coursesAdded++;
            print('SyncManager: Added ${firebaseCourse.courseCode}');
          } else {
            // Existing course - update metadata only (preserve download status)
            final updatedCourse = existingCourse.copyWith(
              title: firebaseCourse.title,
              description: firebaseCourse.description,
              category: firebaseCourse.category,
              level: firebaseCourse.level,
              fileSize: firebaseCourse.fileSize,
              firebasePath: firebaseCourse.firebasePath,
              updatedAt: DateTime.now(),
            );

            await _dbHelper.updateCourse(updatedCourse);
            coursesUpdated++;
            print('SyncManager: Updated ${firebaseCourse.courseCode}');
          }
        } catch (e) {
          print(
            'SyncManager: Error processing course ${firebaseCourse.courseCode}: $e',
          );
        }
      }

      // Update category counts
      await _dbHelper.updateCategoryCounts();

      // Update last sync time
      await _dbHelper.updateLastSyncTime();
      _lastSyncTime = DateTime.now();

      print(
        'SyncManager: Sync completed - Added: $coursesAdded, Updated: $coursesUpdated',
      );

      _isSyncing = false;

      return SyncResult(
        success: true,
        message: 'Sync completed successfully',
        coursesAdded: coursesAdded,
        coursesUpdated: coursesUpdated,
      );
    } catch (e) {
      print('SyncManager: Sync failed - $e');
      _isSyncing = false;

      return SyncResult(
        success: false,
        message: 'Sync failed: $e',
        coursesAdded: 0,
        coursesUpdated: 0,
      );
    }
  }

  /// Sync specific category
  Future<SyncResult> syncCategory(String category) async {
    try {
      print('SyncManager: Syncing category: $category');

      // Check connectivity
      if (!await hasInternetConnection()) {
        return SyncResult(
          success: false,
          message: 'No internet connection',
          coursesAdded: 0,
          coursesUpdated: 0,
        );
      }

      // Fetch courses for this category from Firebase
      final List<Course> firebaseCourses = await _firebaseService
          .fetchCoursesByCategory(category);

      int coursesAdded = 0;
      int coursesUpdated = 0;

      for (final firebaseCourse in firebaseCourses) {
        final existingCourse = await _dbHelper.getCourseByCourseCode(
          firebaseCourse.courseCode,
        );

        if (existingCourse == null) {
          await _dbHelper.insertCourse(firebaseCourse);
          coursesAdded++;
        } else {
          final updatedCourse = existingCourse.copyWith(
            title: firebaseCourse.title,
            description: firebaseCourse.description,
            fileSize: firebaseCourse.fileSize,
            firebasePath: firebaseCourse.firebasePath,
            updatedAt: DateTime.now(),
          );
          await _dbHelper.updateCourse(updatedCourse);
          coursesUpdated++;
        }
      }

      // Update category count
      await _dbHelper.updateCategoryCounts();

      return SyncResult(
        success: true,
        message: 'Category synced successfully',
        coursesAdded: coursesAdded,
        coursesUpdated: coursesUpdated,
      );
    } catch (e) {
      print('SyncManager: Category sync failed - $e');
      return SyncResult(
        success: false,
        message: 'Category sync failed: $e',
        coursesAdded: 0,
        coursesUpdated: 0,
      );
    }
  }

  /// Sync specific level
  Future<SyncResult> syncLevel(String level) async {
    try {
      print('SyncManager: Syncing level: $level');

      // Check connectivity
      if (!await hasInternetConnection()) {
        return SyncResult(
          success: false,
          message: 'No internet connection',
          coursesAdded: 0,
          coursesUpdated: 0,
        );
      }

      // Fetch courses for this level from Firebase
      final List<Course> firebaseCourses = await _firebaseService
          .fetchCoursesByLevel(level);

      int coursesAdded = 0;
      int coursesUpdated = 0;

      for (final firebaseCourse in firebaseCourses) {
        final existingCourse = await _dbHelper.getCourseByCourseCode(
          firebaseCourse.courseCode,
        );

        if (existingCourse == null) {
          await _dbHelper.insertCourse(firebaseCourse);
          coursesAdded++;
        } else {
          final updatedCourse = existingCourse.copyWith(
            title: firebaseCourse.title,
            description: firebaseCourse.description,
            fileSize: firebaseCourse.fileSize,
            firebasePath: firebaseCourse.firebasePath,
            updatedAt: DateTime.now(),
          );
          await _dbHelper.updateCourse(updatedCourse);
          coursesUpdated++;
        }
      }

      // Update category counts
      await _dbHelper.updateCategoryCounts();

      return SyncResult(
        success: true,
        message: 'Level synced successfully',
        coursesAdded: coursesAdded,
        coursesUpdated: coursesUpdated,
      );
    } catch (e) {
      print('SyncManager: Level sync failed - $e');
      return SyncResult(
        success: false,
        message: 'Level sync failed: $e',
        coursesAdded: 0,
        coursesUpdated: 0,
      );
    }
  }

  // ==================== UTILITY OPERATIONS ====================

  /// Check if sync is needed
  Future<bool> shouldSync() async {
    try {
      final lastSync = await _dbHelper.getLastSyncTime();
      if (lastSync == null) return true;

      final timeSinceLastSync = DateTime.now().difference(lastSync);
      return timeSinceLastSync >= AppConstants.syncInterval;
    } catch (e) {
      print('Error checking sync requirement: $e');
      return true;
    }
  }

  /// Get time until next sync
  Future<Duration?> timeUntilNextSync() async {
    try {
      final lastSync = await _dbHelper.getLastSyncTime();
      if (lastSync == null) return Duration.zero;

      final timeSinceLastSync = DateTime.now().difference(lastSync);
      final timeRemaining = AppConstants.syncInterval - timeSinceLastSync;

      return timeRemaining.isNegative ? Duration.zero : timeRemaining;
    } catch (e) {
      print('Error calculating next sync time: $e');
      return null;
    }
  }

  /// Cancel sync (if possible)
  void cancelSync() {
    if (_isSyncing) {
      print('SyncManager: Sync cancellation requested');
      _isSyncing = false;
    }
  }

  /// Initialize sync manager and load last sync time
  Future<void> initialize() async {
    try {
      _lastSyncTime = await _dbHelper.getLastSyncTime();
      print('SyncManager: Initialized - Last sync: $_lastSyncTime');
    } catch (e) {
      print('SyncManager: Initialization error - $e');
    }
  }
}

/// Result of a sync operation
class SyncResult {
  final bool success;
  final String message;
  final int coursesAdded;
  final int coursesUpdated;
  final bool skipped;

  SyncResult({
    required this.success,
    required this.message,
    required this.coursesAdded,
    required this.coursesUpdated,
    this.skipped = false,
  });

  /// Check if any changes were made
  bool get hasChanges => coursesAdded > 0 || coursesUpdated > 0;

  /// Get total changes
  int get totalChanges => coursesAdded + coursesUpdated;

  @override
  String toString() {
    return 'SyncResult(success: $success, message: $message, '
        'added: $coursesAdded, updated: $coursesUpdated, skipped: $skipped)';
  }
}
