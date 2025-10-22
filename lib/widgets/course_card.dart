import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/course.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

/// Reusable Course Card Widget
class CourseCard extends StatelessWidget {
  final Course course;
  final VoidCallback onTap;
  final bool showLevel;

  const CourseCard({
    super.key,
    required this.course,
    required this.onTap,
    this.showLevel = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: AppConstants.cardElevation,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        child: Padding(
          padding: AppConstants.defaultPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row - Course Code and Status Badge
              Row(
                children: [
                  // Course Code Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      course.courseCode,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Status Badges
                  if (course.isBundled)
                    _buildStatusBadge(
                      context,
                      icon: LucideIcons.packageCheck,
                      label: 'Bundled',
                      color: Colors.green,
                    )
                  else if (course.isDownloaded)
                    _buildStatusBadge(
                      context,
                      icon: LucideIcons.download,
                      label: 'Downloaded',
                      color: Colors.blue,
                    )
                  else
                    _buildStatusBadge(
                      context,
                      icon: LucideIcons.cloud,
                      label: 'Cloud',
                      color: Colors.grey,
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // Course Title
              Text(
                course.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppConstants.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 8),

              // Course Description
              Text(
                course.description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppConstants.textSecondary,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 12),

              // Footer Row - Level, Category, File Size
              Row(
                children: [
                  // Level
                  if (showLevel) ...[
                    Icon(
                      LucideIcons.graduationCap,
                      size: 14,
                      color: AppConstants.textTertiary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      course.level,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppConstants.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],

                  // Category
                  Icon(
                    LucideIcons.tag,
                    size: 14,
                    color: AppConstants.textTertiary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      course.category,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppConstants.textTertiary,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  const SizedBox(width: 8),

                  // File Size
                  Icon(
                    LucideIcons.fileText,
                    size: 14,
                    color: AppConstants.textTertiary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    Helpers.formatFileSize(course.fileSize),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppConstants.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build status badge
  Widget _buildStatusBadge(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
