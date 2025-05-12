import 'dart:convert';
import 'package:http/http.dart' as http;

class RegisterService {
  final String baseUrl;

  RegisterService({required this.baseUrl});

  Future<void> register(String name, String email, String password) async {
    final url = Uri.parse('$baseUrl/api/auth/register');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode != 201) {
      final error = jsonDecode(response.body)['message'] ?? 'Registration failed';
      throw Exception(error);
    }
  }
}