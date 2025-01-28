import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../dark_mode_notifier.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  CustomAppBar({required this.title});

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final darkModeNotifier = Provider.of<DarkModeNotifier>(context);

    return AppBar(
      title: Text(title),
      actions: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
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
