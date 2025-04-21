import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/discover_screen.dart';
import 'presentation/screens/statistics_screen.dart';
import 'presentation/screens/settings_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Stock',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        primaryColor: const Color(0xFF1E1E1E), // Set primary color for dark theme
        scaffoldBackgroundColor: const Color(0xFF121212), // Background color for the app
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E), // AppBar background color
          foregroundColor: Colors.white, // AppBar text and icon color
          elevation: 0, // Remove AppBar shadow
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF1E1E1E), // BottomNavigationBar background color
          selectedItemColor: Colors.white, // Selected item color
          unselectedItemColor: Colors.grey, // Unselected item color
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white), // Default text color
          bodyMedium: TextStyle(color: Colors.white70), // Secondary text color
        ),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const DiscoverScreen(),
    const StatisticsScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SmartStock'), centerTitle: true),
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E), // Background color for the bar
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ), // Rounded corners
          boxShadow: [
            BoxShadow(
              color: Colors.black, // Subtle shadow
              spreadRadius: 2,
              blurRadius: 10,
              offset: const Offset(0, -2), // Shadow above the bar
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed, // Fixed mode for consistent layout
            backgroundColor: const Color(0xFF1E1E1E), // Match the container color
            currentIndex: _currentIndex,
            selectedItemColor: const Color(0xFF0078D4), // Highlighted item color
            unselectedItemColor: Colors.grey, // Unselected item color
            showSelectedLabels: true, // Show labels for selected items
            showUnselectedLabels: false, // Hide labels for unselected items
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Discover'),
              BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Statistics'),
              BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Settings'),
            ],
          ),
        ),
      ),
    );
  }
}
