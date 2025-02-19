import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class TimerDisplay extends StatelessWidget {
  final Duration currentDuration;
  final Duration focusDuration;
  final Duration breakDuration;
  final bool isFocusMode;
  final double colonSpacing; // 숫자와 콜론 사이의 간격
  // 기본 진행바 색상 (원래 색상 유지)
  final Color indicatorColor;

  const TimerDisplay({
    required this.currentDuration,
    required this.focusDuration,
    required this.breakDuration,
    required this.isFocusMode,
    this.colonSpacing = 12.0,
    this.indicatorColor = const Color(0xFFF8F7F5),
  });

  @override
  Widget build(BuildContext context) {
    // shadowColor 변수로 분리
    final Color shadowColor = const Color(0xFF242424);
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    // 집중 모드(isFocusMode)에 따라 최대 시간 결정
    final effectiveMaxDuration = isFocusMode ? focusDuration : breakDuration;
    final minutes = currentDuration.inMinutes.toString();
    final seconds = (currentDuration.inSeconds % 60).toString().padLeft(2, '0');

    // 진행률 계산 (남은 시간 / 전체 시간)
    final double progress =
        currentDuration.inSeconds / effectiveMaxDuration.inSeconds;

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: shadowColor.withValues(alpha: 0.1),
            offset: const Offset(4, 4),
            blurRadius: 8,
          ),
        ],
      ),
      child: CircularPercentIndicator(
        radius: 130.0,
        lineWidth: 4.0,
        animation: true,
        animateFromLastPercent: true,
        animationDuration: 300,
        reverse: true,
        percent: progress.clamp(0.0, 1.0),
        progressColor: indicatorColor,
        backgroundColor: primaryColor.withValues(alpha: 0.2),
        circularStrokeCap: CircularStrokeCap.round,
        center: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: TextStyle(
              fontFamily: 'DS-Digital',
              fontSize: 88,
              color: indicatorColor,
              height: 0.8,
              shadows: [
                Shadow(
                  offset: const Offset(2.0, 2.0),
                  blurRadius: 3.0,
                  color: shadowColor.withValues(alpha: 0.3),
                ),
              ],
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
      ),
    );
  }
}
