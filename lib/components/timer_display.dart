import 'package:flutter/material.dart';

class TimerDisplay extends StatelessWidget {
  final Duration currentDuration;
  final Color textColor;
  final VoidCallback onTap; // 추가된 콜백

  const TimerDisplay({
    required this.currentDuration,
    required this.textColor,
    required this.onTap, // 추가된 콜백
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap, // 터치 시 다이얼로그 표시
      child: Text(
        _formatDuration(currentDuration),
        style: TextStyle(
          fontFamily: 'DS-Digital',
          fontSize: 96,
          color: textColor,
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    return '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
  }
}