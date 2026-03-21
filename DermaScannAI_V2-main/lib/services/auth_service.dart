import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService extends ChangeNotifier {
  String? _token;
  String? _userName;
  String? _userEmail;
  String? _userId;

  bool get isAuthenticated => _token != null;
  String? get token => _token;
  String? get userName => _userName;
  String? get userEmail => _userEmail;

  Future<String> get baseUrl async {
    if (!kIsWeb && Platform.isAndroid) return 'http://10.0.2.2:3000';
    return 'http://localhost:3000';
  }

  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('userData')) return false;

    final extractedData = json.decode(prefs.getString('userData')!) as Map<String, dynamic>;
    _token = extractedData['token'];
    _userId = extractedData['userId'];
    _userName = extractedData['userName'];
    _userEmail = extractedData['userEmail'];
    notifyListeners();
    return true;
  }

  Future<void> register(String name, String email, String password) async {
    final url = await baseUrl;
    final response = await http.post(
      Uri.parse('$url/api/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'name': name,
        'email': email,
        'password': password,
      }),
    );

    final responseData = json.decode(response.body);
    if (response.statusCode != 201) {
      throw Exception(responseData['message'] ?? 'Failed to register');
    }

    _authenticateUser(responseData);
  }

  Future<void> login(String email, String password) async {
    final url = await baseUrl;
    final response = await http.post(
      Uri.parse('$url/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'password': password,
      }),
    );

    final responseData = json.decode(response.body);
    if (response.statusCode != 200) {
      throw Exception(responseData['message'] ?? 'Failed to authenticate');
    }

    _authenticateUser(responseData);
  }

  Future<void> _authenticateUser(Map<String, dynamic> responseData) async {
    _token = responseData['token'];
    _userId = responseData['_id'];
    _userName = responseData['name'];
    _userEmail = responseData['email'];

    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final userData = json.encode({
      'token': _token,
      'userId': _userId,
      'userName': _userName,
      'userEmail': _userEmail,
    });
    await prefs.setString('userData', userData);
  }

  Future<void> logout() async {
    _token = null;
    _userId = null;
    _userName = null;
    _userEmail = null;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userData');
  }
}
