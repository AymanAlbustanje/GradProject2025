// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:gradproject2025/presentation/screens/login_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class VerificationScreen extends StatefulWidget {
  final String email;
  final ValueNotifier<ThemeMode> themeNotifier;

  const VerificationScreen({super.key, required this.email, required this.themeNotifier});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _isLoadingVerify = false;
  bool _isLoadingResend = false;

  Future<void> _verifyEmail() async {
    if (_codeController.text.length != 6) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a 6-digit verification code.')));
      return;
    }

    setState(() {
      _isLoadingVerify = true;
    });

    final url = Uri.parse('http://192.168.1.100:3000/api/auth/verify-email'); // Replace localhost with 192.168.1.100
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': widget.email, 'code': _codeController.text}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Email verified successfully! You can now log in.')));
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen(themeNotifier: widget.themeNotifier)),
          (Route<dynamic> route) => false,
        );
      } else {
        final responseBody = jsonDecode(response.body);
        final error = responseBody['message'] ?? 'Invalid or expired verification code.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('An error occurred: ${e.toString()}')));
    } finally {
      setState(() {
        _isLoadingVerify = false;
      });
    }
  }

  Future<void> _resendVerificationCode() async {
    setState(() {
      _isLoadingResend = true;
    });

    final url = Uri.parse('http://192.168.1.100:3000/api/auth/resend-verification'); // Replace localhost
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': widget.email}),
      );

      final responseBody = jsonDecode(response.body);
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseBody['message'] ?? 'Verification code sent. Please check your email.')),
        );
      } else {
        final error = responseBody['message'] ?? 'Failed to resend code.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('An error occurred: ${e.toString()}')));
    } finally {
      setState(() {
        _isLoadingResend = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Email'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
        titleTextStyle: TextStyle(
          color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Enter Verification Code',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15),
              Text(
                'A 6-digit verification code has been sent to your email address: ${widget.email}',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[300] : Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, letterSpacing: 10),
                decoration: InputDecoration(
                  labelText: 'Verification Code',
                  counterText: "",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                ),
              ),
              const SizedBox(height: 30),
              _isLoadingVerify
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                    onPressed: _verifyEmail,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0078D4),
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                    ),
                    child: const Text('Verify', style: TextStyle(fontSize: 18, color: Colors.white)),
                  ),
              const SizedBox(height: 20),
              _isLoadingResend
                  ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                  : TextButton(
                    onPressed: _resendVerificationCode,
                    child: const Text('Didn\'t receive code? Resend', style: TextStyle(color: Color(0xFF0078D4))),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
