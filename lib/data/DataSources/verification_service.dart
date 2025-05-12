import 'dart:convert';
import 'package:http/http.dart' as http;

class VerificationService {
  final String baseUrl;

  VerificationService({required this.baseUrl});

  Future<void> verifyEmail(String email, String code) async {
    final url = Uri.parse('$baseUrl/api/auth/verify-email');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'code': code}),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body)['message'] ?? 'Verification failed';
      throw Exception(error);
    }
  }

  Future<void> resendCode(String email) async {
    final url = Uri.parse('$baseUrl/api/auth/resend-verification');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body)['message'] ?? 'Failed to resend code';
      throw Exception(error);
    }
  }
}