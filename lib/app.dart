import 'package:flutter/material.dart';

import 'core/app_state.dart';
import 'core/theme.dart';
import 'features/auth/login_screen.dart';
import 'features/home/home_screen.dart';

class KeldimApp extends StatelessWidget {
  final bool initiallyLoggedIn;
  const KeldimApp({super.key, required this.initiallyLoggedIn});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppState.instance,
      builder: (context, _) {
        return MaterialApp(
          title: 'Keldim / Ketdim',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: AppState.instance.themeMode,
          home: initiallyLoggedIn ? const HomeScreen() : const LoginScreen(),
        );
      },
    );
  }
}
