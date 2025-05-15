import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gradproject2025/api_constants.dart';
import '../../Logic/blocs/verification_bloc.dart';
import '../../data/DataSources/verification_service.dart';
import 'login_screen.dart';

class VerificationScreen extends StatelessWidget {
  final String email;
  final ValueNotifier<ThemeMode> themeNotifier;

  const VerificationScreen({super.key, required this.email, required this.themeNotifier});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => VerificationBloc(
        verificationService: VerificationService(baseUrl: ApiConstants.baseUrl),
      ),
      child: Scaffold(
        body: BlocConsumer<VerificationBloc, VerificationState>(
          listener: (context, state) {
            if (state is VerificationSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Email verified successfully!')),
              );
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => LoginScreen(themeNotifier: themeNotifier),
                ),
              );
            } else if (state is VerificationFailure) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error)));
            } else if (state is ResendCodeSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Verification code resent successfully!')),
              );
            } else if (state is ResendCodeFailure) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error)));
            }
          },
          builder: (context, state) {
            if (state is VerificationLoading || state is ResendCodeLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final codeController = TextEditingController();

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 60.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40),
                    Text(
                      'Verify Your Email!',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Enter the verification code sent to your email',
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[300] : Colors.grey[700],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 50),
                    TextField(
                      controller: codeController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Verification Code',
                        prefixIcon: const Icon(Icons.code),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                      ),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: () {
                        final code = codeController.text.trim();
                        if (code.isNotEmpty) {
                          context.read<VerificationBloc>().add(
                                VerifyEmail(email: email, code: code),
                              );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter the verification code.')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0078D4),
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                      ),
                      child: const Text('Verify', style: TextStyle(fontSize: 18, color: Colors.white)),
                    ),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () {
                        context.read<VerificationBloc>().add(ResendCode(email: email));
                      },
                      child: const Text('Resend Code', style: TextStyle(color: Color(0xFF0078D4))),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}