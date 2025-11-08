import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
// import 'package:firebase_storage/firebase_storage.dart';
import '../models/course.dart';
import '../utils/constants.dart';

/// Firebase Service - Handles all Firebase operations
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  // final FirebaseStorage _storage = FirebaseStorage.instance;

  User? _currentUser;

  /// Initialize Firebase Authentication (Anonymous)
  Future<void> initializeAuth() async {
    try {
      // Check if user is already signed in
      _currentUser = _auth.currentUser;

      if (_currentUser == null) {
        // Sign in anonymously
        final userCredential = await _auth.signInAnonymously();
        _currentUser = userCredential.user;
        print('Firebase: Signed in anonymously - ${_currentUser?.uid}');
      } else {
        print('Firebase: Already signed in - ${_currentUser?.uid}');
      }
    } catch (e) {
      print('Firebase Auth Error: $e');
      rethrow;
    }
  }

  /// Get current user
  User? get currentUser => _currentUser;

  /// Check if user is authenticated
  bool get isAuthenticated => _currentUser != null;

  // ==================== COURSE CATALOG OPERATIONS ====================

  /// Fetch all courses from Firebase Realtime Database
  Future<List<Course>> fetchAllCourses() async {
    try {
      final DatabaseReference coursesRef = _database.ref(
        AppConstants.coursesCollection,
      );

      final DataSnapshot snapshot = await coursesRef.get();

      if (!snapshot.exists || snapshot.value == null) {
        print('Firebase: No courses found in database');
        return [];
      }

      final List<Course> courses = [];
      final data = snapshot.value as Map<dynamic, dynamic>;

      data.forEach((key, value) {
        try {
          final courseData = Map<String, dynamic>.from(value as Map);
          courseData['id'] = key; // Use Firebase key as ID

          final course = Course(
            id: courseData['id'] ?? key,
            courseCode: courseData['course_code'] ?? '',
            title: courseData['title'] ?? '',
            description: courseData['description'] ?? '',
            category: courseData['category'] ?? 'Other',
            level: courseData['level'] ?? '100 Level',
            fileSize: courseData['file_size'] ?? 0,
            isBundled: false, // Firebase courses are not bundled
            firebasePath: courseData['firebase_path'],
            isDownloaded: false,
          );

          courses.add(course);
        } catch (e) {
          print('Error parsing course $key: $e');
        }
      });

      print('Firebase: Fetched ${courses.length} courses');
      return courses;
    } catch (e) {
      print('Error fetching courses from Firebase: $e');
      return [];
    }
  }

  /// Fetch courses by category
  Future<List<Course>> fetchCoursesByCategory(String category) async {
    try {
      final DatabaseReference coursesRef = _database.ref(
        AppConstants.coursesCollection,
      );

      final Query query = coursesRef.orderByChild('category').equalTo(category);

      final DataSnapshot snapshot = await query.get();

      if (!snapshot.exists || snapshot.value == null) {
        return [];
      }

      final List<Course> courses = [];
      final data = snapshot.value as Map<dynamic, dynamic>;

      data.forEach((key, value) {
        try {
          final courseData = Map<String, dynamic>.from(value as Map);
          courseData['id'] = key;

          final course = Course(
            id: courseData['id'] ?? key,
            courseCode: courseData['course_code'] ?? '',
            title: courseData['title'] ?? '',
            description: courseData['description'] ?? '',
            category: courseData['category'] ?? 'Other',
            level: courseData['level'] ?? '100 Level',
            fileSize: courseData['file_size'] ?? 0,
            isBundled: false,
            firebasePath: courseData['firebase_path'],
            isDownloaded: false,
          );

          courses.add(course);
        } catch (e) {
          print('Error parsing course $key: $e');
        }
      });

      return courses;
    } catch (e) {
      print('Error fetching courses by category: $e');
      return [];
    }
  }

  /// Fetch courses by level
  Future<List<Course>> fetchCoursesByLevel(String level) async {
    try {
      final DatabaseReference coursesRef = _database.ref(
        AppConstants.coursesCollection,
      );

      final Query query = coursesRef.orderByChild('level').equalTo(level);

      final DataSnapshot snapshot = await query.get();

      if (!snapshot.exists || snapshot.value == null) {
        return [];
      }

      final List<Course> courses = [];
      final data = snapshot.value as Map<dynamic, dynamic>;

      data.forEach((key, value) {
        try {
          final courseData = Map<String, dynamic>.from(value as Map);
          courseData['id'] = key;

          final course = Course(
            id: courseData['id'] ?? key,
            courseCode: courseData['course_code'] ?? '',
            title: courseData['title'] ?? '',
            description: courseData['description'] ?? '',
            category: courseData['category'] ?? 'Other',
            level: courseData['level'] ?? '100 Level',
            fileSize: courseData['file_size'] ?? 0,
            isBundled: false,
            firebasePath: courseData['firebase_path'],
            isDownloaded: false,
          );

          courses.add(course);
        } catch (e) {
          print('Error parsing course $key: $e');
        }
      });

      return courses;
    } catch (e) {
      print('Error fetching courses by level: $e');
      return [];
    }
  }

  /// Add a new course to Firebase (Admin operation - optional)
  Future<void> addCourse(Course course) async {
    try {
      final DatabaseReference courseRef = _database.ref(
        '${AppConstants.coursesCollection}/${course.id}',
      );

      await courseRef.set({
        'course_code': course.courseCode,
        'title': course.title,
        'description': course.description,
        'category': course.category,
        'level': course.level,
        'file_size': course.fileSize,
        'firebase_path': course.firebasePath,
        'created_at': course.createdAt.toIso8601String(),
        'updated_at': course.updatedAt.toIso8601String(),
      });

      print('Firebase: Course ${course.courseCode} added successfully');
    } catch (e) {
      print('Error adding course to Firebase: $e');
      rethrow;
    }
  }

  /// Update course metadata in Firebase (Admin operation - optional)
  Future<void> updateCourse(Course course) async {
    try {
      final DatabaseReference courseRef = _database.ref(
        '${AppConstants.coursesCollection}/${course.id}',
      );

      await courseRef.update({
        'title': course.title,
        'description': course.description,
        'category': course.category,
        'level': course.level,
        'file_size': course.fileSize,
        'updated_at': DateTime.now().toIso8601String(),
      });

      print('Firebase: Course ${course.courseCode} updated successfully');
    } catch (e) {
      print('Error updating course in Firebase: $e');
      rethrow;
    }
  }

  /// Delete course from Firebase (Admin operation - optional)
  Future<void> deleteCourse(String courseId) async {
    try {
      final DatabaseReference courseRef = _database.ref(
        '${AppConstants.coursesCollection}/$courseId',
      );

      await courseRef.remove();

      print('Firebase: Course $courseId deleted successfully');
    } catch (e) {
      print('Error deleting course from Firebase: $e');
      rethrow;
    }
  }

  // ==================== STORAGE OPERATIONS ====================

  /// Get download URL for a course PDF
  /// Supports both Firebase Storage paths and direct URLs (e.g., Google Drive)
  Future<String?> getDownloadUrl(String firebasePath) async {
    try {
      // Check if it's already a direct URL (e.g., from Google Drive)
      // if (firebasePath.startsWith('http://') ||
      //     firebasePath.startsWith('https://')) {
      return firebasePath;
      // print('Firebase: Using direct URL - $firebasePath');
      // }

      // Otherwise, get URL from Firebase Storage
      // final Reference ref = _storage.ref(firebasePath);
      // final String downloadUrl = await ref.getDownloadURL();
      // return downloadUrl;
    } catch (e) {
      print('Error getting download URL: $e');
      return null;
    }
  }

  /// Get file metadata
  // Future<FullMetadata?> getFileMetadata(String firebasePath) async {
  //   try {
  //     final Reference ref = _storage.ref(firebasePath);
  //     final FullMetadata metadata = await ref.getMetadata();
  //     return metadata;
  //   } catch (e) {
  //     print('Error getting file metadata: $e');
  //     return null;
  //   }
  // }

  /// Upload a course PDF (Admin operation - optional)
  // Future<String?> uploadCoursePdf({
  //   required String filePath,
  //   required String courseId,
  //   required String level,
  //   Function(double)? onProgress,
  // }) async {
  //   try {
  //     // Construct storage path based on level
  //     final String storagePath =
  //         '${AppConstants.coursesStoragePath}/${level.toLowerCase().replaceAll(' ', '_')}/$courseId.pdf';

  //     final Reference ref = _storage.ref(storagePath);
  //     final UploadTask uploadTask = ref.putFile(
  //       filePath as File,
  //       SettableMetadata(
  //         contentType: 'application/pdf',
  //         customMetadata: {
  //           'courseId': courseId,
  //           'uploadedAt': DateTime.now().toIso8601String(),
  //         },
  //       ),
  //     );

  //     // Track upload progress
  //     uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
  //       final progress = snapshot.bytesTransferred / snapshot.totalBytes;
  //       onProgress?.call(progress);
  //     });

  //     final TaskSnapshot taskSnapshot = await uploadTask;
  //     final String downloadUrl = await taskSnapshot.ref.getDownloadURL();

  //     print('Firebase: File uploaded successfully - $downloadUrl');
  //     return downloadUrl;
  //   } catch (e) {
  //     print('Error uploading file to Firebase Storage: $e');
  //     return null;
  //   }
  // }

  /// Delete course PDF from storage (Admin operation - optional)
  // Future<void> deleteCoursePdf(String firebasePath) async {
  //   try {
  //     final Reference ref = _storage.ref(firebasePath);
  //     await ref.delete();
  //     print('Firebase: File deleted successfully - $firebasePath');
  //   } catch (e) {
  //     print('Error deleting file from Firebase Storage: $e');
  //     rethrow;
  //   }
  // }

  // ==================== UTILITY OPERATIONS ====================

  /// Check Firebase connection status
  Future<bool> checkConnection() async {
    try {
      final DatabaseReference connectedRef = _database.ref('.info/connected');
      final DataSnapshot snapshot = await connectedRef.get();
      return snapshot.value == true;
    } catch (e) {
      print('Error checking Firebase connection: $e');
      return false;
    }
  }

  /// Get server timestamp
  Future<DateTime> getServerTimestamp() async {
    try {
      final DatabaseReference timestampRef = _database.ref('timestamp');
      await timestampRef.set(ServerValue.timestamp);
      final DataSnapshot snapshot = await timestampRef.get();
      final int timestamp = snapshot.value as int;
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    } catch (e) {
      print('Error getting server timestamp: $e');
      return DateTime.now();
    }
  }

  /// Sign out (for testing purposes)
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _currentUser = null;
      print('Firebase: Signed out successfully');
    } catch (e) {
      print('Error signing out: $e');
    }
  }
}
