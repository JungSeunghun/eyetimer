import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/dark_mode_notifier.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  const CustomAppBar({Key? key}) : super(key: key);

  Future<void> _showWhiteNoiseDialog(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    // 다이얼로그 함수 시작 시 한 번만 초기화: 없으면 기본 무음(빈 문자열)
    String selected = prefs.getString('white_noise_asset') ?? '';
    // 옵션 목록: label과 asset 경로 (무음은 빈 문자열)
    final options = [
      {'label': '무음', 'asset': ''},
      {'label': '빗소리', 'asset': 'assets/sounds/rain.mp3'},
      {'label': '파도 소리', 'asset': 'assets/sounds/ocean.mp3'},
      {'label': '바람 소리', 'asset': 'assets/sounds/wind.mp3'},
    ];

    await showDialog(
      context: context,
      builder: (context) {
        // StatefulBuilder 내에서는 setState를 통해 selected를 업데이트합니다.
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("백색소음 선택"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: options.map((option) {
                    final asset = option['asset']!;
                    final label = option['label']!;
                    final isSelected = selected == asset;
                    return CheckboxListTile(
                      title: Text(label),
                      value: isSelected,
                      onChanged: (bool? value) {
                        setState(() {
                          // 하나만 선택되도록: true이면 해당 asset, false이면 무음(빈 문자열)
                          selected = value == true ? asset : '';
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("취소"),
                ),
                TextButton(
                  onPressed: () async {
                    await prefs.setString('white_noise_asset', selected);
                    Navigator.pop(context);
                  },
                  child: const Text("확인"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final darkModeNotifier = Provider.of<DarkModeNotifier>(context);
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyMedium?.color ?? Colors.black;

    return AppBar(
      title: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(scale: animation, child: child),
          );
        },
        child: Row(
          children: [
            SvgPicture.asset(
              darkModeNotifier.isDarkMode
                  ? 'assets/logos/logo_dark.svg'
                  : 'assets/logos/logo_light.svg',
              height: 24,
              fit: BoxFit.contain,
              key: ValueKey(darkModeNotifier.isDarkMode),
            ),
            const SizedBox(width: 8),
            Text(
              'EyeTimer',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
      centerTitle: false,
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
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
              color: textColor,
            ),
            onPressed: () => darkModeNotifier.toggleDarkMode(),
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            return ScaleTransition(
              scale: animation,
              child: child,
            );
          },
          child: IconButton(
            key: const ValueKey("whiteNoise"),
            icon: Icon(
              Icons.volume_up,
              color: textColor,
            ),
            onPressed: () => _showWhiteNoiseDialog(context),
          ),
        ),
      ],
    );
  }
}
