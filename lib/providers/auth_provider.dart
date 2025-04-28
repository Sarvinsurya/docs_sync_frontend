import 'package:flutter/foundation.dart';

import '../models/user.dart';
import '../services/auth_service.dart';
class AuthProvider with ChangeNotifier {
  User? _user;
  String? _token;
  final AuthService _authService = AuthService();

  bool get isAuth => _token != null;
  User? get user => _user;
  String? get token => _token;

  // Try auto login from stored token
  Future<bool> tryAutoLogin() async {
    final storedToken = await _authService.getStoredToken();

    
    if (storedToken == null) {
      return false;
    }

    try {
      final userData = await _authService.getUserData(storedToken);
      
      if (userData == null) {
        return false;
      }

      _token = storedToken;// Debug log
      _user = userData;
      notifyListeners();
      return true;
    } catch (error) {
      return false;
    }
  }

  // Register a new user
  Future<void> register(String name, String email, String password) async {
    try {
      final result = await _authService.register(name, email, password);
      _token = result['token'];
      _user = result['user'];
      notifyListeners();
    } catch (error) {
      throw error;
    }
  }

  // Login user
  Future<void> login(String email, String password) async {
    try {
      final result = await _authService.login(email, password);
      _token = result['token'];
      _user = result['user'];
      notifyListeners();
    } catch (error) {
      throw error;
    }
  }

  // Logout user
  Future<void> logout() async {
    _token = null;
    _user = null;
    await _authService.logout();
    notifyListeners();
  }
}
