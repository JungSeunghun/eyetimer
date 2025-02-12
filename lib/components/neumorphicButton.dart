import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/dark_mode_notifier.dart';

/// 뉴모피즘 스타일의 원형 버튼 (애니메이션 적용, DarkModeNotifier 활용)
class NeumorphicButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onPressed;
  final double size;
  final Color backgroundColor;

  const NeumorphicButton({
    Key? key,
    required this.child,
    required this.onPressed,
    required this.size,
    required this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Provider를 통해 다크모드 여부를 가져옵니다.
    final darkModeNotifier = Provider.of<DarkModeNotifier>(context);
    final isDarkMode = darkModeNotifier.isDarkMode;

    // 다크모드와 라이트모드에 따른 부드러운 그림자 색상 및 효과 설정
    final lightShadow = isDarkMode
        ? Colors.grey[800]!.withValues(alpha: 0.5)
        : Colors.white.withValues(alpha: 0.7);
    final darkShadow = isDarkMode
        ? Colors.black.withValues(alpha: 0.7)
        : Colors.black.withValues(alpha: 0.2);

    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: lightShadow,
              offset: const Offset(-5, -5),
              blurRadius: 12,
            ),
            BoxShadow(
              color: darkShadow,
              offset: const Offset(5, 5),
              blurRadius: 12,
            ),
          ],
        ),
        child: Center(child: child),
      ),
    );
  }
}
