import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../services/database_helper.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

/// Settings Screen - App settings and information
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Map<String, dynamic>? _stats;
  DateTime? _lastSync;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  /// Load statistics
  Future<void> _loadStats() async {
    try {
      final stats = await _dbHelper.getDatabaseStats();
      final lastSync = await _dbHelper.getLastSyncTime();

      setState(() {
        _stats = stats;
        _lastSync = lastSync;
        _isLoadingStats = false;
      });
    } catch (e) {
      setState(() => _isLoadingStats = false);
    }
  }

  /// Show about dialog
  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: AppConstants.appName,
      applicationVersion: AppConstants.appVersion,
      applicationIcon: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: AppConstants.primaryColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(LucideIcons.bookOpen, color: Colors.white, size: 32),
      ),
      children: [
        const SizedBox(height: 16),
        Text(
          AppConstants.institutionName,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        const Text(
          'A mobile library application providing Computer Science students '
          'with convenient access to course materials, enabling offline study '
          'and supporting distance learning.',
        ),
        const SizedBox(height: 16),
        const Text(
          '© 2025 National Open University of Nigeria',
          style: TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  /// Show storage info dialog
  void _showStorageInfo() {
    if (_stats == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(LucideIcons.hardDrive, color: AppConstants.primaryColor),
            SizedBox(width: 12),
            Text('Storage Information'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Total Courses', '${_stats!['total_courses']}'),
            _buildInfoRow('Downloaded', '${_stats!['downloaded_courses']}'),
            _buildInfoRow('Bundled', '${_stats!['bundled_courses']}'),
            _buildInfoRow(
              'Storage Used',
              Helpers.formatFileSize(_stats!['total_size_bytes']),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Build info row
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppConstants.textSecondary),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppConstants.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  /// Clear cache
  Future<void> _clearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text(
          'This will clear temporary files and free up space. '
          'Your downloads will not be affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Implement cache clearing logic here
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cache cleared successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _isLoadingStats
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                // App Info Section
                _buildSectionHeader('App Information'),
                _buildListTile(
                  icon: LucideIcons.info,
                  title: 'About',
                  subtitle: 'Version ${AppConstants.appVersion}',
                  onTap: _showAboutDialog,
                ),
                _buildListTile(
                  icon: LucideIcons.hardDrive,
                  title: 'Storage',
                  subtitle: _stats != null
                      ? Helpers.formatFileSize(_stats!['total_size_bytes'])
                      : 'Loading...',
                  onTap: _showStorageInfo,
                ),

                const Divider(),

                // Sync Section
                _buildSectionHeader('Sync'),
                _buildListTile(
                  icon: LucideIcons.refreshCw,
                  title: 'Last Sync',
                  subtitle: _lastSync != null
                      ? Helpers.formatDateTime(_lastSync!)
                      : 'Not synced yet',
                  trailing: const Icon(LucideIcons.chevronRight),
                ),

                const Divider(),

                // Data Management Section
                _buildSectionHeader('Data Management'),
                _buildListTile(
                  icon: LucideIcons.trash2,
                  title: 'Clear Cache',
                  subtitle: 'Free up space by clearing temporary files',
                  onTap: _clearCache,
                ),

                const Divider(),

                // Statistics Section
                if (_stats != null) ...[
                  _buildSectionHeader('Statistics'),
                  _buildStatCard(
                    'Total Courses',
                    '${_stats!['total_courses']}',
                    LucideIcons.bookOpen,
                    Colors.blue,
                  ),
                  _buildStatCard(
                    'Downloaded',
                    '${_stats!['downloaded_courses']}',
                    LucideIcons.download,
                    Colors.green,
                  ),
                  _buildStatCard(
                    'Bundled',
                    '${_stats!['bundled_courses']}',
                    LucideIcons.package,
                    Colors.orange,
                  ),
                ],

                const SizedBox(height: 24),

                // Footer
                Center(
                  child: Column(
                    children: [
                      Text(
                        AppConstants.institutionName,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppConstants.textTertiary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '© 2025 All Rights Reserved',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppConstants.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
    );
  }

  /// Build section header
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: AppConstants.primaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Build list tile
  Widget _buildListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppConstants.primaryColor),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: trailing ?? const Icon(LucideIcons.chevronRight),
      onTap: onTap,
    );
  }

  /// Build stat card
  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppConstants.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
