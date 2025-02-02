import 'package:flutter/material.dart';

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
      backgroundColor: backgroundColor, // ✅ 배경색 적용
      title: Text(
        '시간 설정',
        style: TextStyle(color: textColor), // ✅ 제목 색상 적용
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildAdjustRow(
            label: '집중 시간',
            minutes: focusMinutes,
            seconds: focusSeconds,
            onMinutesChanged: (value) => setState(() => focusMinutes = value),
            onSecondsChanged: (value) => setState(() => focusSeconds = value),
            textColor: textColor,
          ),
          const SizedBox(height: 16),
          _buildAdjustRow(
            label: '쉬는 시간',
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
            '취소',
            style: TextStyle(color: textColor), // ✅ 버튼 색상 적용
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
            '확인',
            style: TextStyle(color: textColor), // ✅ 버튼 색상 적용
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
    required Color textColor, // ✅ 텍스트 색상 추가
  }) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor), // ✅ 텍스트 색상 적용
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: Icon(Icons.remove, color: textColor), // ✅ 아이콘 색상 적용
              onPressed: () {
                if (minutes > 1) onMinutesChanged(minutes - 1);
              },
              splashRadius: 20,
            ),
            Text(
              '$minutes 분',
              style: TextStyle(fontSize: 18, color: textColor), // ✅ 텍스트 색상 적용
            ),
            IconButton(
              icon: Icon(Icons.add, color: textColor), // ✅ 아이콘 색상 적용
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
              icon: Icon(Icons.remove, color: textColor), // ✅ 아이콘 색상 적용
              onPressed: () {
                if (seconds > 0) onSecondsChanged(seconds - 10);
              },
              splashRadius: 20,
            ),
            Text(
              '$seconds 초',
              style: TextStyle(fontSize: 18, color: textColor), // ✅ 텍스트 색상 적용
            ),
            IconButton(
              icon: Icon(Icons.add, color: textColor), // ✅ 아이콘 색상 적용
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
