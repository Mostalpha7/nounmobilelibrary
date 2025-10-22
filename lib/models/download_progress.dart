/// Represents the state and progress of a course download
class DownloadProgress {
  final String courseId;
  final String courseCode;
  final String title;
  final DownloadStatus status;
  final int totalBytes;
  final int downloadedBytes;
  final double progress; // 0.0 to 1.0
  final String? errorMessage;
  final DateTime startedAt;
  final DateTime? completedAt;

  DownloadProgress({
    required this.courseId,
    required this.courseCode,
    required this.title,
    required this.status,
    this.totalBytes = 0,
    this.downloadedBytes = 0,
    double? progress,
    this.errorMessage,
    DateTime? startedAt,
    this.completedAt,
  }) : progress = progress ?? 0.0,
       startedAt = startedAt ?? DateTime.now();

  /// Get progress as percentage (0-100)
  int get progressPercentage => (progress * 100).round().clamp(0, 100);

  /// Check if download is in progress
  bool get isInProgress => status == DownloadStatus.downloading;

  /// Check if download is complete
  bool get isComplete => status == DownloadStatus.completed;

  /// Check if download has failed
  bool get hasFailed => status == DownloadStatus.failed;

  /// Check if download is paused
  bool get isPaused => status == DownloadStatus.paused;

  /// Check if download is queued
  bool get isQueued => status == DownloadStatus.queued;

  /// Create DownloadProgress from database map
  factory DownloadProgress.fromMap(Map<String, dynamic> map) {
    return DownloadProgress(
      courseId: map['course_id'] as String,
      courseCode: map['course_code'] as String,
      title: map['title'] as String,
      status: DownloadStatus.values.firstWhere(
        (e) => e.toString() == 'DownloadStatus.${map['status']}',
        orElse: () => DownloadStatus.queued,
      ),
      totalBytes: map['total_bytes'] as int? ?? 0,
      downloadedBytes: map['downloaded_bytes'] as int? ?? 0,
      progress: (map['progress'] as num?)?.toDouble() ?? 0.0,
      errorMessage: map['error_message'] as String?,
      startedAt: DateTime.parse(map['started_at'] as String),
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'] as String)
          : null,
    );
  }

  /// Convert DownloadProgress to database map
  Map<String, dynamic> toMap() {
    return {
      'course_id': courseId,
      'course_code': courseCode,
      'title': title,
      'status': status.name,
      'total_bytes': totalBytes,
      'downloaded_bytes': downloadedBytes,
      'progress': progress,
      'error_message': errorMessage,
      'started_at': startedAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  /// Create a copy with modified fields
  DownloadProgress copyWith({
    String? courseId,
    String? courseCode,
    String? title,
    DownloadStatus? status,
    int? totalBytes,
    int? downloadedBytes,
    double? progress,
    String? errorMessage,
    DateTime? startedAt,
    DateTime? completedAt,
  }) {
    return DownloadProgress(
      courseId: courseId ?? this.courseId,
      courseCode: courseCode ?? this.courseCode,
      title: title ?? this.title,
      status: status ?? this.status,
      totalBytes: totalBytes ?? this.totalBytes,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      progress: progress ?? this.progress,
      errorMessage: errorMessage ?? this.errorMessage,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  String toString() {
    return 'DownloadProgress(courseId: $courseId, courseCode: $courseCode, '
        'status: $status, progress: ${progressPercentage}%)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DownloadProgress &&
        other.courseId == courseId &&
        other.status == status;
  }

  @override
  int get hashCode => courseId.hashCode ^ status.hashCode;
}

/// Download status enumeration
enum DownloadStatus {
  queued,
  downloading,
  paused,
  completed,
  failed,
  cancelled,
}

/// Extension for DownloadStatus
extension DownloadStatusExtension on DownloadStatus {
  /// Get user-friendly display name
  String get displayName {
    switch (this) {
      case DownloadStatus.queued:
        return 'Queued';
      case DownloadStatus.downloading:
        return 'Downloading';
      case DownloadStatus.paused:
        return 'Paused';
      case DownloadStatus.completed:
        return 'Completed';
      case DownloadStatus.failed:
        return 'Failed';
      case DownloadStatus.cancelled:
        return 'Cancelled';
    }
  }

  /// Check if status is terminal (completed, failed, cancelled)
  bool get isTerminal {
    return this == DownloadStatus.completed ||
        this == DownloadStatus.failed ||
        this == DownloadStatus.cancelled;
  }
}
