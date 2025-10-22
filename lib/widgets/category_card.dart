import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/category.dart';
import '../utils/constants.dart';

/// Reusable Category Card Widget
class CategoryCard extends StatelessWidget {
  final Category category;
  final VoidCallback onTap;

  const CategoryCard({super.key, required this.category, required this.onTap});

  /// Get Lucide Icon from icon name string
  IconData _getIconData(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'code':
        return LucideIcons.code;
      case 'database':
        return LucideIcons.database;
      case 'server':
        return LucideIcons.server;
      case 'package':
        return LucideIcons.package;
      case 'network':
        return LucideIcons.network;
      case 'globe':
        return LucideIcons.globe;
      case 'monitor':
        return LucideIcons.monitor;
      case 'calculator':
        return LucideIcons.calculator;
      case 'folder':
        return LucideIcons.folder;
      default:
        return LucideIcons.bookOpen;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: AppConstants.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        child: Padding(
          padding: AppConstants.defaultPadding,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getIconData(category.iconName),
                  size: 28,
                  color: AppConstants.primaryColor,
                ),
              ),

              const SizedBox(height: 12),

              // Category Name
              Text(
                category.name,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppConstants.textPrimary,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 4),

              // Course Count Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppConstants.secondaryColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${category.courseCount} ${category.courseCount == 1 ? 'course' : 'courses'}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppConstants.primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
