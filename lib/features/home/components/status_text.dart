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
    return Transform.translate(
      offset: Offset(0, -15),
      child: Text(
        isRunning ? (isFocusMode ? focusModeText : breakModeText) : beforeStartText,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w300,
          height: 1.5,
          color: textColor,
        ),
      ),
    );
  }
}