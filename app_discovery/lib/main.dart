import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/routing/app_router.dart';
import 'services/firebase_service.dart';
import 'services/cloudinary_service.dart';
import 'services/admin_service.dart';
import 'providers/auth_provider.dart';
import 'providers/post_provider.dart';
import 'providers/category_provider.dart';
import 'providers/admin_provider.dart';
import 'providers/settings_provider.dart';
import 'core/constants/admin_constants.dart';
import 'features/home/screens/main_screen.dart';
import 'widgets/app_background.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Custom ErrorWidget builder so release mode renders an informative dark error screen instead of Flutter's blank grey box
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('=== FLUTTER ERROR ===: ${details.exceptionAsString()}');
  };

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: const Color(0xFF06090E),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.cyanAccent, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Something went wrong',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                details.exceptionAsString(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  };

  await FirebaseService.initialize();
  await CloudinaryService.loadConfig();
  await AdminConstants.loadPersistedAdmins();
  await AdminService.hydrateFromDisk();

  // Initialize settings provider before building widget tree
  final settingsProvider = SettingsProvider();
  await settingsProvider.init();

  runApp(MyApp(settingsProvider: settingsProvider));
}

class MyApp extends StatelessWidget {
  final SettingsProvider settingsProvider;

  const MyApp({super.key, required this.settingsProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settingsProvider),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PostProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'App Discovery',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.dark, // Obsidian geometric starry dark theme
            home: const MainScreen(),
            onGenerateRoute: AppRouter.generateRoute,
            debugShowCheckedModeBanner: false,
            builder: (context, child) {
              return AppBackground(
                child: child ?? const SizedBox(),
              );
            },
          );
        },
      ),
    );
  }
}
