import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gradproject2025/api_constants.dart';
import '../../Logic/blocs/login_bloc.dart';
import '../../data/DataSources/login_service.dart';
import 'main_screen.dart';
import 'register_screen.dart';

// Convert to StatefulWidget for managing field error states
class LoginScreen extends StatefulWidget {
  final ValueNotifier<ThemeMode> themeNotifier;

  const LoginScreen({super.key, required this.themeNotifier});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  
  // Error states for form fields
  String? emailError;
  String? passwordError;
  
  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LoginBloc(loginService: LoginService(baseUrl: ApiConstants.baseUrl)),
      child: Scaffold(
        body: BlocConsumer<LoginBloc, LoginState>(
          listener: (context, state) {
            if (state is LoginSuccess) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => MainScreen(themeNotifier: widget.themeNotifier)),
              );
            } else if (state is LoginFailure) {
              String errorMessage = state.error.toLowerCase(); // Convert to lowercase for easier comparison
              
              // Print error for debugging
              debugPrint("Login error: ${state.error}");
              
              // Handle different types of login errors
              if (errorMessage.contains('invalid credentials') || 
                  errorMessage.contains('incorrect password') || 
                  errorMessage.contains('wrong password')) {
                // Show password-specific error
                setState(() {
                  passwordError = 'Incorrect password. Please try again.';
                });
                formKey.currentState?.validate();
              } 
              else if (errorMessage.contains('not verified')) {
                // Show email-specific error for unverified accounts
                setState(() {
                  emailError = 'Email not verified. Please check your inbox.';
                });
                formKey.currentState?.validate();
              }
              else if (errorMessage.contains('not found') || 
                       errorMessage.contains('no account') || 
                       errorMessage.contains('not exist')) {
                // Show email-specific error for non-existent accounts
                setState(() {
                  emailError = 'No account found with this email.';
                });
                formKey.currentState?.validate();
              }
              else {
                // For other errors, show a snackbar
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.error),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  )
                );
              }
            }
          },
          builder: (context, state) {
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 60.0),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Added image
                      const SizedBox(height: 20),
                      Image.asset(
                        'assets/images/1.png',
                        height: 160,
                      ),
                      const SizedBox(height: 30),
                      Text(
                        'Welcome Back!',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Log in to your account',
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[300] : Colors.grey[700],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 50),
                      // Email field with error handling
                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: const Icon(Icons.email),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                          // Add error border when there's a server-side error
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: BorderSide(color: Theme.of(context).colorScheme.error, width: 2),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: BorderSide(color: Theme.of(context).colorScheme.error, width: 2),
                          ),
                        ),
                        validator: (value) {
                          // First check if there's a server-side error
                          if (emailError != null) {
                            return emailError;
                          }
                          
                          // Then perform client-side validation
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          final bool emailValid = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value);
                          if (!emailValid) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                        // Clear server-side error when user starts typing
                        onChanged: (value) {
                          if (emailError != null) {
                            setState(() {
                              emailError = null;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                      // Password field with error handling
                      TextFormField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                          // Add error border when there's a server-side error
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: BorderSide(color: Theme.of(context).colorScheme.error, width: 2),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: BorderSide(color: Theme.of(context).colorScheme.error, width: 2),
                          ),
                        ),
                        validator: (value) {
                          // First check if there's a server-side error
                          if (passwordError != null) {
                            return passwordError;
                          }
                          
                          // Then perform client-side validation
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                        // Clear server-side error when user starts typing
                        onChanged: (value) {
                          if (passwordError != null) {
                            setState(() {
                              passwordError = null;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: state is LoginLoading 
                          ? null // Disable button during loading
                          : () {
                            // Clear any previous server-side errors
                            setState(() {
                              emailError = null;
                              passwordError = null;
                            });
                            
                            // Validate all form fields before submitting
                            if (formKey.currentState!.validate()) {
                              final email = emailController.text.trim();
                              final password = passwordController.text.trim();
                              context.read<LoginBloc>().add(LoginSubmitted(email: email, password: password));
                            }
                          },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                          foregroundColor: Colors.white,
                        ),
                        child: state is LoginLoading 
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Log In', style: TextStyle(fontSize: 18)),
                      ),
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => RegisterScreen(themeNotifier: widget.themeNotifier)),
                          );
                        },
                        child: Text(
                          "Don't have an account? Register", 
                          style: TextStyle(color: Theme.of(context).colorScheme.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}