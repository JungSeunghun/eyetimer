import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap; // 콜백 추가

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
      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.timer_outlined),
          label: 'bottom_nav_timer'.tr(), // "타이머" 번역 키
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.photo_library_outlined),
          label: 'bottom_nav_gallery'.tr(), // "갤러리" 번역 키
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.remove_red_eye_outlined),
          label: 'bottom_nav_exercise'.tr(), // "운동" 번역 키
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.bar_chart_outlined),
          label: 'bottom_nav_eye_record'.tr(), // "시력기록" 번역 키
        ),
      ],
    );
  }
}
