import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'components/alarm_dialog.dart';
import 'constants/colors.dart';
import 'providers/dark_mode_notifier.dart';
import 'layouts/main_layout.dart';

Future<void> initializeDefaultAlarms(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  final defaultsInitialized = prefs.getBool('defaults_initialized') ?? false;
  if (!defaultsInitialized) {
    await scheduleNotification(TimeOfDay(hour: 10, minute: 0), context);
    await scheduleNotification(TimeOfDay(hour: 20, minute: 0), context);
    await prefs.setBool('defaults_initialized', true);
  }
}

class EyeTimerApp extends StatefulWidget {
  @override
  _EyeTimerAppState createState() => _EyeTimerAppState();
}

class _EyeTimerAppState extends State<EyeTimerApp>
    with SingleTickerProviderStateMixin {
  late final GoRouter _router;
  late final AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      initializeDefaultAlarms(context);
    });

    // 애니메이션 컨트롤러 초기화
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // 애니메이션 설정
    _animation = _controller.drive(
      Tween<double>(begin: 0.0, end: 1.0).chain(
        CurveTween(curve: Curves.easeInOut),
      ),
    );

    // 라우터 초기화
    _router = _buildRouter();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // DarkModeNotifier에 리스너 추가
    final darkModeNotifier = Provider.of<DarkModeNotifier>(context, listen: false);
    darkModeNotifier.addListener(() {
      if (darkModeNotifier.isDarkMode) {
        _controller.forward(); // 다크 모드 애니메이션 시작
      } else {
        _controller.reverse(); // 라이트 모드 애니메이션 시작
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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

  GoRouter _buildRouter() {
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

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        // ThemeData.lerp를 사용하여 부드럽게 전환
        final interpolatedTheme = ThemeData.lerp(
          _buildTheme(isDarkMode: false),
          _buildTheme(isDarkMode: true),
          _animation.value,
        );

        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          routerConfig: _router,
          title: 'Eye Timer',
          theme: interpolatedTheme,
          darkTheme: _buildTheme(isDarkMode: true),
          themeMode: darkModeNotifier.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          locale: context.locale,
          supportedLocales: context.supportedLocales,
          localizationsDelegates: context.localizationDelegates,
        );
      },
    );
  }
}
