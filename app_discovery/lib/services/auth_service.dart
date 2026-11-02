import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../core/constants/admin_constants.dart';

/// Service for handling Firebase Authentication
class AuthService {
  FirebaseAuth? get _auth {
    try {
      if (Firebase.apps.isNotEmpty) {
        return FirebaseAuth.instance;
      }
    } catch (_) {}
    return null;
  }

  FirebaseFirestore? get _firestore {
    try {
      if (Firebase.apps.isNotEmpty) {
        return FirebaseFirestore.instance;
      }
    } catch (_) {}
    return null;
  }

  /// Get current authenticated user
  User? getCurrentUser() {
    return _auth?.currentUser;
  }

  /// Stream of auth state changes
  Stream<User?> get authStateChanges {
    final auth = _auth;
    return auth != null ? auth.authStateChanges() : Stream.value(null);
  }

  /// Sign in with email and password
  Future<User?> signInWithEmail(String email, String password) async {
    final auth = _auth;
    if (auth == null) {
      throw Exception('Authentication service is currently unavailable.');
    }

    try {
      final result = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('✓ User signed in: ${result.user?.email}');

      // Automatically store/update signed user in Firestore collection
      if (result.user != null) {
        await storeSignedUser(result.user!.uid, result.user!.email ?? email);
      }

      return result.user;
    } on FirebaseAuthException catch (e) {
      print('✗ Auth error: ${e.code} - ${e.message}');

      // If user does not exist in Firebase Auth yet, and it is an authorized admin,
      // auto-provision their account in Firebase Auth so cloud auth is established!
      if ((e.code == 'user-not-found' || e.code == 'invalid-credential') &&
          AdminConstants.isAdminEmail(email)) {
        try {
          final createResult = await auth.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );
          if (createResult.user != null) {
            await storeSignedUser(createResult.user!.uid, email);
            return createResult.user;
          }
        } catch (createErr) {
          print('Notice auto-creating admin in Firebase Auth: $createErr');
        }
      }
      rethrow;
    }
  }

  /// Create user with email and password
  Future<User?> createUser(String email, String password) async {
    final auth = _auth;
    if (auth == null) {
      throw Exception('Authentication service is currently unavailable.');
    }

    try {
      final result = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = result.user;
      if (user != null) {
        await storeSignedUser(user.uid, email);
      }
      return user;
    } on FirebaseAuthException catch (e) {
      print('✗ Create user error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// Ensure signed user is saved in Firestore `users` and `admins` collections
  Future<void> storeSignedUser(String userId, String email) async {
    try {
      final firestore = _firestore;
      if (firestore == null) return;

      final bool isAdmin = AdminConstants.isAdminEmail(email);
      final bool isSuperAdmin = AdminConstants.isSuperAdmin(email);

      // Store in users collection
      await firestore.collection('users').doc(userId).set({
        'id': userId,
        'email': email,
        'isAdmin': isAdmin,
        'isSuperAdmin': isSuperAdmin,
        'lastLoginAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'status': 'active',
      }, SetOptions(merge: true));

      // If administrator, store in admins collection as well
      if (isAdmin) {
        await firestore.collection('admins').doc(userId).set({
          'email': email,
          'isAdmin': true,
          'isSuperAdmin': isSuperAdmin,
          'lastLoginAt': FieldValue.serverTimestamp(),
          'grantedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      print('✓ Signed user record stored in Firebase collections: $email (isAdmin: $isAdmin)');
    } catch (e) {
      print('⚠️ Notice storing signed user in Firestore: $e');
    }
  }

  /// Check if current user is admin (reads from designated list or Firestore)
  Future<bool> isCurrentUserAdmin() async {
    try {
      final user = getCurrentUser();
      if (user == null) return false;

      // Always grant access to designated admin emails
      if (AdminConstants.isAdminEmail(user.email)) {
        return true;
      }

      final firestore = _firestore;
      if (firestore == null) return false;

      final doc = await firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return false;

      final isAdmin = doc.data()?['isAdmin'] as bool? ?? false;
      return isAdmin;
    } catch (e) {
      print('Notice checking admin status: $e');
      final user = getCurrentUser();
      return AdminConstants.isAdminEmail(user?.email);
    }
  }

  /// Get user document from Firestore
  Future<AppUser?> getUserData(String userId) async {
    try {
      final firestore = _firestore;
      if (firestore == null) return null;

      final doc = await firestore.collection('users').doc(userId).get();
      if (!doc.exists) return null;
      return AppUser.fromFirestore(doc);
    } catch (e) {
      print('Notice fetching user data: $e');
      return null;
    }
  }

  /// Update password for the current authenticated user
  Future<void> updatePassword(String newPassword) async {
    try {
      final auth = _auth;
      final user = auth?.currentUser;
      if (user != null) {
        await user.updatePassword(newPassword);
        print('✓ Firebase Auth user password updated');
      }
    } catch (e) {
      print('Notice updating user password in Firebase Auth: $e');
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    try {
      final auth = _auth;
      if (auth != null) {
        await auth.signOut();
        print('✓ User signed out');
      }
    } catch (e) {
      print('Notice signing out: $e');
    }
  }
}
