import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/app_state.dart';
import 'services/storage.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();
  await AppState.instance.load();
  final loggedIn = (await Storage.token) != null;
  runApp(KeldimApp(initiallyLoggedIn: loggedIn));
}
