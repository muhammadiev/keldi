import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart'; // ← THIS IMPORT IS REQUIRED
import 'package:shared_preferences/shared_preferences.dart';
import 'features/auth/login_screen.dart';
import 'features/home/home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Uzbek locale data for date formatting
  await initializeDateFormatting('uz', null);
  await initializeDateFormatting('uz_UZ', null);

  // Check login state (a stored token means logged in)
  final prefs = await SharedPreferences.getInstance();
  final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Keldim / Ketdim',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.purple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: isLoggedIn ? const HomeScreen() : const LoginScreen(),
    );
  }
}