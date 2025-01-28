import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dark_mode_notifier.dart';
import 'eye_timer_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final darkModeNotifier = DarkModeNotifier();
  await darkModeNotifier.initialize();

  runApp(
    ChangeNotifierProvider(
      create: (_) => darkModeNotifier,
      child: EyeTimerApp(),
    ),
  );
}
