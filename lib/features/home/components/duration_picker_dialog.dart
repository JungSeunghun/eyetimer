import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class DurationPickerDialog extends StatefulWidget {
  final Duration focusDuration;
  final Duration breakDuration;
  final Function(Duration, Duration) onSave;

  const DurationPickerDialog({
    super.key,
    required this.focusDuration,
    required this.breakDuration,
    required this.onSave,
  });

  @override
  _DurationPickerDialogState createState() => _DurationPickerDialogState();
}

class _DurationPickerDialogState extends State<DurationPickerDialog> {
  late int focusMinutes;
  late int focusSeconds;
  late int breakMinutes;
  late int breakSeconds;

  @override
  void initState() {
    super.initState();
    focusMinutes = widget.focusDuration.inMinutes;
    focusSeconds = widget.focusDuration.inSeconds % 60;
    breakMinutes = widget.breakDuration.inMinutes;
    breakSeconds = widget.breakDuration.inSeconds % 60;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyMedium?.color ?? Colors.black;
    final backgroundColor = theme.scaffoldBackgroundColor; // AlertDialog 기본 배경색

    return AlertDialog(
      backgroundColor: backgroundColor,
      title: Text(
        'dialog_title'.tr(),
        style: TextStyle(color: textColor),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildAdjustRow(
            label: 'focus_time_label'.tr(),
            minutes: focusMinutes,
            seconds: focusSeconds,
            onMinutesChanged: (value) => setState(() => focusMinutes = value),
            onSecondsChanged: (value) => setState(() => focusSeconds = value),
            textColor: textColor,
          ),
          const SizedBox(height: 16),
          _buildAdjustRow(
            label: 'break_time_label'.tr(),
            minutes: breakMinutes,
            seconds: breakSeconds,
            onMinutesChanged: (value) => setState(() => breakMinutes = value),
            onSecondsChanged: (value) => setState(() => breakSeconds = value),
            textColor: textColor,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'cancel'.tr(),
            style: TextStyle(color: textColor),
          ),
        ),
        TextButton(
          onPressed: () {
            widget.onSave(
              Duration(minutes: focusMinutes, seconds: focusSeconds),
              Duration(minutes: breakMinutes, seconds: breakSeconds),
            );
            Navigator.pop(context);
          },
          child: Text(
            'confirm'.tr(),
            style: TextStyle(color: textColor),
          ),
        ),
      ],
    );
  }

  Widget _buildAdjustRow({
    required String label,
    required int minutes,
    required int seconds,
    required Function(int) onMinutesChanged,
    required Function(int) onSecondsChanged,
    required Color textColor,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: Icon(Icons.remove, color: textColor),
              onPressed: () {
                if (minutes > 1) onMinutesChanged(minutes - 1);
              },
              splashRadius: 20,
            ),
            Text(
              '$minutes ${'minute'.tr()}',
              style: TextStyle(fontSize: 18, color: textColor),
            ),
            IconButton(
              icon: Icon(Icons.add, color: textColor),
              onPressed: () {
                if (minutes < 60) onMinutesChanged(minutes + 1);
              },
              splashRadius: 20,
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: Icon(Icons.remove, color: textColor),
              onPressed: () {
                if (seconds > 0) onSecondsChanged(seconds - 10);
              },
              splashRadius: 20,
            ),
            Text(
              '$seconds ${'second'.tr()}',
              style: TextStyle(fontSize: 18, color: textColor),
            ),
            IconButton(
              icon: Icon(Icons.add, color: textColor),
              onPressed: () {
                if (seconds < 50) onSecondsChanged(seconds + 10);
              },
              splashRadius: 20,
            ),
          ],
        ),
      ],
    );
  }
}
