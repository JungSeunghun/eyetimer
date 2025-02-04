import 'package:flutter/material.dart';

class StatusText extends StatelessWidget {
  final bool isRunning;
  final bool isFocusMode;
  final String focusModeText;
  final String breakModeText;
  final String beforeStartText;
  final Color textColor;

  const StatusText({
    required this.isRunning,
    required this.isFocusMode,
    required this.focusModeText,
    required this.breakModeText,
    required this.beforeStartText,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      isRunning ? (isFocusMode ? focusModeText : breakModeText) : beforeStartText,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w300,
        height: 0.8,
        color: textColor,
      ),
    );
  }
}