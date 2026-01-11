import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/models/user_profile.dart';
import '../services/auth_service.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService;
  StreamSubscription<AuthState>? _authSubscription;

  bool _isLoading = false;
  String? _error;
  User? _user;
  UserProfile? _profile;

  AuthViewModel(this._authService) {
    _init();
  }

  bool get isLoading => _isLoading;
  String? get error => _error;
  User? get user => _user;
  UserProfile? get profile => _profile;
  bool get isAuthenticated => _user != null;

  void _init() {
    _user = _authService.currentUser;

    _authSubscription = _authService.authStateChanges.listen((state) {
      _user = state.session?.user;
      if (_user != null) {
        _loadProfile();
      } else {
        _profile = null;
      }
      notifyListeners();
    });

    if (_user != null) {
      _loadProfile();
    }
  }

  Future<void> _loadProfile() async {
    _profile = await _authService.getUserProfile();
    notifyListeners();
  }

  Future<bool> signIn({required String email, required String password}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.signIn(email: email, password: password);
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Une erreur est survenue';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUp({required String email, required String password}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.signUp(email: email, password: password);
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Une erreur est survenue';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() => _authService.signOut();

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
