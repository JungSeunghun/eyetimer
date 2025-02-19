import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class DurationPickerDialog extends StatefulWidget {
  final Duration focusDuration;
  final Duration breakDuration;
  final Function(Duration, Duration) onSave;

  const DurationPickerDialog({
    Key? key,
    required this.focusDuration,
    required this.breakDuration,
    required this.onSave,
  }) : super(key: key);

  @override
  _DurationPickerDialogState createState() => _DurationPickerDialogState();
}

class _DurationPickerDialogState extends State<DurationPickerDialog> {
  late int focusMinutes;
  late int focusSeconds;
  late int breakMinutes;
  late int breakSeconds;

  late TextEditingController _focusMinutesController;
  late TextEditingController _focusSecondsController;
  late TextEditingController _breakMinutesController;
  late TextEditingController _breakSecondsController;

  @override
  void initState() {
    super.initState();
    focusMinutes = widget.focusDuration.inMinutes;
    focusSeconds = widget.focusDuration.inSeconds % 60;
    breakMinutes = widget.breakDuration.inMinutes;
    breakSeconds = widget.breakDuration.inSeconds % 60;

    _focusMinutesController =
        TextEditingController(text: focusMinutes.toString());
    _focusSecondsController =
        TextEditingController(text: focusSeconds.toString());
    _breakMinutesController =
        TextEditingController(text: breakMinutes.toString());
    _breakSecondsController =
        TextEditingController(text: breakSeconds.toString());
  }

  @override
  void dispose() {
    _focusMinutesController.dispose();
    _focusSecondsController.dispose();
    _breakMinutesController.dispose();
    _breakSecondsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyMedium?.color ?? Colors.black;
    final backgroundColor = theme.scaffoldBackgroundColor;

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
            minutesController: _focusMinutesController,
            secondsController: _focusSecondsController,
            onMinutesChanged: (value) => setState(() => focusMinutes = value),
            onSecondsChanged: (value) => setState(() => focusSeconds = value),
            textColor: textColor,
          ),
          const SizedBox(height: 16),
          _buildAdjustRow(
            label: 'break_time_label'.tr(),
            minutes: breakMinutes,
            seconds: breakSeconds,
            minutesController: _breakMinutesController,
            secondsController: _breakSecondsController,
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
            'save'.tr(),
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
    required TextEditingController minutesController,
    required TextEditingController secondsController,
    required Function(int) onMinutesChanged,
    required Function(int) onSecondsChanged,
    required Color textColor,
  }) {
    return Column(
      children: [
        Text(
          label,
          style:
          TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
        ),
        const SizedBox(height: 8),
        // 분 입력 Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: Icon(Icons.remove, color: textColor),
              onPressed: () {
                if (minutes > 1) {
                  int newVal = minutes - 1;
                  onMinutesChanged(newVal);
                  minutesController.text = newVal.toString();
                }
              },
              splashRadius: 20,
            ),
            SizedBox(
              width: 80,
              child: TextFormField(
                controller: minutesController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: textColor),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  border: UnderlineInputBorder(
                    borderSide: BorderSide(color: textColor),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: textColor),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: textColor),
                  ),
                  suffixText: ' ${'minute'.tr()}',
                ),
                onFieldSubmitted: (value) {
                  int newVal = int.tryParse(value) ?? 1;
                  if (newVal < 1) {
                    newVal = 1;
                  }
                  onMinutesChanged(newVal);
                  minutesController.text = newVal.toString();
                },

                cursorColor: textColor,
              ),
            ),
            IconButton(
              icon: Icon(Icons.add, color: textColor),
              onPressed: () {
                if (minutes < 60) {
                  int newVal = minutes + 1;
                  onMinutesChanged(newVal);
                  minutesController.text = newVal.toString();
                }
              },
              splashRadius: 20,
            ),
          ],
        ),
        // 초 입력 Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: Icon(Icons.remove, color: textColor),
              onPressed: () {
                if (seconds > 0) {
                  int newVal = seconds - 10;
                  if (newVal < 0) newVal = 0;
                  onSecondsChanged(newVal);
                  secondsController.text = newVal.toString();
                }
              },
              splashRadius: 20,
            ),
            SizedBox(
              width: 80,
              child: TextFormField(
                controller: secondsController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: textColor),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  border: UnderlineInputBorder(
                    borderSide: BorderSide(color: textColor),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: textColor),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: textColor),
                  ),
                  suffixText: ' ${'second'.tr()}',
                ),
                onFieldSubmitted: (value) {
                  int newVal = int.tryParse(value) ?? 1;
                  if (newVal < 1) {
                    newVal = 1;
                  }
                  onMinutesChanged(newVal);
                  minutesController.text = newVal.toString();
                },
                cursorColor: textColor,
              ),
            ),
            IconButton(
              icon: Icon(Icons.add, color: textColor),
              onPressed: () {
                if (seconds < 50) {
                  int newVal = seconds + 10;
                  onSecondsChanged(newVal);
                  secondsController.text = newVal.toString();
                }
              },
              splashRadius: 20,
            ),
          ],
        ),
      ],
    );
  }
}
