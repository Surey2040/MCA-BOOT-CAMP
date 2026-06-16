import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/db_helper.dart';

class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _token;
  String _username = 'Guest';
  String _role = 'staff';
  String _errorMessage = '';
  
  bool _rememberMe = false;
  String _savedPin = '';

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get token => _token;
  String get username => _username;
  String get role => _role;
  String get errorMessage => _errorMessage;
  bool get rememberMe => _rememberMe;
  String get savedPin => _savedPin;


  Future<void> checkTokenExpiry() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    _username = prefs.getString('auth_username') ?? 'Guest';
    _role = prefs.getString('auth_role') ?? 'staff';
    _rememberMe = prefs.getBool('remember_me') ?? false;
    _savedPin = prefs.getString('saved_pin') ?? '';
    
    if (_token != null) {
      _isAuthenticated = true;
    }
    notifyListeners();
  }

  Future<bool> login(String pin, {bool rememberMe = false}) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      // Authenticate against SQLite local database
      final admin = await DbHelper.instance.authenticateAdmin(pin);
      
      if (admin != null) {
        _isAuthenticated = true;
        _username = admin['name'] ?? 'Admin';
        _role = 'admin';
        _token = 'local_session_token_${admin['id']}';

        // Save session credentials to shared preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', _token!);
        await prefs.setString('auth_username', _username);
        await prefs.setString('auth_role', _role);
        
        // Save "Remember Me" preferences
        await prefs.setBool('remember_me', rememberMe);
        if (rememberMe) {
          await prefs.setString('saved_pin', pin);
          _savedPin = pin;
        } else {
          await prefs.remove('saved_pin');
          _savedPin = '';
        }
        _rememberMe = rememberMe;

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Incorrect Admin PIN';
      }
    } catch (e) {
      _errorMessage = 'Database authentication error: $e';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    _isAuthenticated = false;
    _token = null;
    _username = 'Guest';
    _role = 'staff';
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('auth_username');
    await prefs.remove('auth_role');
    
    notifyListeners();
  }
}
