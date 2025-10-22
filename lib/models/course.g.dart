// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'course.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Course _$CourseFromJson(Map<String, dynamic> json) => Course(
  id: json['id'] as String,
  courseCode: json['courseCode'] as String,
  title: json['title'] as String,
  description: json['description'] as String,
  category: json['category'] as String,
  level: json['level'] as String,
  fileSize: (json['fileSize'] as num).toInt(),
  isBundled: json['isBundled'] as bool? ?? false,
  firebasePath: json['firebasePath'] as String?,
  localPath: json['localPath'] as String?,
  isDownloaded: json['isDownloaded'] as bool? ?? false,
  downloadedAt: json['downloadedAt'] == null
      ? null
      : DateTime.parse(json['downloadedAt'] as String),
  lastAccessedAt: json['lastAccessedAt'] == null
      ? null
      : DateTime.parse(json['lastAccessedAt'] as String),
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$CourseToJson(Course instance) => <String, dynamic>{
  'id': instance.id,
  'courseCode': instance.courseCode,
  'title': instance.title,
  'description': instance.description,
  'category': instance.category,
  'level': instance.level,
  'fileSize': instance.fileSize,
  'isBundled': instance.isBundled,
  'firebasePath': instance.firebasePath,
  'localPath': instance.localPath,
  'isDownloaded': instance.isDownloaded,
  'downloadedAt': instance.downloadedAt?.toIso8601String(),
  'lastAccessedAt': instance.lastAccessedAt?.toIso8601String(),
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
};
