import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:nounmobilelibrary/firebase_options.dart';
import 'package:provider/provider.dart';
import 'services/database_helper.dart';
import 'services/firebase_service.dart';
import 'services/sync_manager.dart';
import 'screens/splash_screen.dart';
import 'utils/constants.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations (portrait only)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize services
  await _initializeServices();

  // Run the app
  runApp(const NOUNMobileLibraryApp());
}

/// Initialize core services
Future<void> _initializeServices() async {
  try {
    // Initialize Firebase Auth (anonymous sign-in)
    final firebaseService = FirebaseService();
    await firebaseService.initializeAuth();

    // Initialize database (creates tables and loads bundled courses)
    final dbHelper = DatabaseHelper();
    await dbHelper.database; // Triggers initialization

    // Initialize sync manager
    final syncManager = SyncManager();
    await syncManager.initialize();

    print('Main: All services initialized successfully');
  } catch (e) {
    print('Main: Error initializing services - $e');
  }
}

/// Root widget of the application
class NOUNMobileLibraryApp extends StatelessWidget {
  const NOUNMobileLibraryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Add providers here for state management if needed
        Provider<DatabaseHelper>(create: (_) => DatabaseHelper()),
        Provider<FirebaseService>(create: (_) => FirebaseService()),
        Provider<SyncManager>(create: (_) => SyncManager()),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),

        // Define routes for navigation
        routes: {
          '/splash': (context) => const SplashScreen(),
          // Additional routes will be added as we create screens
        },
      ),
    );
  }
}
