import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import '../main.dart';

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
        // Container의 배경색을 테마 색상으로 지정
        color: backgroundColor,
        child: CupertinoTheme(
          data: CupertinoThemeData(
            scaffoldBackgroundColor: backgroundColor,
            textTheme: CupertinoTextThemeData(
              // CupertinoDatePicker에 적용할 텍스트 스타일 설정
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
                // 버튼 텍스트에도 색상 적용
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
  final now = DateTime.now();
  DateTime scheduledTime = DateTime(
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
  // 고유 알람 id 생성 (예: 현재 밀리초 값의 나머지)
  final int alarmId = DateTime.now().millisecondsSinceEpoch.remainder(100000);

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

  final String timeString = "${selectedTime.hour}:${selectedTime.minute.toString().padLeft(2, '0')}";
  final alarms = await getStoredAlarms();
  alarms.add({"id": alarmId, "time": timeString});
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
    final now = DateTime.now();
    DateTime scheduledTime = DateTime(
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
          // UI를 업데이트할 때마다 alarms 변수도 최신 상태로 유지하도록 함
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "alarm_options_title".tr(),
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: alarms.isEmpty
                        ? Center(
                        child: Text("alarm_empty".tr(),
                            style: TextStyle(color: textColor)))
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
                            child: const Icon(Icons.alarm,
                                color: Colors.white, size: 20),
                          ),
                          title: Text(
                            alarm['time'],
                            style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.w500),
                          ),
                          // 리스트 아이템을 탭하면 수정 모달이 뜹니다.
                          onTap: () async {
                            await editAlarm(alarm['id'], alarm['time'], context);
                            // 수정 후 최신 데이터로 업데이트
                            alarms = await getStoredAlarms();
                            setState(() {});
                          },
                          trailing: TextButton(
                            child: Text(
                              "delete".tr(),
                              style: TextStyle(
                                color: Colors.red,
                              ),
                            ),
                            onPressed: () async {
                              // 삭제 전 확인 다이얼로그 표시
                              final shouldDelete = await showDialog<bool>(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text("delete_confirm_title".tr()),
                                    content:
                                    Text("delete_confirm_content?".tr()),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context)
                                                .pop(false),
                                        child: Text("cancel".tr()),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context)
                                                .pop(true),
                                        child: Text("delete".tr()),
                                      ),
                                    ],
                                  );
                                },
                              );
                              if (shouldDelete == true) {
                                await cancelAlarm(alarm['id'], context);
                                // 삭제 후 최신 데이터로 업데이트
                                alarms = await getStoredAlarms();
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
                      // Cupertino 시간 선택 다이얼로그 호출 후 알람 추가
                      final TimeOfDay? picked = await showCupertinoTimePickerDialog(
                        context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (picked != null) {
                        await scheduleNotification(picked, context);
                        // 알람 추가 후 최신 데이터로 업데이트
                        alarms = await getStoredAlarms();
                        setState(() {});
                      }
                    },
                    icon: Icon(
                      Icons.add,
                      color: textColor,
                    ),
                    label: Text("alarm_set".tr()),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      backgroundColor: backgroundColor,
                      foregroundColor: textColor,
                      side: BorderSide(color: textColor)
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
