import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex;

  CustomBottomNavigationBar({required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = theme.scaffoldBackgroundColor;
    final textColor = theme.textTheme.bodyMedium?.color ?? Colors.black;
    final primaryColor = theme.primaryColor;

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: backgroundColor,
      elevation: 0,
      currentIndex: currentIndex,
      selectedItemColor: textColor, // 선택된 아이템 색상
      unselectedItemColor: textColor.withValues(alpha: 0.5), // 선택되지 않은 아이템 색상
      onTap: (index) {
        switch (index) {
          case 0:
            context.go('/'); // 홈
            break;
          case 1:
            context.go('/gallery'); // 갤러리
            break;
          case 2:
            context.go('/settings'); // 설정
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.timer_outlined),
          label: '타이머',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.photo_library_outlined),
          label: '갤러리',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings_outlined),
          label: '설정',
        ),
      ],
    );
  }
}
