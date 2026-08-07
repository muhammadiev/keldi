import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/app_state.dart';
import 'services/storage.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Show any widget-build error as visible text instead of a blank box.
  // This makes problems diagnosable even in a release build.
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: const Color(0xFFFDECEC),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Text(
              'Xatolik:\n\n${details.exceptionAsString()}',
              style: const TextStyle(color: Color(0xFFB00020), fontSize: 13),
            ),
          ),
        ),
      ),
    );
  };

  await initializeDateFormatting();
  await AppState.instance.load();
  final loggedIn = (await Storage.token) != null;
  runApp(KeldimApp(initiallyLoggedIn: loggedIn));
}
