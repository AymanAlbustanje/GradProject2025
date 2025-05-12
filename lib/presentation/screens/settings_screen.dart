import 'package:flutter/material.dart';
import 'acc_info_screen.dart';
import 'notification_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  final ValueNotifier<ThemeMode> themeNotifier;

  const SettingsScreen({super.key, required this.themeNotifier});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSwitchTile(
            title: 'Dark Mode',
            icon: Theme.of(context).brightness == Brightness.dark ? Icons.dark_mode : Icons.light_mode,
            value: widget.themeNotifier.value == ThemeMode.dark,
            onChanged: (isDarkMode) {
              setState(() {
                widget.themeNotifier.value = isDarkMode ? ThemeMode.dark : ThemeMode.light;
              });
            },
          ),
          const SizedBox(height: 10),

          _buildNavigationTile(
            context,
            title: 'Account',
            icon: Icons.person,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AccInfoScreen(themeNotifier: widget.themeNotifier),
                ),
              );
            },
          ),
          const SizedBox(height: 10),

          _buildNavigationTile(
            context,
            title: 'Notification Settings',
            icon: Icons.notifications,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationSettingsScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withAlpha(200),
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(30),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SwitchListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        activeColor: const Color(0xFF0078D4),
        secondary: Icon(icon, color: Theme.of(context).colorScheme.primary),
        value: value,
        onChanged: onChanged,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      ),
    );
  }

  Widget _buildNavigationTile(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 18.0),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor.withAlpha(200),
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(30),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary, size: 26),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }
}