import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import '../main.dart';

// 고유 ID를 생성하기 위한 함수 (SharedPreferences에 저장된 카운터 값을 증가시킴)
Future<int> getNextAlarmId() async {
  final prefs = await SharedPreferences.getInstance();
  int id = prefs.getInt('alarm_counter') ?? 0;
  await prefs.setInt('alarm_counter', id + 1);
  return id;
}

// Cupertino용 시간 선택 다이얼로그
Future<TimeOfDay?> showCupertinoTimePickerDialog(BuildContext context, {required TimeOfDay initialTime}) async {
  final theme = Theme.of(context);
  final backgroundColor = theme.scaffoldBackgroundColor;
  final textColor = theme.textTheme.bodyMedium?.color ?? Colors.black;

  DateTime initialDateTime = DateTime(0, 1, 1, initialTime.hour, initialTime.minute);
  TimeOfDay? pickedTime;
  await showCupertinoModalPopup(
    context: context,
    builder: (BuildContext context) {
      DateTime tempPickedDateTime = initialDateTime;
      return Container(
        height: 300,
        color: backgroundColor,
        child: CupertinoTheme(
          data: CupertinoThemeData(
            scaffoldBackgroundColor: backgroundColor,
            textTheme: CupertinoTextThemeData(
              dateTimePickerTextStyle: TextStyle(color: textColor, fontSize: 20),
            ),
          ),
          child: Column(
            children: [
              SizedBox(
                height: 200,
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  initialDateTime: initialDateTime,
                  use24hFormat: false,
                  onDateTimeChanged: (DateTime newDateTime) {
                    tempPickedDateTime = newDateTime;
                  },
                ),
              ),
              CupertinoButton(
                child: Text("save".tr(), style: TextStyle(color: textColor)),
                onPressed: () {
                  pickedTime = TimeOfDay(hour: tempPickedDateTime.hour, minute: tempPickedDateTime.minute);
                  Navigator.of(context).pop();
                },
              )
            ],
          ),
        ),
      );
    },
  );
  return pickedTime;
}

// 등록된 알람 목록을 가져오기
Future<List<Map<String, dynamic>>> getStoredAlarms() async {
  final prefs = await SharedPreferences.getInstance();
  final alarmsJson = prefs.getString('alarm_times');
  if (alarmsJson == null || alarmsJson.isEmpty) {
    return [];
  }
  final List<dynamic> decoded = jsonDecode(alarmsJson);
  return decoded.cast<Map<String, dynamic>>();
}

// 알람 목록 저장하기
Future<void> saveStoredAlarms(List<Map<String, dynamic>> alarms) async {
  final prefs = await SharedPreferences.getInstance();
  final alarmsJson = jsonEncode(alarms);
  await prefs.setString('alarm_times', alarmsJson);
}

// 알람 등록 (새 알람 추가)
Future<void> scheduleNotification(TimeOfDay selectedTime, BuildContext context) async {
  final now = tz.TZDateTime.now(tz.local);
  tz.TZDateTime scheduledTime = tz.TZDateTime(
    tz.local,
    now.year,
    now.month,
    now.day,
    selectedTime.hour,
    selectedTime.minute,
  );
  if (scheduledTime.isBefore(now)) {
    scheduledTime = scheduledTime.add(const Duration(days: 1));
  }
  final tz.TZDateTime tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);

  final String timeString = "${selectedTime.hour}:${selectedTime.minute.toString().padLeft(2, '0')}";

  // 동일한 시간의 알림이 이미 저장되어 있는지 확인
  final alarms = await getStoredAlarms();
  if (alarms.any((alarm) => alarm["time"] == timeString)) {
    return; // 동일 시간의 알림이 있으면 등록하지 않고 바로 return
  }

  // SharedPreferences 카운터를 이용해 고유 정수 ID 생성
  final int notificationId = await getNextAlarmId();

  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'vision_care_channel',
    'Vision Care Notifications',
    channelDescription: 'EyeTimerNotificationChannel',
    importance: Importance.max,
    priority: Priority.high,
    ticker: 'ticker',
  );
  const NotificationDetails notificationDetails = NotificationDetails(
    android: androidDetails,
  );

  await flutterLocalNotificationsPlugin.zonedSchedule(
    notificationId,
    'notification_title'.tr(),
    'notification_content'.tr(),
    tzScheduledTime,
    notificationDetails,
    uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    matchDateTimeComponents: DateTimeComponents.time,
  );

  // 알림 추가 후 저장된 알람 목록에 추가
  alarms.add({"id": notificationId, "time": timeString});
  await saveStoredAlarms(alarms);
}


// 알람 취소 (개별 삭제)
Future<void> cancelAlarm(int alarmId, BuildContext context) async {
  await flutterLocalNotificationsPlugin.cancel(alarmId);
  final alarms = await getStoredAlarms();
  alarms.removeWhere((alarm) => alarm["id"] == alarmId);
  await saveStoredAlarms(alarms);
}

// 알람 수정
Future<void> editAlarm(int alarmId, String currentTime, BuildContext context) async {
  final parts = currentTime.split(":");
  final initialTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));

  // CupertinoTimePicker 사용
  final TimeOfDay? picked = await showCupertinoTimePickerDialog(context, initialTime: initialTime);
  if (picked != null) {
    await flutterLocalNotificationsPlugin.cancel(alarmId);
    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledTime = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      picked.hour,
      picked.minute,
    );
    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }
    final tz.TZDateTime tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'vision_care_channel',
      'Vision Care Notifications',
      channelDescription: 'EyeTimerNotificationChannel',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      alarmId,
      'notification_title'.tr(),
      'notification_content'.tr(),
      tzScheduledTime,
      notificationDetails,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    final String newTimeString = "${picked.hour}:${picked.minute.toString().padLeft(2, '0')}";
    final alarms = await getStoredAlarms();
    for (var alarm in alarms) {
      if (alarm["id"] == alarmId) {
        alarm["time"] = newTimeString;
        break;
      }
    }
    await saveStoredAlarms(alarms);
  }
}

Future<void> showAlarmDialog(BuildContext context) async {
  // 최초에 alarms를 불러옵니다.
  List<Map<String, dynamic>> alarms = await getStoredAlarms();

  // 알람 목록을 시간순으로 정렬 (오전부터 오후 순)
  alarms.sort((a, b) {
    final aParts = a["time"].split(":");
    final bParts = b["time"].split(":");
    final aMinutes = int.parse(aParts[0]) * 60 + int.parse(aParts[1]);
    final bMinutes = int.parse(bParts[0]) * 60 + int.parse(bParts[1]);
    return aMinutes.compareTo(bMinutes);
  });

  final theme = Theme.of(context);
  final backgroundColor = theme.scaffoldBackgroundColor;
  final textColor = theme.textTheme.bodyMedium?.color ?? Colors.black;

  showModalBottomSheet(
    context: context,
    backgroundColor: backgroundColor,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "alarm_options_title".tr(),
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: alarms.isEmpty
                        ? Center(
                        child: Text("alarm_empty".tr(), style: TextStyle(color: textColor)))
                        : ListView.separated(
                      shrinkWrap: true,
                      itemCount: alarms.length,
                      separatorBuilder: (context, index) =>
                          Divider(color: textColor.withOpacity(0.3)),
                      itemBuilder: (context, index) {
                        final alarm = alarms[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: theme.primaryColor,
                            child: Icon(
                              Icons.alarm,
                              color: const Color(0xFFF8F7F5),
                              size: 20,
                            ),
                          ),
                          title: Builder(
                            builder: (_) {
                              final parts = alarm['time'].split(':');
                              final hour = int.parse(parts[0]);
                              final minute = int.parse(parts[1]);
                              final time = DateTime(0, 1, 1, hour, minute);
                              final formattedTime = DateFormat('a h:mm', 'ko').format(time);
                              return Text(
                                formattedTime,
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 24,
                                ),
                              );
                            },
                          ),
                          onTap: () async {
                            await editAlarm(alarm['id'], alarm['time'], context);
                            alarms = await getStoredAlarms();
                            // 알람 목록 정렬 후 setState 호출
                            alarms.sort((a, b) {
                              final aParts = a["time"].split(":");
                              final bParts = b["time"].split(":");
                              final aMinutes = int.parse(aParts[0]) * 60 + int.parse(aParts[1]);
                              final bMinutes = int.parse(bParts[0]) * 60 + int.parse(bParts[1]);
                              return aMinutes.compareTo(bMinutes);
                            });
                            setState(() {});
                          },
                          trailing: TextButton(
                            child: Text(
                              "delete".tr(),
                              style: const TextStyle(color: Colors.red),
                            ),
                            onPressed: () async {
                              final shouldDelete = await showDialog<bool>(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    backgroundColor: backgroundColor,
                                    title: Text("delete_confirm_title".tr(),
                                        style: TextStyle(color: textColor)),
                                    content: Text("delete_confirm_content".tr(),
                                        style: TextStyle(color: textColor)),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(false),
                                        child: Text("cancel".tr(), style: TextStyle(color: textColor)),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(true),
                                        child: Text("delete".tr(), style: TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  );
                                },
                              );
                              if (shouldDelete == true) {
                                await cancelAlarm(alarm['id'], context);
                                alarms = await getStoredAlarms();
                                // 알람 목록 정렬 후 setState 호출
                                alarms.sort((a, b) {
                                  final aParts = a["time"].split(":");
                                  final bParts = b["time"].split(":");
                                  final aMinutes = int.parse(aParts[0]) * 60 + int.parse(aParts[1]);
                                  final bMinutes = int.parse(bParts[0]) * 60 + int.parse(bParts[1]);
                                  return aMinutes.compareTo(bMinutes);
                                });
                                setState(() {});
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final TimeOfDay? picked = await showCupertinoTimePickerDialog(
                        context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (picked != null) {
                        await scheduleNotification(picked, context);
                        alarms = await getStoredAlarms();
                        // 알람 목록 정렬 후 setState 호출
                        alarms.sort((a, b) {
                          final aParts = a["time"].split(":");
                          final bParts = b["time"].split(":");
                          final aMinutes = int.parse(aParts[0]) * 60 + int.parse(aParts[1]);
                          final bMinutes = int.parse(bParts[0]) * 60 + int.parse(bParts[1]);
                          return aMinutes.compareTo(bMinutes);
                        });
                        setState(() {});
                      }
                    },
                    icon: Icon(Icons.add, color: textColor),
                    label: Text("alarm_set".tr()),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      backgroundColor: backgroundColor,
                      foregroundColor: textColor,
                      side: BorderSide(color: textColor),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("cancel".tr(), style: TextStyle(color: textColor)),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
