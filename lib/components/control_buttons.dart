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
                  ? (isPaused ? Icons.play_arrow_outlined : Icons.pause_outlined)
                  : Icons.play_arrow_outlined,
              size: buttonIconSize,
            ),
            onPressed: isRunning
                ? (isPaused ? onPlay : onPause)
                : onPlay, // 시작, 일시 정지, 재개 동작 설정
            color: primaryColor,
          ),
          IconButton(
            icon: Icon(Icons.stop_outlined, size: buttonIconSize),
            onPressed: onStop, // 중지
            color: Colors.deepOrange.shade300,
          ),
          IconButton(
            icon: Icon(Icons.camera_outlined, size: buttonIconSize - 8),
            onPressed: onTakePhoto, // 사진 찍기
            color: textColor,
          ),
        ],
      ),
    );
  }
}
