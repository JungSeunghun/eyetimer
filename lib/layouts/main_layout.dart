import 'package:EyeTimer/features/home/screens/home_screen.dart';
import 'package:EyeTimer/features/profile/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../components/custom_app_bar.dart';
import '../components/custom_bottom_navigation_bar.dart';
import '../features/exercise/screens/exercise_screen.dart';
import '../features/gallery/screens/gallery_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({Key? key}) : super(key: key);

  @override
  _MainLayoutState createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    HomeScreen(),    // 인덱스 0: 타이머 화면
    GalleryScreen(), // 인덱스 1: 갤러리 화면
    ExerciseScreen(),// 인덱스 2: 운동 화면
    ProfileScreen(), // 인덱스 3: 시력기록 화면
  ];

  Future<void> _handleBackButton() async {
    if (_currentIndex != 0) {
      setState(() {
        _currentIndex = 0;
      });
    } else {
      SystemNavigator.pop();
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
        appBar: CustomAppBar(),
        body: _screens[_currentIndex],
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
