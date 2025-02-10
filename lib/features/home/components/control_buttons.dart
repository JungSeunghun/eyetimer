import 'package:flutter/material.dart';

class ControlButtons extends StatelessWidget {
  final bool isRunning;
  final bool isPaused;
  final VoidCallback onPlay; // 시작
  final VoidCallback onPause; // 일시 정지
  final VoidCallback onStop; // 중지
  final VoidCallback onTakePhoto; // 사진 찍기

  const ControlButtons({
    required this.isRunning,
    required this.isPaused,
    required this.onPlay,
    required this.onPause,
    required this.onStop,
    required this.onTakePhoto,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyMedium?.color ?? Colors.black;
    final primaryColor = theme.primaryColor;
    final backgroundColor = theme.scaffoldBackgroundColor;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 중지 버튼
        ElevatedButton(
          onPressed: onStop,
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: backgroundColor,
            foregroundColor: textColor,
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(8),
          ),
          child: Icon(
            Icons.refresh_rounded,
            size: 32,
            color: textColor,
          ),
        ),
        const SizedBox(width: 36),
        // 시작 / 일시 정지 버튼
        ElevatedButton(
          onPressed: isRunning ? (isPaused ? onPlay : onPause) : onPlay,
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF242424),
            foregroundColor: Color(0xFFF8F8F8),
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(8),
          ),
          child: Icon(
            isRunning
                ? (isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded)
                : Icons.play_arrow_rounded,
            size: 36,
            color: primaryColor,
          ),
        ),
        const SizedBox(width: 40),
        // 사진 찍기 버튼
        ElevatedButton(
          onPressed: onTakePhoto,
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: backgroundColor,
            foregroundColor: textColor,
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(8),
          ),
          child: Icon(
            Icons.photo_camera_outlined,
            size: 32,
            color: textColor,
          ),
        ),
      ],
    );
  }
}
