import 'package:json_annotation/json_annotation.dart';

part 'course.g.dart';

/// Represents a course/learning resource in the library
@JsonSerializable()
class Course {
  final String id;
  final String courseCode;
  final String title;
  final String description;
  final String category;
  final String level;
  final int fileSize; // in bytes
  final bool isBundled; // true if included in app assets
  final String? firebasePath; // path in Firebase Storage
  final String? localPath; // local file path if downloaded
  final bool isDownloaded;
  final DateTime? downloadedAt;
  final DateTime? lastAccessedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Course({
    required this.id,
    required this.courseCode,
    required this.title,
    required this.description,
    required this.category,
    required this.level,
    required this.fileSize,
    this.isBundled = false,
    this.firebasePath,
    this.localPath,
    this.isDownloaded = false,
    this.downloadedAt,
    this.lastAccessedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  /// Create Course from JSON
  factory Course.fromJson(Map<String, dynamic> json) => _$CourseFromJson(json);

  /// Convert Course to JSON
  Map<String, dynamic> toJson() => _$CourseToJson(this);

  /// Create Course from database map
  factory Course.fromMap(Map<String, dynamic> map) {
    return Course(
      id: map['id'] as String,
      courseCode: map['course_code'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      category: map['category'] as String,
      level: map['level'] as String,
      fileSize: map['file_size'] as int,
      isBundled: (map['is_bundled'] as int) == 1,
      firebasePath: map['firebase_path'] as String?,
      localPath: map['local_path'] as String?,
      isDownloaded: (map['is_downloaded'] as int) == 1,
      downloadedAt: map['downloaded_at'] != null
          ? DateTime.parse(map['downloaded_at'] as String)
          : null,
      lastAccessedAt: map['last_accessed_at'] != null
          ? DateTime.parse(map['last_accessed_at'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Convert Course to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'course_code': courseCode,
      'title': title,
      'description': description,
      'category': category,
      'level': level,
      'file_size': fileSize,
      'is_bundled': isBundled ? 1 : 0,
      'firebase_path': firebasePath,
      'local_path': localPath,
      'is_downloaded': isDownloaded ? 1 : 0,
      'downloaded_at': downloadedAt?.toIso8601String(),
      'last_accessed_at': lastAccessedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy with modified fields
  Course copyWith({
    String? id,
    String? courseCode,
    String? title,
    String? description,
    String? category,
    String? level,
    int? fileSize,
    bool? isBundled,
    String? firebasePath,
    String? localPath,
    bool? isDownloaded,
    DateTime? downloadedAt,
    DateTime? lastAccessedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Course(
      id: id ?? this.id,
      courseCode: courseCode ?? this.courseCode,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      level: level ?? this.level,
      fileSize: fileSize ?? this.fileSize,
      isBundled: isBundled ?? this.isBundled,
      firebasePath: firebasePath ?? this.firebasePath,
      localPath: localPath ?? this.localPath,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      downloadedAt: downloadedAt ?? this.downloadedAt,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if course is available (bundled or downloaded)
  bool get isAvailable => isBundled || isDownloaded;

  /// Get display name (course code + title)
  String get displayName => '$courseCode: $title';

  @override
  String toString() {
    return 'Course(id: $id, courseCode: $courseCode, title: $title, '
        'category: $category, level: $level, isBundled: $isBundled, '
        'isDownloaded: $isDownloaded)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Course && other.id == id && other.courseCode == courseCode;
  }

  @override
  int get hashCode => id.hashCode ^ courseCode.hashCode;
}
