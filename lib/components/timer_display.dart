import 'package:flutter/material.dart';

class TimerDisplay extends StatelessWidget {
  final Duration currentDuration;
  final Color textColor;

  const TimerDisplay({
    required this.currentDuration,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      _formatDuration(currentDuration),
      style: TextStyle(
        fontFamily: 'DS-Digital',
        fontSize: 96,
        color: textColor,
      ),
    );
  }

  String _formatDuration(Duration duration) {
    return '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
  }
}