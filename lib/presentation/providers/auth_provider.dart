import 'package:flutter/material.dart';
import 'package:loker_kabur_aja_dulu/data/models/user_model.dart';
import 'package:loker_kabur_aja_dulu/services/auth_service.dart';
import 'dart:io'; // Untuk File

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  
  User? _currentUser;
  String? _token;
  String? _userRole;
  String? _userId;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isInitializing = true;

  User? get currentUser => _currentUser;
  String? get token => _token;
  String? get userRole => _userRole;
  String? get userId => _userId;
  bool get isAuthenticated => _token != null && _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isInitializing => _isInitializing;

  AuthProvider() {
    _initialize(); // Panggil saat inisialisasi atau dari main.dart
  }

  Future<void> _initialize() async {
    _setLoading(true);
    await tryAutoLogin();
    _isInitializing = false;
    _setLoading(false);
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();
    try {
      final result = await _authService.login(email, password);
      if (result['success'] == true) {
        _currentUser = result['user'] as User;
        _token = result['token'] as String;
        _userRole = _currentUser!.role;
        _userId = _currentUser!.id;
        notifyListeners();
        _setLoading(false);
        return true;
      } else {
        _errorMessage = result['message'] as String?;
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<Map<String, dynamic>> register({
    required String nama,
    required String email,
    required String password,
    String? linkLinkedIn,
    String? role,
    File? fotoProfile,
  }) async {
    _setLoading(true);
    _clearError();
    try {
      final result = await _authService.register(
        nama: nama,
        email: email,
        password: password,
        linkLinkedIn: linkLinkedIn,
        role: role,
        fotoProfile: fotoProfile,
      );
      _setLoading(false);
      if (result['success'] == false) {
        _errorMessage = result['message'] as String?;
      }
      return result; // Mengembalikan Map agar bisa dihandle di UI
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return {'success': false, 'message': e.toString()};
    }
  }


  Future<void> logout() async {
    _setLoading(true);
    await _authService.logout();
    _currentUser = null;
    _token = null;
    _userRole = null;
    _userId = null;
    _setLoading(false);
    notifyListeners();
  }

  Future<bool> tryAutoLogin() async {
    // _setLoading(true);
    final token = await _authService.getToken();
    if (token == null) {
      // _setLoading(false);
      return false;
    }

    // Token ada, coba fetch user data
    final user = await _authService.getMe(); // Menggunakan token yang tersimpan di AuthService
    if (user != null) {
      _currentUser = user;
      _token = token;
      _userRole = user.role;
      _userId = user.id;
      // _setLoading(false);
      // notifyListeners();
      return true;
    } else {
      // Token mungkin invalid, hapus
      await logout();
      // _setLoading(false); // Ini akan set _isLoading jadi false
      return false;
    }
  }
}