import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/course.dart';
import '../models/category.dart';
import '../models/download_progress.dart';
import '../utils/constants.dart';

/// SQLite Database Helper - Singleton class for database operations
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  /// Get database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize database
  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, AppConstants.databaseName);

    return await openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Create database tables
  Future<void> _onCreate(Database db, int version) async {
    // Courses table
    await db.execute('''
      CREATE TABLE courses (
        id TEXT PRIMARY KEY,
        course_code TEXT NOT NULL UNIQUE,
        title TEXT NOT NULL,
        description TEXT,
        category TEXT NOT NULL,
        level TEXT NOT NULL,
        file_size INTEGER NOT NULL DEFAULT 0,
        is_bundled INTEGER NOT NULL DEFAULT 0,
        firebase_path TEXT,
        local_path TEXT,
        is_downloaded INTEGER NOT NULL DEFAULT 0,
        downloaded_at TEXT,
        last_accessed_at TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Categories table
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL UNIQUE,
        description TEXT,
        icon_name TEXT NOT NULL,
        course_count INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Downloads table
    await db.execute('''
      CREATE TABLE downloads (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        course_id TEXT NOT NULL,
        course_code TEXT NOT NULL,
        title TEXT NOT NULL,
        status TEXT NOT NULL,
        total_bytes INTEGER NOT NULL DEFAULT 0,
        downloaded_bytes INTEGER NOT NULL DEFAULT 0,
        progress REAL NOT NULL DEFAULT 0.0,
        error_message TEXT,
        started_at TEXT NOT NULL,
        completed_at TEXT,
        FOREIGN KEY (course_id) REFERENCES courses (id)
      )
    ''');

    // User preferences table
    await db.execute('''
      CREATE TABLE user_preferences (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Search history table
    await db.execute('''
      CREATE TABLE search_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        query TEXT NOT NULL,
        result_count INTEGER NOT NULL DEFAULT 0,
        searched_at TEXT NOT NULL
      )
    ''');

    // Create indexes for performance
    await db.execute('CREATE INDEX idx_courses_code ON courses(course_code)');
    await db.execute('CREATE INDEX idx_courses_category ON courses(category)');
    await db.execute('CREATE INDEX idx_courses_level ON courses(level)');
    await db.execute(
      'CREATE INDEX idx_courses_downloaded ON courses(is_downloaded)',
    );
    await db.execute('CREATE INDEX idx_downloads_status ON downloads(status)');

    // Initialize default data
    await _initializeDefaultData(db);
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle future schema migrations here
    if (oldVersion < 2) {
      // Example migration for future versions
      // await db.execute('ALTER TABLE courses ADD COLUMN new_field TEXT');
    }
  }

  /// Initialize default categories and bundled courses
  Future<void> _initializeDefaultData(Database db) async {
    // Insert default categories
    final categories = [
      Category(
        id: 'cat_programming',
        name: 'Programming Languages',
        description: 'Programming fundamentals and languages',
        iconName: 'code',
      ),
      Category(
        id: 'cat_data_structures',
        name: 'Data Structures & Algorithms',
        description: 'Core data structures and algorithms',
        iconName: 'database',
      ),
      Category(
        id: 'cat_database',
        name: 'Database Systems',
        description: 'Database design and management',
        iconName: 'server',
      ),
      Category(
        id: 'cat_software_eng',
        name: 'Software Engineering',
        description: 'Software development practices',
        iconName: 'package',
      ),
      Category(
        id: 'cat_networks',
        name: 'Computer Networks',
        description: 'Networking and communications',
        iconName: 'network',
      ),
      Category(
        id: 'cat_web',
        name: 'Web Development',
        description: 'Web technologies and frameworks',
        iconName: 'globe',
      ),
      Category(
        id: 'cat_os',
        name: 'Operating Systems',
        description: 'OS concepts and administration',
        iconName: 'monitor',
      ),
      Category(
        id: 'cat_theory',
        name: 'Theoretical Mathematics',
        description: 'Mathematical foundations',
        iconName: 'calculator',
      ),
      Category(
        id: 'cat_other',
        name: 'Other',
        description: 'Other computer science topics',
        iconName: 'folder',
      ),
    ];

    for (final category in categories) {
      await db.insert('categories', category.toMap());
    }

    // Load and insert bundled courses from JSON
    await _loadBundledCourses(db);

    // Set initial preferences
    await db.insert('user_preferences', {
      'key': 'last_sync',
      'value': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });

    await db.insert('user_preferences', {
      'key': 'download_wifi_only',
      'value': 'false',
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  /// Load bundled courses from JSON file
  Future<void> _loadBundledCourses(Database db) async {
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/data/bundled_courses.json',
      );
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      final List<dynamic> coursesJson = jsonData['courses'] as List;

      for (final courseJson in coursesJson) {
        final course = Course(
          id: courseJson['id'],
          courseCode: courseJson['course_code'],
          title: courseJson['title'],
          description: courseJson['description'] ?? '',
          category: courseJson['category'],
          level: courseJson['level'],
          fileSize: courseJson['file_size'],
          isBundled: courseJson['is_bundled'] ?? false,
          firebasePath: courseJson['firebase_path'],
          localPath: courseJson['local_path'],
          isDownloaded: courseJson['is_bundled'] ?? false,
        );

        await db.insert('courses', course.toMap());
      }
    } catch (e) {
      print('Error loading bundled courses: $e');
      rethrow;
    }
  }

  // ==================== COURSE OPERATIONS ====================

  /// Insert a course
  Future<int> insertCourse(Course course) async {
    final db = await database;
    return await db.insert(
      'courses',
      course.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Update a course
  Future<int> updateCourse(Course course) async {
    final db = await database;
    return await db.update(
      'courses',
      course.toMap(),
      where: 'id = ?',
      whereArgs: [course.id],
    );
  }

  /// Delete a course
  Future<int> deleteCourse(String courseId) async {
    final db = await database;
    return await db.delete('courses', where: 'id = ?', whereArgs: [courseId]);
  }

  /// Get course by ID
  Future<Course?> getCourseById(String courseId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'courses',
      where: 'id = ?',
      whereArgs: [courseId],
    );

    if (maps.isEmpty) return null;
    return Course.fromMap(maps.first);
  }

  /// Get course by course code
  Future<Course?> getCourseByCourseCode(String courseCode) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'courses',
      where: 'course_code = ?',
      whereArgs: [courseCode],
    );

    if (maps.isEmpty) return null;
    return Course.fromMap(maps.first);
  }

  /// Get all courses
  Future<List<Course>> getAllCourses() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'courses',
      orderBy: 'course_code ASC',
    );
    return List.generate(maps.length, (i) => Course.fromMap(maps[i]));
  }

  /// Get courses by category
  Future<List<Course>> getCoursesByCategory(String category) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'courses',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'course_code ASC',
    );
    return List.generate(maps.length, (i) => Course.fromMap(maps[i]));
  }

  /// Get courses by level
  Future<List<Course>> getCoursesByLevel(String level) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'courses',
      where: 'level = ?',
      whereArgs: [level],
      orderBy: 'course_code ASC',
    );
    return List.generate(maps.length, (i) => Course.fromMap(maps[i]));
  }

  /// Get downloaded courses
  Future<List<Course>> getDownloadedCourses() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'courses',
      where: 'is_downloaded = ?',
      whereArgs: [1],
      orderBy: 'downloaded_at DESC',
    );
    return List.generate(maps.length, (i) => Course.fromMap(maps[i]));
  }

  /// Get bundled courses
  Future<List<Course>> getBundledCourses() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'courses',
      where: 'is_bundled = ?',
      whereArgs: [1],
      orderBy: 'course_code ASC',
    );
    return List.generate(maps.length, (i) => Course.fromMap(maps[i]));
  }

  /// Search courses
  Future<List<Course>> searchCourses(String query) async {
    final db = await database;
    final lowerQuery = query.toLowerCase();

    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT * FROM courses
      WHERE LOWER(course_code) LIKE ? 
         OR LOWER(title) LIKE ? 
         OR LOWER(description) LIKE ?
      ORDER BY 
        CASE 
          WHEN LOWER(course_code) = ? THEN 1
          WHEN LOWER(course_code) LIKE ? THEN 2
          WHEN LOWER(title) LIKE ? THEN 3
          ELSE 4
        END,
        course_code ASC
    ''',
      [
        '%$lowerQuery%',
        '%$lowerQuery%',
        '%$lowerQuery%',
        lowerQuery,
        '$lowerQuery%',
        '$lowerQuery%',
      ],
    );

    // Save search history
    await _saveSearchHistory(query, maps.length);

    return List.generate(maps.length, (i) => Course.fromMap(maps[i]));
  }

  /// Update course download status
  Future<int> updateCourseDownloadStatus({
    required String courseId,
    required bool isDownloaded,
    String? localPath,
  }) async {
    final db = await database;
    return await db.update(
      'courses',
      {
        'is_downloaded': isDownloaded ? 1 : 0,
        'local_path': localPath,
        'downloaded_at': isDownloaded ? DateTime.now().toIso8601String() : null,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [courseId],
    );
  }

  /// Update last accessed time
  Future<int> updateLastAccessed(String courseId) async {
    final db = await database;
    return await db.update(
      'courses',
      {
        'last_accessed_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [courseId],
    );
  }

  // ==================== CATEGORY OPERATIONS ====================

  /// Get all categories
  Future<List<Category>> getAllCategories() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      orderBy: 'name ASC',
    );
    return List.generate(maps.length, (i) => Category.fromMap(maps[i]));
  }

  /// Get category by name
  Future<Category?> getCategoryByName(String name) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: 'name = ?',
      whereArgs: [name],
    );

    if (maps.isEmpty) return null;
    return Category.fromMap(maps.first);
  }

  /// Update category course count
  Future<void> updateCategoryCounts() async {
    final db = await database;
    final categories = await getAllCategories();

    for (final category in categories) {
      final count = await db.rawQuery(
        'SELECT COUNT(*) as count FROM courses WHERE category = ?',
        [category.name],
      );

      final courseCount = count.first['count'] as int;

      await db.update(
        'categories',
        {
          'course_count': courseCount,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [category.id],
      );
    }
  }

  // ==================== DOWNLOAD OPERATIONS ====================

  /// Insert download progress
  Future<int> insertDownloadProgress(DownloadProgress progress) async {
    final db = await database;
    return await db.insert('downloads', progress.toMap());
  }

  /// Update download progress
  Future<int> updateDownloadProgress(DownloadProgress progress) async {
    final db = await database;
    return await db.update(
      'downloads',
      progress.toMap(),
      where: 'course_id = ? AND status != ?',
      whereArgs: [progress.courseId, 'completed'],
    );
  }

  /// Get download progress by course ID
  Future<DownloadProgress?> getDownloadProgress(String courseId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'downloads',
      where: 'course_id = ?',
      whereArgs: [courseId],
      orderBy: 'started_at DESC',
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return DownloadProgress.fromMap(maps.first);
  }

  /// Get all active downloads
  Future<List<DownloadProgress>> getActiveDownloads() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'downloads',
      where: 'status IN (?, ?)',
      whereArgs: ['queued', 'downloading'],
      orderBy: 'started_at DESC',
    );
    return List.generate(maps.length, (i) => DownloadProgress.fromMap(maps[i]));
  }

  /// Delete download record
  Future<int> deleteDownloadProgress(String courseId) async {
    final db = await database;
    return await db.delete(
      'downloads',
      where: 'course_id = ?',
      whereArgs: [courseId],
    );
  }

  // ==================== PREFERENCES OPERATIONS ====================

  /// Set preference
  Future<int> setPreference(String key, String value) async {
    final db = await database;
    return await db.insert('user_preferences', {
      'key': key,
      'value': value,
      'updated_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Get preference
  Future<String?> getPreference(String key) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'user_preferences',
      where: 'key = ?',
      whereArgs: [key],
    );

    if (maps.isEmpty) return null;
    return maps.first['value'] as String;
  }

  /// Get last sync time
  Future<DateTime?> getLastSyncTime() async {
    final value = await getPreference('last_sync');
    if (value == null) return null;
    return DateTime.parse(value);
  }

  /// Update last sync time
  Future<void> updateLastSyncTime() async {
    await setPreference('last_sync', DateTime.now().toIso8601String());
  }

  // ==================== SEARCH HISTORY OPERATIONS ====================

  /// Save search query to history
  Future<void> _saveSearchHistory(String query, int resultCount) async {
    final db = await database;
    await db.insert('search_history', {
      'query': query,
      'result_count': resultCount,
      'searched_at': DateTime.now().toIso8601String(),
    });
  }

  /// Get recent search history
  Future<List<String>> getRecentSearches({int limit = 10}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'search_history',
      orderBy: 'searched_at DESC',
      limit: limit,
      distinct: true,
    );

    return maps.map((m) => m['query'] as String).toList();
  }

  /// Clear search history
  Future<int> clearSearchHistory() async {
    final db = await database;
    return await db.delete('search_history');
  }

  // ==================== UTILITY OPERATIONS ====================

  /// Get database statistics
  Future<Map<String, dynamic>> getDatabaseStats() async {
    final db = await database;

    final totalCourses = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM courses'),
    );

    final downloadedCourses = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM courses WHERE is_downloaded = 1'),
    );

    final bundledCourses = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM courses WHERE is_bundled = 1'),
    );

    final totalSize = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT SUM(file_size) FROM courses WHERE is_downloaded = 1 OR is_bundled = 1',
      ),
    );

    return {
      'total_courses': totalCourses ?? 0,
      'downloaded_courses': downloadedCourses ?? 0,
      'bundled_courses': bundledCourses ?? 0,
      'total_size_bytes': totalSize ?? 0,
    };
  }

  /// Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  /// Delete database (for testing/debugging)
  Future<void> deleteDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, AppConstants.databaseName);
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }
}
