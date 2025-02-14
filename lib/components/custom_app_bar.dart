import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../main.dart';
import '../providers/dark_mode_notifier.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const CustomAppBar({Key? key, required this.title}) : super(key: key);

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

  // 매일 같은 시간에 알림이 울리도록 예약하고, 선택한 시간을 저장하는 함수
  Future<void> _scheduleNotification(TimeOfDay selectedTime, BuildContext context) async {
    final now = DateTime.now();
    DateTime scheduledTime = DateTime(
      now.year,
      now.month,
      now.day,
      selectedTime.hour,
      selectedTime.minute,
    );
    // 이미 지난 시간일 경우 내일로 예약
    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    // TZDateTime으로 변환
    final tz.TZDateTime tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'vision_care_channel', // 채널 ID
      'Vision Care Notifications', // 채널 이름
      channelDescription: '눈 건강 알림 채널',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );
    const NotificationDetails notificationDetails = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      0, // 노티피케이션 ID
      '눈 건강 알림', // 알림 제목
      '눈 깜빡임 게임할 시간입니다!', // 알림 내용
      tzScheduledTime,
      notificationDetails,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      // 매일 같은 시간에 반복되도록 지정
      matchDateTimeComponents: DateTimeComponents.time,
    );

    // 설정한 시간을 SharedPreferences에 저장 (예: "HH:mm" 형식)
    final prefs = await SharedPreferences.getInstance();
    final timeString = "${selectedTime.hour}:${selectedTime.minute.toString().padLeft(2, '0')}";
    await prefs.setString('alarm_time', timeString);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '노티피케이션이 매일 ${timeString}에 설정되었습니다.',
        ),
      ),
    );
  }

  // 알람 옵션 다이얼로그: 알람 상태(설정된 시간 또는 미설정)를 보여주고, 알람 설정/해제 선택
  Future<void> _showAlarmOptions(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final storedTime = prefs.getString('alarm_time'); // 설정된 알람 시간이 저장된 키

    String alarmStatus;
    if (storedTime == null || storedTime.isEmpty) {
      alarmStatus = "설정된 알람이 없습니다.";
    } else {
      alarmStatus = "현재 알람이 $storedTime 에 설정되어 있습니다.";
    }

    final theme = Theme.of(context);
    final backgroundColor = theme.scaffoldBackgroundColor;
    final textColor = theme.textTheme.bodyMedium?.color ?? Colors.black;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: backgroundColor, // 다이얼로그 배경색 설정
          title: Text("alarm_options_title".tr(), style: TextStyle(color: textColor)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(alarmStatus, style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(context); // 다이얼로그 닫기
                final TimeOfDay? picked = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (picked != null) {
                  await _scheduleNotification(picked, context);
                }
              },
              child: Text("alarm_set".tr()),
            ),
            TextButton(
              onPressed: () async {
                await flutterLocalNotificationsPlugin.cancel(0);
                // 알람 해제 시 저장된 알람 시간 제거
                await prefs.remove('alarm_time');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("alarm_cancelled".tr())),
                );
                Navigator.pop(context);
              },
              child: Text("alarm_cancel".tr()),
            ),
          ],
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
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
      centerTitle: false,
      actions: [
        IconButton(
          key: const ValueKey("whiteNoise"),
          icon: Icon(
            Icons.audio_file_outlined,
            color: textColor,
          ),
          onPressed: () => _showWhiteNoiseDialog(context),
        ),
        IconButton(
          key: const ValueKey("notification"),
          icon: Icon(
            Icons.notifications,
            color: textColor,
          ),
          onPressed: () => _showAlarmOptions(context),
        ),
        IconButton(
          key: ValueKey(darkModeNotifier.isDarkMode),
          icon: Icon(
            darkModeNotifier.isDarkMode
                ? Icons.light_mode_outlined
                : Icons.dark_mode_outlined,
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
