// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:gradproject2025/presentation/screens/notification_settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart'; // Import LoginScreen for logout

class AccountScreen extends StatefulWidget {
  final ValueNotifier<ThemeMode> themeNotifier;

  const AccountScreen({super.key, required this.themeNotifier});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  String username = 'Loading...';
  String email = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      // token = prefs.getString('token') ?? 'Unknown Token';
      username = prefs.getString('username') ?? 'Unknown User';
      email = prefs.getString('email') ?? 'Unknown Email';
    });
  }

  Future<void> _showLogoutConfirmationDialog() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        final isDarkMode = Theme.of(dialogContext).brightness == Brightness.dark;
        final primaryColor = Theme.of(dialogContext).colorScheme.primary;
        final textColor = isDarkMode ? Colors.white : Colors.black87;
        final subtitleColor = isDarkMode ? Colors.grey[400] : Colors.grey[700];
        final dialogBgColor = Theme.of(dialogContext).dialogBackgroundColor;

        return AlertDialog(
          backgroundColor: dialogBgColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
          title: Row(
            children: [
              Icon(Icons.logout, color: primaryColor),
              const SizedBox(width: 10),
              Text('Confirm Logout', style: TextStyle(color: textColor)),
            ],
          ),
          content: Text('Are you sure you want to log out?', style: TextStyle(color: subtitleColor)),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel', style: TextStyle(color: subtitleColor)),
              onPressed: () {
                Navigator.of(dialogContext).pop(false); // User canceled
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Log Out'),
              onPressed: () {
                Navigator.of(dialogContext).pop(true); // User confirmed
              },
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      // Proceed with logout
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear(); // Clears all data in SharedPreferences
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen(themeNotifier: widget.themeNotifier)),
        (route) => false,
      );
    }
  }

  // Modify the existing _logout or rename it if you prefer,
  // then call _showLogoutConfirmationDialog from the button's onPressed.
  // For this example, I'm making the button call _showLogoutConfirmationDialog directly.

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final cardBgColor = Theme.of(context).cardColor.withAlpha(200);
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final subtitleColor = isDarkMode ? Colors.grey[400] : Colors.grey[700];

    return Scaffold(
      appBar: AppBar(
        title: Text('Your Account', style: TextStyle(color: textColor)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Account Info Section
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: cardBgColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withAlpha(30), blurRadius: 8, offset: const Offset(0, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: primaryColor,
                  child: Icon(Icons.person, size: 50, color: Colors.white),
                ),
                const SizedBox(height: 16),
                Text(
                  username,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(email, style: TextStyle(fontSize: 16, color: subtitleColor), textAlign: TextAlign.center),
                const SizedBox(height: 24), // Spacer before logout button
                SizedBox(
                  width: 150, // Make button take available width within the card
                  child: ElevatedButton.icon(
                    onPressed: _showLogoutConfirmationDialog, // Call the confirmation dialog
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor.withOpacity(0.8), // Use primary theme color
                      foregroundColor: Colors.white, // Text color for the button
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 1,
                    ),
                    icon: const Icon(Icons.logout, size: 20),
                    label: const Text('Log Out', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),

          // Dark Mode Switch
          _buildSwitchTile(
            title: 'Dark Mode',
            icon: isDarkMode ? Icons.dark_mode : Icons.light_mode,
            value: widget.themeNotifier.value == ThemeMode.dark,
            onChanged: (isDarkModeEnabled) {
              setState(() {
                widget.themeNotifier.value = isDarkModeEnabled ? ThemeMode.dark : ThemeMode.light;
              });
            },
          ),
          const SizedBox(height: 10),

          // Notification Settings Navigation
          _buildNavigationTile(
            context,
            title: 'Notification Settings',
            icon: Icons.notifications_outlined,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationSettingsScreen()));
            },
          ),
          const SizedBox(height: 20),
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
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(30), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: SwitchListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        activeColor: Theme.of(context).colorScheme.primary, // Use theme color
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
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withAlpha(200),
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(30), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      ),
    );
  }
}
