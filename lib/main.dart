import 'package:EyeTimer/providers/photo_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/dark_mode_notifier.dart';
import 'eye_timer_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final darkModeNotifier = DarkModeNotifier();
  await darkModeNotifier.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => darkModeNotifier),
        ChangeNotifierProvider(create: (_) => PhotoProvider()),
      ],
      child: EyeTimerApp(),
    ),
  );
}
