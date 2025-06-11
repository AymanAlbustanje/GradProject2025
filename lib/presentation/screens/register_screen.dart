// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gradproject2025/api_constants.dart';
import '../../Logic/blocs/register_bloc.dart';
import '../../data/DataSources/register_service.dart';
import 'verification_screen.dart';

class RegisterScreen extends StatefulWidget {
  final ValueNotifier<ThemeMode> themeNotifier;

  const RegisterScreen({super.key, required this.themeNotifier});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  String? emailError;
  bool isLoading = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RegisterBloc(registerService: RegisterService(baseUrl: ApiConstants.baseUrl)),
      child: Builder(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(
              elevation: 0,
              backgroundColor: Colors.transparent,
              foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
            ),
            body: BlocListener<RegisterBloc, RegisterState>(
              listener: (context, state) {
                if (state is RegisterLoading) {
                  setState(() {
                    isLoading = true;
                  });
                } else {
                  setState(() {
                    isLoading = false;
                  });

                  if (state is RegisterSuccess) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => VerificationScreen(email: state.email, themeNotifier: widget.themeNotifier),
                        ),
                      );

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Registration successful! Please verify your email.')),
                      );
                    });
                  } else if (state is RegisterFailure) {
                    String errorMessage = state.error.toLowerCase();
                    print("Registration error: ${state.error}");

                    if (errorMessage.contains("email already in use")) {
                      setState(() {
                        emailError = 'This email is already in use';
                      });
                      formKey.currentState?.validate();
                    } else if (errorMessage.contains('already') &&
                        (errorMessage.contains('email') ||
                            errorMessage.contains('registered') ||
                            errorMessage.contains('exists'))) {
                      setState(() {
                        emailError = 'This email is already registered';
                      });
                      formKey.currentState?.validate();
                    } else if (errorMessage.contains('email') && errorMessage.contains('taken')) {
                      setState(() {
                        emailError = 'This email is already taken';
                      });
                      formKey.currentState?.validate();
                    } else if (errorMessage.contains('duplicate')) {
                      setState(() {
                        emailError = 'This email is already in use';
                      });
                      formKey.currentState?.validate();
                    } else {
                      if (errorMessage.contains('validation')) {
                        errorMessage = 'Please ensure all fields are valid and try again.';
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(errorMessage), backgroundColor: Theme.of(context).colorScheme.error),
                      );
                    }
                  }
                }
              },
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Image.asset('assets/images/1.png', height: 130),
                        const SizedBox(height: 30),
                        Text(
                          'Create an Account!',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Sign up to get started',
                          style: TextStyle(
                            fontSize: 16,
                            color:
                                Theme.of(context).brightness == Brightness.dark ? Colors.grey[300] : Colors.grey[700],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 40),
                        TextFormField(
                          controller: nameController,
                          decoration: InputDecoration(
                            labelText: 'Name',
                            prefixIcon: const Icon(Icons.person),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your name';
                            }
                            if (value.length < 2) {
                              return 'Name must be at least 2 characters';
                            }
                            return null;
                          },
                          enabled: !isLoading,
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            prefixIcon: const Icon(Icons.email),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
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
                            if (emailError != null) {
                              return emailError;
                            }

                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            final bool emailValid = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value);
                            if (!emailValid) {
                              return 'Please enter a valid email address';
                            }
                            return null;
                          },
                          onChanged: (value) {
                            if (emailError != null) {
                              setState(() {
                                emailError = null;
                              });
                            }
                          },
                          enabled: !isLoading,
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                            helperText: 'Password must be at least 8 characters',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a password';
                            }
                            if (value.length < 8) {
                              return 'Must be at least 8 characters including numbers and capital letters';
                            }
                            return null;
                          },
                          enabled: !isLoading,
                        ),
                        const SizedBox(height: 30),
                        ElevatedButton(
                          onPressed:
                              isLoading
                                  ? null
                                  : () {
                                    setState(() {
                                      emailError = null;
                                    });

                                    if (formKey.currentState!.validate()) {
                                      final name = nameController.text.trim();
                                      final email = emailController.text.trim();
                                      final password = passwordController.text.trim();
                                      context.read<RegisterBloc>().add(
                                        RegisterSubmitted(name: name, email: email, password: password),
                                      );
                                    }
                                  },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                            foregroundColor: Colors.white,
                          ),
                          child:
                              isLoading
                                  ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                  : const Text('Sign Up', style: TextStyle(fontSize: 18)),
                        ),
                        const SizedBox(height: 20),
                        TextButton(
                          onPressed:
                              isLoading
                                  ? null
                                  : () {
                                    Navigator.pop(context);
                                  },
                          child: Text(
                            'Already have an account? Log In',
                            style: TextStyle(color: Theme.of(context).colorScheme.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
