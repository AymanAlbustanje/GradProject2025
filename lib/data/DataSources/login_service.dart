import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LoginService {
  final String baseUrl;

  LoginService({required this.baseUrl});

  Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/api/auth/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', data['token'] ?? '');
      await prefs.setString('username', data['user']['name'] ?? '');
      await prefs.setString('email', data['user']['email'] ?? '');

      if (kDebugMode) {
        print('Saved token: ${prefs.getString('token')}');
      }

      return data['user'];
    } else {
      final error = jsonDecode(response.body)['message'] ?? 'Login failed';
      throw Exception(error);
    }
  }
}