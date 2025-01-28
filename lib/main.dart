import 'package:eyetimer/layouts/main_layout.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'constants/colors.dart';
import 'dark_mode_notifier.dart';
import 'screens/home_screen.dart';
import 'screens/gallery_screen.dart';
import 'screens/settings_screen.dart';

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

class EyeTimerApp extends StatefulWidget { // StatefulWidget으로 변경
  @override
  _EyeTimerAppState createState() => _EyeTimerAppState();
}

class _EyeTimerAppState extends State<EyeTimerApp> {
  late final GoRouter _router; // 라우터 인스턴스

  @override
  void initState() {
    super.initState();
    _router = _buildRouter(); // 초기화 시 라우터 생성
  }

  ThemeData _buildTheme({required bool isDarkMode}) {
    return ThemeData(
      fontFamily: 'KoPubWorld',
      primaryColor: isDarkMode ? AppColors.darkPrimary : AppColors.lightPrimary,
      scaffoldBackgroundColor:
      isDarkMode ? AppColors.darkBackground : AppColors.lightBackground,
      appBarTheme: AppBarTheme(
        backgroundColor:
        isDarkMode ? AppColors.darkBackground : AppColors.lightBackground,
        foregroundColor: isDarkMode ? AppColors.darkText : AppColors.lightText,
      ),
      textTheme: TextTheme(
        bodyMedium: TextStyle(
          color: isDarkMode ? AppColors.darkText : AppColors.lightText,
        ),
      ),
    );
  }

  GoRouter _buildRouter() { // 컨텍스트 의존성 제거
    return GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => MainLayout(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final darkModeNotifier = Provider.of<DarkModeNotifier>(context);

    return AnimatedTheme(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      data: _buildTheme(isDarkMode: darkModeNotifier.isDarkMode),
      child: MaterialApp.router(
        routerConfig: _router, // 동일한 라우터 인스턴스 사용
        theme: _buildTheme(isDarkMode: false),
        darkTheme: _buildTheme(isDarkMode: true),
        themeMode: darkModeNotifier.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      ),
    );
  }
}