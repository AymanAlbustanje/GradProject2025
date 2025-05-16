import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gradproject2025/presentation/screens/main_screen.dart';
import 'package:gradproject2025/presentation/screens/login_screen.dart';
import 'package:gradproject2025/Logic/blocs/in_house_bloc.dart';
import 'package:gradproject2025/Logic/blocs/household_bloc.dart';
import 'package:gradproject2025/Logic/blocs/current_household_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final isLoggedIn = await _checkIfLoggedIn();
  runApp(MyApp(isLoggedIn: isLoggedIn));
}

Future<bool> _checkIfLoggedIn() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');
  if (kDebugMode) {
    print('Token found: $token');
  }
  return token != null && token.isNotEmpty; // Return true if a valid token exists
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, themeMode, child) {
        return MultiBlocProvider(
          providers: [
            BlocProvider(create: (context) => InHouseBloc()),
            BlocProvider(create: (context) => HouseholdBloc()),
            BlocProvider(create: (context) => CurrentHouseholdBloc()..add(LoadCurrentHousehold())),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'ToBuy App',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF0078D4),
                brightness: Brightness.light,
              ),
              useMaterial3: true,
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF0078D4),
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
            ),
            themeMode: themeMode,
            home: isLoggedIn 
              ? MainScreen(themeNotifier: themeNotifier)
              : LoginScreen(themeNotifier: themeNotifier),
          ),
        );
      },
    );
  }
}