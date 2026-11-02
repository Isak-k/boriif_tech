import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

/// Service for initializing Firebase
class FirebaseService {
  static bool isInitialized = false;
  static String? initializationError;

  static Future<void> initialize() async {
    try {
      if (Firebase.apps.isEmpty) {
        try {
          await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform,
          );
        } catch (optionsErr) {
          try {
            await Firebase.initializeApp();
          } catch (_) {
            print('Notice during Firebase.initializeApp fallback: $optionsErr');
          }
        }
      }
      isInitialized = Firebase.apps.isNotEmpty;
      if (isInitialized) {
        try {
          FirebaseFirestore.instance.settings = const Settings(
            persistenceEnabled: true,
            cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
          );
        } catch (e) {
          print('Notice configuring Firestore persistence: $e');
        }
      }
      print('✓ Firebase initialized successfully: isInitialized=$isInitialized');
    } catch (e) {
      initializationError = e.toString();
      print('✗ Firebase initialization notice: $e');
    }
  }
}
