import 'package:flutter/material.dart';

class AccInfoScreen extends StatelessWidget {
  const AccInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: const Center(child: Text('Account Screen', style: TextStyle(color: Colors.white))),
    );
  }
}
