import 'package:flutter/material.dart';
import 'package:gradproject2025/data/DataSources/notification_service.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications'), centerTitle: true),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Notifications Settings Screen', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                final notificationService = NotificationService();
                notificationService.triggerTestNotification();
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Test Immediate Generic Notification'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final notificationService = NotificationService();
                final DateTime expirationDate = DateTime.now().add(const Duration(days: 7));
                notificationService.scheduleSimpleExpirationNotification(
                  id: 12345,
                  itemName: "Milk (Settings Test)",
                  expirationDate: expirationDate,
                  forceShortDelayForTestButton: true,
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                backgroundColor: Colors.orange,
              ),
              child: const Text('Test 15-Sec Expiration Notification'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final notificationService = NotificationService();
                notificationService.cancelAllNotifications();
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                backgroundColor: Colors.red,
              ),
              child: const Text('Cancel All Notifications'),
            ),
          ],
        ),
      ),
    );
  }
}
