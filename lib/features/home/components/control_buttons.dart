import 'package:flutter/material.dart';

class ControlButtons extends StatelessWidget {
  final bool isRunning;
  final bool isPaused;
  final VoidCallback onPlay; // 시작
  final VoidCallback onPause; // 일시 정지
  final VoidCallback onStop; // 중지
  final VoidCallback onTakePhoto; // 사진 찍기
  final Color primaryColor;
  final Color textColor;
  final double buttonIconSize;

  const ControlButtons({
    required this.isRunning,
    required this.isPaused,
    required this.onPlay,
    required this.onPause,
    required this.onStop,
    required this.onTakePhoto,
    required this.primaryColor,
    required this.textColor,
    required this.buttonIconSize,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -25),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(
              isRunning
                  ? (isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded)
                  : Icons.play_arrow_rounded,
              size: buttonIconSize,
            ),
            onPressed: isRunning
                ? (isPaused ? onPlay : onPause)
                : onPlay, // 시작, 일시 정지, 재개 동작 설정
            color: textColor,
          ),
          IconButton(
            icon: Icon(Icons.photo_camera_rounded, size: buttonIconSize - 8),
            onPressed: onTakePhoto, // 사진 찍기
            color: primaryColor,
          ),
          IconButton(
            icon: Icon(Icons.stop_rounded, size: buttonIconSize),
            onPressed: onStop, // 중지
            color: textColor,
          ),
        ],
      ),
    );
  }
}
