import 'package:flutter/material.dart';

class ControlButtons extends StatelessWidget {
  final bool isRunning;
  final VoidCallback onPlayPause;
  final VoidCallback onStop;
  final VoidCallback onTakePhoto;
  final Color primaryColor;
  final Color textColor;
  final double buttonIconSize;

  const ControlButtons({
    required this.isRunning,
    required this.onPlayPause,
    required this.onStop,
    required this.onTakePhoto,
    required this.primaryColor,
    required this.textColor,
    required this.buttonIconSize,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, -25),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(
              isRunning ? Icons.pause_outlined : Icons.play_arrow_outlined,
              size: buttonIconSize,
            ),
            onPressed: onPlayPause,
            color: primaryColor,
          ),
          IconButton(
            icon: Icon(Icons.stop_outlined, size: buttonIconSize),
            onPressed: onStop,
            color: Colors.deepOrange.shade300,
          ),
          IconButton(
            icon: Icon(Icons.camera_outlined, size: buttonIconSize - 8),
            onPressed: onTakePhoto,
            color: textColor,
          ),
        ],
      ),
    );
  }
}