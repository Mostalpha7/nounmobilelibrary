import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../utils/constants.dart';
import 'browse_screen.dart';
import 'downloads_screen.dart';
import 'settings_screen.dart';

/// Dashboard Screen - Main navigation hub with bottom navigation bar
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  // Screens for each tab
  final List<Widget> _screens = [
    const BrowseScreen(),
    const DownloadsScreen(),
    const SettingsScreen(),
  ];

  // Tab labels
  final List<String> _tabLabels = ['Browse', 'Downloads', 'Settings'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: Colors.white,
        indicatorColor: AppConstants.primaryColor.withOpacity(0.1),
        elevation: 8,
        height: 70,
        destinations: [
          NavigationDestination(
            icon: const Icon(LucideIcons.bookOpen),
            selectedIcon: Icon(
              LucideIcons.bookOpen,
              color: AppConstants.primaryColor,
            ),
            label: _tabLabels[0],
          ),
          NavigationDestination(
            icon: const Icon(LucideIcons.download),
            selectedIcon: Icon(
              LucideIcons.download,
              color: AppConstants.primaryColor,
            ),
            label: _tabLabels[1],
          ),
          NavigationDestination(
            icon: const Icon(LucideIcons.settings),
            selectedIcon: Icon(
              LucideIcons.settings,
              color: AppConstants.primaryColor,
            ),
            label: _tabLabels[2],
          ),
        ],
      ),
    );
  }
}
