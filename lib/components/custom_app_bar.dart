import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  CustomAppBar({
    required this.title,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyMedium?.color ?? Colors.black;

    return AppBar(
      title: Text(title),
      actions: [
        IconButton(
          icon: Icon(
            isDarkMode ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
            color: textColor,
          ),
          onPressed: onToggleTheme,
          tooltip: isDarkMode ? '라이트 모드로 변경' : '다크 모드로 변경',
        ),
      ],
    );
  }
}
