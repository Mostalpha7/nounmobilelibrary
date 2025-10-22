import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../services/database_helper.dart';
import '../services/sync_manager.dart';
import '../utils/constants.dart';
import 'dashboard_screen.dart';

/// Splash Screen - Shows NOUN branding while initializing services
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  String _statusMessage = 'Initializing...';
  bool _hasError = false;

  @override
  void initState() {
    super.initState();

    // Setup fade animation
    _animationController = AnimationController(
      vsync: this,
      duration: AppConstants.longAnimation,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();

    // Initialize app
    _initializeApp();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Initialize application services
  Future<void> _initializeApp() async {
    try {
      // Minimum splash duration for branding
      await Future.delayed(const Duration(seconds: 2));

      // Step 1: Verify database
      setState(() => _statusMessage = 'Loading course catalog...');
      final dbHelper = DatabaseHelper();
      final courses = await dbHelper.getAllCourses();
      print('Splash: Loaded ${courses.length} courses');

      await Future.delayed(const Duration(milliseconds: 500));

      // Step 2: Check for sync
      setState(() => _statusMessage = 'Checking for updates...');
      final syncManager = SyncManager();

      // Perform background sync if needed (don't wait for it)
      syncManager
          .syncCatalog()
          .then((result) {
            if (result.success && result.hasChanges) {
              print('Splash: Sync completed - ${result.totalChanges} changes');
            }
          })
          .catchError((error) {
            print('Splash: Sync error (non-critical) - $error');
          });

      await Future.delayed(const Duration(milliseconds: 500));

      // Navigate to dashboard
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      }
    } catch (e) {
      print('Splash: Initialization error - $e');
      setState(() {
        _hasError = true;
        _statusMessage = 'Initialization failed';
      });

      // Show error for 2 seconds, then retry
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        _initializeApp(); // Retry initialization
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.primaryColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // NOUN Logo/Icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    LucideIcons.bookOpen,
                    size: 60,
                    color: AppConstants.primaryColor,
                  ),
                ),

                const SizedBox(height: 32),

                // App Name
                const Text(
                  AppConstants.appName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                // Institution Name
                const Text(
                  AppConstants.institutionName,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),

                const Spacer(flex: 2),

                // Status Message
                AnimatedSwitcher(
                  duration: AppConstants.mediumAnimation,
                  child: Text(
                    _statusMessage,
                    key: ValueKey(_statusMessage),
                    style: TextStyle(
                      color: _hasError
                          ? AppConstants.errorColor
                          : Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Loading Indicator
                if (!_hasError)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppConstants.secondaryColor,
                      ),
                    ),
                  )
                else
                  Icon(
                    LucideIcons.bellRing400,

                    color: AppConstants.errorColor,
                    size: 24,
                  ),

                const Spacer(flex: 1),

                // Version Info
                Text(
                  'Version ${AppConstants.appVersion}',
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
