import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../core/constants/admin_constants.dart';

/// Provider for managing authentication state
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _currentUser;
  AppUser? _currentAppUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isAdmin = false;

  // Getters
  User? get currentUser => _currentUser;
  AppUser? get currentAppUser => _currentAppUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAdmin => _isAdmin;
  bool get isAuthenticated => _currentUser != null || (_isAdmin && _currentAppUser != null);
  String? get activeEmail => _currentUser?.email ?? _currentAppUser?.email;

  AuthProvider() {
    _initializeAuthState();
  }

  /// Initialize authentication state on app start
  void _initializeAuthState() {
    _authService.authStateChanges.listen((user) {
      _currentUser = user;
      if (user != null) {
        if (AdminConstants.isAdminEmail(user.email)) {
          _isAdmin = true;
        }
        _loadUserData(user.uid);
      } else {
        _currentAppUser = null;
        _isAdmin = false;
      }
      notifyListeners();
    });
  }

  /// Load user data from Firestore
  Future<void> _loadUserData(String userId) async {
    try {
      final userData = await _authService.getUserData(userId);
      _currentAppUser = userData;
      if (AdminConstants.isAdminEmail(_currentUser?.email)) {
        _isAdmin = true;
      } else {
        _isAdmin = userData?.isAdmin ?? false;
      }
      notifyListeners();
    } catch (e) {
      print('Error loading user data: $e');
      if (AdminConstants.isAdminEmail(_currentUser?.email)) {
        _isAdmin = true;
        notifyListeners();
      }
    }
  }

  /// Sign in with email and password
  Future<bool> signInWithEmail(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final isSuper = AdminConstants.isSuperAdmin(email);
    final isAdmin = AdminConstants.isAdminEmail(email);

    // Verify Super Admin password explicitly
    if (isSuper && !AdminConstants.verifySuperAdminPassword(password)) {
      _errorMessage = 'Incorrect password for $email';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    try {
      final user = await _authService.signInWithEmail(email, password);
      _currentUser = user;
      if (user != null) {
        if (isAdmin) {
          _isAdmin = true;
        }
        await _loadUserData(user.uid);
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      // If designated admin, establish active session even if Firebase provider is disabled in console
      if (isAdmin) {
        _isAdmin = true;
        final uid = 'admin_${email.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';
        _currentAppUser = AppUser(
          id: uid,
          email: email,
          isAdmin: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Store signed admin in Firestore collections
        _authService.storeSignedUser(uid, email);

        _isLoading = false;
        notifyListeners();
        return true;
      }

      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Create a new user account (with admin role if email is pre-authorized)
  Future<bool> createUser(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authService.createUser(email, password);
      _currentUser = user;
      if (user != null) {
        if (AdminConstants.isAdminEmail(user.email)) {
          _isAdmin = true;
        }
        await _loadUserData(user.uid);
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      if (AdminConstants.isAdminEmail(email)) {
        _isAdmin = true;
        final uid = 'admin_${email.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';
        _currentAppUser = AppUser(
          id: uid,
          email: email,
          isAdmin: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        _authService.storeSignedUser(uid, email);
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Change password for current administrator
  Future<bool> changePassword(String newPassword) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final email = activeEmail;
      if (AdminConstants.isSuperAdmin(email)) {
        await AdminConstants.updateSuperAdminPassword(newPassword);
      }
      await _authService.updatePassword(newPassword);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Check if current user is admin
  Future<void> checkAdminStatus() async {
    if (_currentUser == null && !_isAdmin) return;
    
    try {
      if (AdminConstants.isAdminEmail(activeEmail) || _isAdmin) {
        _isAdmin = true;
      } else {
        final isAdmin = await _authService.isCurrentUserAdmin();
        _isAdmin = isAdmin;
      }
      notifyListeners();
    } catch (e) {
      print('Error checking admin status: $e');
      if (AdminConstants.isAdminEmail(activeEmail)) {
        _isAdmin = true;
        notifyListeners();
      }
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.signOut();
      _currentUser = null;
      _currentAppUser = null;
      _isAdmin = false;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _currentUser = null;
      _currentAppUser = null;
      _isAdmin = false;
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
