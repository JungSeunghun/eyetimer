import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import '../providers/dark_mode_notifier.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  const CustomAppBar({Key? key}) : super(key: key);

  Future<void> _showWhiteNoiseDialog(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    // 다이얼로그 시작 시 한 번만 초기화: 없으면 기본 무음(빈 문자열)
    String selected = prefs.getString('white_noise_asset') ?? '';
    // 옵션 목록: label과 asset 경로 (무음은 빈 문자열)
    final options = [
      {'label': 'white_noise_silent'.tr(), 'asset': ''},
      {'label': 'white_noise_rain'.tr(), 'asset': 'assets/sounds/rain.mp3'},
      {'label': 'white_noise_ocean'.tr(), 'asset': 'assets/sounds/ocean.mp3'},
      {'label': 'white_noise_wind'.tr(), 'asset': 'assets/sounds/wind.mp3'},
    ];

    // 다이얼로그에 적용할 테마 색상 가져오기
    final theme = Theme.of(context);
    final backgroundColor = theme.scaffoldBackgroundColor;
    final textColor = theme.textTheme.bodyMedium?.color ?? Colors.black;
    final primaryColor = theme.primaryColor;

    await showDialog(
      context: context,
      builder: (context) {
        // StatefulBuilder 내에서는 setState를 통해 selected를 업데이트합니다.
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: backgroundColor,
              title: Text(
                "white_noise_select".tr(),
                style: TextStyle(color: textColor),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: options.map((option) {
                    final asset = option['asset']!;
                    final label = option['label']!;
                    final isSelected = selected == asset;
                    return CheckboxListTile(
                      activeColor: textColor,
                      checkColor: primaryColor,
                      title: Text(label, style: TextStyle(color: textColor)),
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
                  child: Text("cancel".tr(), style: TextStyle(color: textColor)),
                ),
                TextButton(
                  onPressed: () async {
                    await prefs.setString('white_noise_asset', selected);
                    Navigator.pop(context);
                  },
                  child: Text("save".tr(), style: TextStyle(color: textColor)),
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
              'eye_timer'.tr(), // 번역 키: JSON에 "eye_timer": "Eye Timer" / "아이 타이머" 등으로 등록
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
            key: const ValueKey("whiteNoise"),
            icon: Icon(
              Icons.audiotrack_outlined,
              color: textColor,
            ),
            onPressed: () => _showWhiteNoiseDialog(context),
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
      ],
    );
  }
}
