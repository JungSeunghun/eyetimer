import 'package:flutter/material.dart';

class TimerDisplay extends StatelessWidget {
  final Duration currentDuration;
  final Color textColor;
  final VoidCallback onSettingsPressed; // 설정 버튼 콜백
  final double colonSpacing; // 숫자와 콜론 사이의 간격 (양쪽)

  const TimerDisplay({
    required this.currentDuration,
    required this.textColor,
    required this.onSettingsPressed,
    this.colonSpacing = 12.0, // 기본 간격 4.0
  });

  @override
  Widget build(BuildContext context) {
    final minutes = currentDuration.inMinutes.toString();
    final seconds = (currentDuration.inSeconds % 60).toString().padLeft(2, '0');

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontFamily: 'DS-Digital',
              fontSize: 96,
              color: textColor,
              height: 0.8,
            ),
            children: [
              TextSpan(text: minutes),
              WidgetSpan(child: SizedBox(width: colonSpacing)),
              const TextSpan(text: ':'),
              WidgetSpan(child: SizedBox(width: colonSpacing)),
              TextSpan(text: seconds),
            ],
          ),
        ),
        Align(
          alignment: Alignment.center,
          child: IconButton(
            icon: Icon(Icons.settings, color: textColor),
            onPressed: onSettingsPressed,
          ),
        ),
      ],
    );
  }
}
