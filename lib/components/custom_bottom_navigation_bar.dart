import 'package:flutter/material.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;  // 콜백 추가

  const CustomBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = theme.scaffoldBackgroundColor;
    final textColor = theme.textTheme.bodyMedium?.color ?? Colors.black;

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: backgroundColor,
      elevation: 0,
      currentIndex: currentIndex,
      selectedItemColor: textColor, // 선택된 아이템 색상
      unselectedItemColor: textColor.withValues(alpha: 0.5), // 선택되지 않은 아이템 색상
      onTap: onTap,
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
          icon: Icon(Icons.remove_red_eye_outlined), // 운동 아이콘 추가
          label: '운동',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart_outlined),
          label: '시력기록',
        ),
      ],
    );
  }
}
