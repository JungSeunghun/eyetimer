import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'constants/colors.dart';
import 'screens/home_screen.dart';
import 'screens/gallery_screen.dart';
import 'screens/settings_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // SharedPreferences 및 카메라 초기화
  final prefs = await SharedPreferences.getInstance();
  final isDarkMode = prefs.getBool('isDarkMode') ?? false;

  runApp(EyeTimerApp(isDarkMode: isDarkMode));
}

class EyeTimerApp extends StatelessWidget {
  final bool isDarkMode;

  EyeTimerApp({required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: EyeTimerTheme(isDarkMode: isDarkMode),
    );
  }
}

class EyeTimerTheme extends StatefulWidget {
  final bool isDarkMode;

  EyeTimerTheme({required this.isDarkMode});

  @override
  _EyeTimerThemeState createState() => _EyeTimerThemeState();
}

class _EyeTimerThemeState extends State<EyeTimerTheme> {
  late bool isDarkMode;

  @override
  void initState() {
    super.initState();
    isDarkMode = widget.isDarkMode;
  }

  Future<void> _saveThemePreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', value);
  }

  void toggleTheme() {
    setState(() {
      isDarkMode = !isDarkMode;
      _saveThemePreference(isDarkMode);
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => HomeScreen(
            isDarkMode: isDarkMode,
            onToggleTheme: toggleTheme,
          ),
        ),
        GoRoute(
          path: '/gallery',
          builder: (context, state) => GalleryScreen(
            isDarkMode: isDarkMode,
            onToggleTheme: toggleTheme,
          ),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => SettingsScreen(
            isDarkMode: isDarkMode,
            onToggleTheme: toggleTheme,
          ),
        ),
      ],
    );

    return MaterialApp.router(
      routerConfig: router,
      theme: ThemeData(
        fontFamily: 'KoPubWorld',
        primaryColor: AppColors.lightPrimary,
        scaffoldBackgroundColor: AppColors.lightBackground,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.lightBackground,
          foregroundColor: AppColors.lightText,
        ),
        textTheme: TextTheme(
          bodyMedium: TextStyle(color: AppColors.lightText),
        ),
      ),
      darkTheme: ThemeData(
        fontFamily: 'KoPubWorld',
        primaryColor: AppColors.darkPrimary,
        scaffoldBackgroundColor: AppColors.darkBackground,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.darkBackground,
          foregroundColor: AppColors.darkText,
        ),
        textTheme: TextTheme(
          bodyMedium: TextStyle(color: AppColors.darkText),
        ),
      ),
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
    );
  }
}
