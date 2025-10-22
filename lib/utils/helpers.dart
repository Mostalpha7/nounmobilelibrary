import 'package:intl/intl.dart';

/// Helper class for common utility functions
class Helpers {
  /// Format file size in bytes to human-readable format
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  /// Format DateTime to readable string
  static String formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM dd, yyyy').format(date);
    }
  }

  /// Format DateTime to full date and time
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy • hh:mm a').format(dateTime);
  }

  /// Extract course level from course code (e.g., CIT 101 -> 100)
  static String extractCourseLevel(String courseCode) {
    final match = RegExp(r'(\d{3})').firstMatch(courseCode);
    if (match != null) {
      final code = match.group(1)!;
      return '${code[0]}00 Level';
    }
    return 'Unknown';
  }

  /// Get course level index (0-3) from course code
  static int getCourseLevelIndex(String courseCode) {
    final level = extractCourseLevel(courseCode);
    switch (level) {
      case '100 Level':
        return 0;
      case '200 Level':
        return 1;
      case '300 Level':
        return 2;
      case '400 Level':
        return 3;
      default:
        return 0;
    }
  }

  /// Validate course code format (e.g., CIT 101, CSC 201)
  static bool isValidCourseCode(String code) {
    return RegExp(r'^[A-Z]{3}\s?\d{3}$').hasMatch(code);
  }

  /// Sanitize filename for safe storage
  static String sanitizeFilename(String filename) {
    return filename
        .replaceAll(RegExp(r'[^\w\s\-\.]'), '')
        .replaceAll(RegExp(r'\s+'), '_');
  }

  /// Get file extension from filename
  static String getFileExtension(String filename) {
    final index = filename.lastIndexOf('.');
    return index != -1 ? filename.substring(index + 1).toLowerCase() : '';
  }

  /// Check if file is PDF
  static bool isPdfFile(String filename) {
    return getFileExtension(filename) == 'pdf';
  }

  /// Calculate download progress percentage
  static int calculateProgress(int downloaded, int total) {
    if (total == 0) return 0;
    return ((downloaded / total) * 100).round().clamp(0, 100);
  }

  /// Truncate text with ellipsis
  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  /// Capitalize first letter of each word
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }

  /// Generate a unique ID based on timestamp
  static String generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  /// Check if string is null or empty
  static bool isNullOrEmpty(String? value) {
    return value == null || value.trim().isEmpty;
  }

  /// Format duration to readable string
  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  /// Get storage path for course level
  static String getStoragePathForLevel(String level) {
    switch (level) {
      case '100 Level':
        return 'courses/100_level';
      case '200 Level':
        return 'courses/200_level';
      case '300 Level':
        return 'courses/300_level';
      case '400 Level':
        return 'courses/400_level';
      default:
        return 'courses/other';
    }
  }

  /// Get asset path for bundled course
  static String getAssetPathForCourse(String courseCode, String level) {
    final levelFolder = level.replaceAll(' Level', '_level').toLowerCase();
    return 'assets/courses/$levelFolder/${sanitizeFilename(courseCode)}.pdf';
  }

  /// Parse search query into keywords
  static List<String> parseSearchQuery(String query) {
    return query
        .toLowerCase()
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
  }

  /// Calculate relevance score for search results
  static int calculateRelevanceScore(
    String query,
    String title,
    String courseCode,
    String description,
  ) {
    final queryLower = query.toLowerCase();
    final titleLower = title.toLowerCase();
    final codeLower = courseCode.toLowerCase();
    final descLower = description.toLowerCase();

    int score = 0;

    // Exact course code match (highest priority)
    if (codeLower == queryLower) {
      score += 100;
    } else if (codeLower.contains(queryLower)) {
      score += 50;
    }

    // Title matches
    if (titleLower == queryLower) {
      score += 80;
    } else if (titleLower.startsWith(queryLower)) {
      score += 60;
    } else if (titleLower.contains(queryLower)) {
      score += 40;
    }

    // Description matches
    if (descLower.contains(queryLower)) {
      score += 20;
    }

    // Multi-word query handling
    final keywords = parseSearchQuery(query);
    for (final keyword in keywords) {
      if (titleLower.contains(keyword)) score += 10;
      if (descLower.contains(keyword)) score += 5;
    }

    return score;
  }
}
