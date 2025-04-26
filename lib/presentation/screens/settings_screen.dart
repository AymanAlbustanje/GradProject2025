import 'package:flutter/material.dart';
import 'package:gradproject2025/main.dart';
import 'package:gradproject2025/presentation/screens/login_screen.dart';
import 'package:gradproject2025/presentation/screens/register_screen.dart';
import 'acc_info_screen.dart';
import 'notification_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final themeNotifier = (context.findAncestorWidgetOfExactType<MainScreen>() as MainScreen).themeNotifier;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          SwitchListTile(
            title: const Text('Dark Mode'),
            activeColor: const Color(0xFF0078D4),
            secondary: const Icon(Icons.light_mode),
            value: themeNotifier.value == ThemeMode.dark,
            onChanged: (isDarkMode) {
              setState(() {
                themeNotifier.value = isDarkMode ? ThemeMode.dark : ThemeMode.light;
              });
            },
          ),
          const SizedBox(height: 10),
          ListTile(
            title: const Text('Account'),
            leading: const Icon(Icons.person),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AccInfoScreen()));
            },
          ),
          const SizedBox(height: 10),
          ListTile(
            title: const Text('Notification Settings'),
            leading: const Icon(Icons.notifications),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationSettingsScreen()));
            },
          ),
          ListTile(
            title: const Text('Login Screen'),
            leading: const Icon(Icons.login),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
            },
          ),
          const SizedBox(height: 10),
          ListTile(
            title: const Text('Register Screen'),
            leading: const Icon(Icons.app_registration),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen()));
            },
          ),
        ],
      ),
    );
  }
}
