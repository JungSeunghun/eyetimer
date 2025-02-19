// main_layout.dart
import 'package:EyeTimer/screens/home/screens/home_screen.dart';
import 'package:EyeTimer/screens/profile/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../components/custom_app_bar.dart';
import '../components/custom_bottom_navigation_bar.dart';
import '../providers/timer_provider.dart';
import '../screens/exercise/screens/exercise_screen.dart';
import '../screens/gallery/screens/gallery_screen.dart';
import 'package:easy_localization/easy_localization.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({Key? key}) : super(key: key);

  @override
  _MainLayoutState createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  final List<Widget> _screens = [];

  @override
  void initState() {
    super.initState();
    // HomeScreen에 key를 할당하여 생성
    _screens.addAll([
      HomeScreen(),    // 인덱스 0: 타이머 화면
      GalleryScreen(),                   // 인덱스 1: 갤러리 화면
      ExerciseScreen(),                  // 인덱스 2: 운동 화면
      ProfileScreen(),                   // 인덱스 3: 시력기록 화면
    ]);
  }

  Future<void> _handleBackButton() async {
    if (_currentIndex != 0) {
      setState(() {
        _currentIndex = 0;
      });
    } else {
      // 테마에서 텍스트 색상과 배경색 가져오기
      final theme = Theme.of(context);
      final textColor = theme.textTheme.bodyMedium?.color ?? Colors.black;
      final backgroundColor = theme.scaffoldBackgroundColor;

      // 앱 종료 전 확인 다이얼로그 표시
      final shouldExit = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: backgroundColor,
            title: Text(
              'exit_dialog_title'.tr(),
              style: TextStyle(color: textColor),
            ),
            content: Text(
              'exit_dialog_content'.tr(),
              style: TextStyle(color: textColor),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'exit_dialog_cancel'.tr(),
                  style: TextStyle(color: textColor),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  'exit_dialog_confirm'.tr(),
                  style: TextStyle(color: textColor),
                ),
              ),
            ],
          );
        },
      );
      // "예"를 선택한 경우
      // "예"를 선택한 경우
      if (shouldExit == true) {
        // TimerProvider를 통해 타이머 실행 여부 확인 및 중지
        final timerProvider = Provider.of<TimerProvider>(context, listen: false);
        if (timerProvider.isTimerRunning) {
          timerProvider.stopTimer();
        }
        SystemNavigator.pop();
      }

    }
  }

  /// 현재 인덱스에 따른 스크린 타이틀 반환
  String _getScreenTitle(BuildContext context) {
    switch (_currentIndex) {
      case 0:
        return 'bottom_nav_timer'.tr();
      case 1:
        return 'bottom_nav_gallery'.tr();
      case 2:
        return 'bottom_nav_exercise'.tr();
      case 3:
        return 'bottom_nav_eye_record'.tr();
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        await _handleBackButton();
      },
      child: Scaffold(
        appBar: CustomAppBar(title: _getScreenTitle(context)),
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: CustomBottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
        ),
      ),
    );
  }
}
