import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import '../providers/dark_mode_notifier.dart';
import 'alarm_dialog.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const CustomAppBar({Key? key, required this.title}) : super(key: key);

  // 백색소음 다이얼로그 (변경 없음)
  Future<void> _showWhiteNoiseDialog(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    String selected = prefs.getString('white_noise_asset') ?? '';
    final options = [
      {'label': 'white_noise_silent'.tr(), 'asset': ''},
      {'label': 'white_noise_rain'.tr(), 'asset': 'assets/sounds/rain.mp3'},
      {'label': 'white_noise_ocean'.tr(), 'asset': 'assets/sounds/ocean.mp3'},
      {'label': 'white_noise_wind'.tr(), 'asset': 'assets/sounds/wind.mp3'},
    ];

    final theme = Theme.of(context);
    final backgroundColor = theme.scaffoldBackgroundColor;
    final textColor = theme.textTheme.bodyMedium?.color ?? Colors.black;
    final primaryColor = theme.primaryColor;

    await showDialog(
      context: context,
      builder: (context) {
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
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            darkModeNotifier.isDarkMode
                ? 'assets/logos/logo_dark.svg'
                : 'assets/logos/logo_light.svg',
            height: 24,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textColor),
          ),
        ],
      ),
      centerTitle: false,
      actions: [
        IconButton(
          key: const ValueKey("whiteNoise"),
          icon: Icon(Icons.audio_file_outlined, color: textColor),
          onPressed: () => _showWhiteNoiseDialog(context),
        ),
        IconButton(
          key: const ValueKey("notification"),
          icon: Icon(Icons.notifications_outlined, color: textColor),
          onPressed: () => showAlarmDialog(context),
        ),
        IconButton(
          key: ValueKey(darkModeNotifier.isDarkMode),
          icon: Icon(
            darkModeNotifier.isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            color: textColor,
          ),
          onPressed: () => darkModeNotifier.toggleDarkMode(),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
