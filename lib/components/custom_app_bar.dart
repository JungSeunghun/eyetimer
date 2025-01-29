import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../providers/dark_mode_notifier.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final darkModeNotifier = Provider.of<DarkModeNotifier>(context);
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyMedium?.color ?? Colors.black;

    return AppBar(
      title: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300), // 애니메이션 지속 시간
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation, // 페이드 효과
            child: ScaleTransition(scale: animation, child: child), // 스케일 효과 추가
          );
        },
        child: Row(
          children: [
            SvgPicture.asset(
              darkModeNotifier.isDarkMode
                  ? 'assets/logos/logo_dark.svg'
                  : 'assets/logos/logo_light.svg',
              height: 24, // 로고 높이 설정
              fit: BoxFit.contain, // 로고 크기 맞춤
              key: ValueKey(darkModeNotifier.isDarkMode), // 상태에 따른 고유 키 설정
            ),
            const SizedBox(width: 8), // 로고와 텍스트 간 간격
            Text(
              'EyeTimer',
              style: TextStyle(
                fontSize: 18, // 텍스트 크기
                fontWeight: FontWeight.w600, // 텍스트 굵기
                color: textColor, // 다크모드에 따른 텍스트 색상
              ),
            ),
          ],
        ),
      ),
      centerTitle: false, // 로고와 텍스트를 중앙에 배치
      actions: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            return ScaleTransition(
              scale: animation,
              child: child,
            );
          },
          child: IconButton(
            key: ValueKey(darkModeNotifier.isDarkMode),
            icon: Icon(
              darkModeNotifier.isDarkMode
                  ? Icons.dark_mode_outlined
                  : Icons.light_mode_outlined,
            ),
            onPressed: () => darkModeNotifier.toggleDarkMode(),
          ),
        ),
      ],
    );
  }
}
