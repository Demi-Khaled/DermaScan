import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../core/constants.dart';
import '../models/lesion.dart';
import 'notification_service.dart';
import 'sync_service.dart';

class AuthService extends ChangeNotifier {
  String? _token;
  String? _refreshToken;
  String? _userName;
  String? _userEmail;
  String? _profilePicture;
  int? _age;
  String? _skinType;
  String? _medicalConditions;
  bool _isDarkMode = false;

  final _storage = const FlutterSecureStorage();
  bool _googleInitialized = false;

  bool get isAuthenticated => _token != null;
  String? get token => _token;
  String get userName => _userName ?? 'Unknown User';
  String get userEmail => _userEmail ?? '';
  String? get profilePicture => _profilePicture;
  int? get age => _age;
  String? get skinType => _skinType;
  String? get medicalConditions => _medicalConditions;
  bool get isDarkMode => _isDarkMode;

  Future<void> loadUser() async {
    _token = await _storage.read(key: 'token');
    _refreshToken = await _storage.read(key: 'refreshToken');
    _userName = await _storage.read(key: 'userName');
    _userEmail = await _storage.read(key: 'userEmail');
    _profilePicture = await _storage.read(key: 'profilePicture');
    final ageStr = await _storage.read(key: 'age');
    _age = ageStr != null ? int.tryParse(ageStr) : null;
    _skinType = await _storage.read(key: 'skinType');
    _medicalConditions = await _storage.read(key: 'medicalConditions');
    final darkStr = await _storage.read(key: 'isDarkMode');
    _isDarkMode = darkStr == 'true';
    notifyListeners();
    
    if (isAuthenticated) {
      await SyncService.fetchHistoryFromServer(token: _token!);
    }
  }

  Future<void> _saveUser(Map<String, dynamic> data) async {
    _token = data['token'];
    _refreshToken = data['refreshToken'];
    _userName = data['name'];
    _userEmail = data['email'];
    _profilePicture = data['profilePicture'];
    _age = data['age'];
    _skinType = data['skinType'];
    _medicalConditions = data['medicalConditions'];
    _isDarkMode = data['isDarkMode'] ?? false;
    
    if (_token != null) await _storage.write(key: 'token', value: _token);
    if (_refreshToken != null) await _storage.write(key: 'refreshToken', value: _refreshToken);
    if (_userName != null) await _storage.write(key: 'userName', value: _userName);
    if (_userEmail != null) await _storage.write(key: 'userEmail', value: _userEmail);
    if (_profilePicture != null) await _storage.write(key: 'profilePicture', value: _profilePicture!);
    if (_age != null) await _storage.write(key: 'age', value: _age!.toString());
    if (_skinType != null) await _storage.write(key: 'skinType', value: _skinType!);
    if (_medicalConditions != null) await _storage.write(key: 'medicalConditions', value: _medicalConditions!);
    await _storage.write(key: 'isDarkMode', value: _isDarkMode.toString());
    
    if (_token != null) {
      await SyncService.fetchHistoryFromServer(token: _token!);
    }
    
    notifyListeners();
  }

  Future<void> logout() async {
    // Attempt backend logout if we have a token
    if (_token != null) {
      try {
        await http.post(
          Uri.parse('${AppConstants.apiBaseUrl}/auth/logout'),
          headers: {'Authorization': 'Bearer $_token'},
        );
      } catch (e) {
        debugPrint('Backend logout error: $e');
      }
    }

    await _storage.deleteAll();
    await LesionStore().clear();
    NotificationService.cancelAll();
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
    
    _token = null;
    _refreshToken = null;
    _userName = null;
    _userEmail = null;
    _profilePicture = null;
    _age = null;
    _skinType = null;
    _medicalConditions = null;
    _isDarkMode = false;
    
    notifyListeners();
  }

  // Helper for authenticated requests with automatic token refresh
  Future<http.Response> _requestWithRefresh(
    String method,
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    headers ??= {};
    headers['Content-Type'] = 'application/json';
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }

    try {
      http.Response response;
      if (method == 'POST') {
        response = await http.post(url, headers: headers, body: body).timeout(const Duration(seconds: 15));
      } else if (method == 'PUT') {
        response = await http.put(url, headers: headers, body: body).timeout(const Duration(seconds: 15));
      } else if (method == 'DELETE') {
        response = await http.delete(url, headers: headers).timeout(const Duration(seconds: 15));
      } else {
        response = await http.get(url, headers: headers).timeout(const Duration(seconds: 15));
      }

      if (response.statusCode == 401 && _refreshToken != null) {
        // Attempt refresh
        final refreshSuccess = await refreshSession();
        if (refreshSuccess) {
          // Retry the request with new token
          headers['Authorization'] = 'Bearer $_token';
          if (method == 'POST') {
            return await http.post(url, headers: headers, body: body).timeout(const Duration(seconds: 15));
          } else if (method == 'PUT') {
            return await http.put(url, headers: headers, body: body).timeout(const Duration(seconds: 15));
          } else if (method == 'DELETE') {
            return await http.delete(url, headers: headers).timeout(const Duration(seconds: 15));
          } else {
            return await http.get(url, headers: headers).timeout(const Duration(seconds: 15));
          }
        } else {
          await logout();
          throw Exception('Session expired. Please log in again.');
        }
      }
      return response;
    } on TimeoutException {
      throw Exception('Connection timed out. Please check your internet.');
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> refreshSession() async {
    if (_refreshToken == null) return false;
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': _refreshToken}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = _safeDecode(response.body);
        _token = data['token'];
        _refreshToken = data['refreshToken'];
        await _storage.write(key: 'token', value: _token);
        await _storage.write(key: 'refreshToken', value: _refreshToken);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = _safeDecode(response.body);
        await _saveUser(data);
        return true;
      } else {
        final error = _safeDecode(response.body);
        throw Exception(error['message'] ?? 'Login failed');
      }
    } on TimeoutException {
      throw Exception('Login timed out. Check your connection.');
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      if (!_googleInitialized) {
        await GoogleSignIn.instance.initialize(
          clientId: '897097439750-0r6t31gcvr97f2ta2h86u4k0mbfvsjud.apps.googleusercontent.com',
          serverClientId: '897097439750-9tirkd17nu0lj940u6fir7sr3uj10lh9.apps.googleusercontent.com',
        );
        _googleInitialized = true;
      }

      final googleUser = await GoogleSignIn.instance.authenticate();


      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        throw Exception('Failed to get Google ID Token. Try again.');
      }

      final response = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idToken': idToken}),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = _safeDecode(response.body);
        await _saveUser(data);
        return true;
      } else {
        final error = _safeDecode(response.body);
        throw Exception(error['message'] ?? 'Google Login failed');
      }
    } on TimeoutException {
      throw Exception('Google login timed out.');
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      rethrow;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 201) {
        final data = _safeDecode(response.body);
        await _saveUser(data);
        return true;
      } else {
        final error = _safeDecode(response.body);
        throw Exception(error['message'] ?? 'Registration failed');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> updateProfile({
    String? name,
    String? email,
    String? password,
    int? age,
    String? skinType,
    String? medicalConditions,
  }) async {
    if (_token == null) return false;
    try {
      final Map<String, dynamic> body = {};
      if (name != null && name.isNotEmpty) body['name'] = name;
      if (email != null && email.isNotEmpty) body['email'] = email;
      if (password != null && password.isNotEmpty) body['password'] = password;
      if (age != null) body['age'] = age;
      if (skinType != null) body['skinType'] = skinType;
      if (medicalConditions != null) body['medicalConditions'] = medicalConditions;
      if (body.isEmpty) return true; // Nothing to update

      final response = await _requestWithRefresh(
        'PUT',
        Uri.parse('${AppConstants.apiBaseUrl}/auth/update'),
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = _safeDecode(response.body);
        await _saveUser(data);
        return true;
      } else {
        final error = _safeDecode(response.body);
        throw Exception(error['message'] ?? 'Update failed');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> uploadAvatar(String filePath) async {
    if (_token == null) return false;
    try {
      // Manual multi-part request because _requestWithRefresh expects simple methods
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConstants.apiBaseUrl}/auth/upload-avatar'),
      );

      request.headers['Authorization'] = 'Bearer $_token';
      request.files.add(await http.MultipartFile.fromPath('avatar', filePath));

      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = _safeDecode(response.body);
        _profilePicture = data['profilePicture'];
        await _storage.write(key: 'profilePicture', value: _profilePicture!);
        notifyListeners();
        return true;
      } else if (response.statusCode == 401) {
        // Simple token refresh attempt
        final refreshed = await refreshSession();
        if (refreshed) {
          return uploadAvatar(filePath); // Retry once
        }
        await logout(); // Session truly expired
        throw Exception('Session expired. Please login again.');
      } else {
        final error = _safeDecode(response.body);
        throw Exception(error['message'] ?? 'Avatar upload failed');
      }
    } catch (e) {
      debugPrint('Avatar Upload Error: $e');
      rethrow;
    }
  }

  Future<bool> changePassword(String oldPassword, String newPassword) async {
    if (_token == null) return false;
    try {
      final response = await _requestWithRefresh(
        'PUT',
        Uri.parse('${AppConstants.apiBaseUrl}/auth/change-password'),
        body: jsonEncode({
          'oldPassword': oldPassword,
          'newPassword': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final error = _safeDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to change password');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return true;
      } else {
        final error = _safeDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to send OTP');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> verifyOTP(String email, String otp) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/auth/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'otp': otp}),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return true;
      } else {
        final error = _safeDecode(response.body);
        throw Exception(error['message'] ?? 'Invalid OTP');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> resetPassword(String email, String otp, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'otp': otp,
          'newPassword': newPassword,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return true;
      } else {
        final error = _safeDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to reset password');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteAccount() async {
    if (_token == null) return;
    try {
      final response = await _requestWithRefresh(
        'DELETE',
        Uri.parse('${AppConstants.apiBaseUrl}/auth/delete'),
      );

      if (response.statusCode == 200) {
        await logout();
      } else {
        final error = _safeDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to delete account');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> toggleDarkMode(bool value) async {
    _isDarkMode = value;
    notifyListeners();
    await _storage.write(key: 'isDarkMode', value: _isDarkMode.toString());
    
    // Sync with backend if authenticated
    if (isAuthenticated) {
      try {
        final response = await _requestWithRefresh(
          'PUT',
          Uri.parse('${AppConstants.apiBaseUrl}/auth/update'),
          body: jsonEncode({'isDarkMode': value}),
        );
        if (response.statusCode != 200) {
          debugPrint('Failed to sync dark mode with backend');
        }
      } catch (e) {
        debugPrint('Error syncing dark mode: $e');
      }
    }
  }

  Map<String, dynamic> _safeDecode(String body) {
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('JSON Decode Error: $e\nBody: $body');
      throw Exception('Server returned an invalid response. Please try again.');
    }
  }
}
