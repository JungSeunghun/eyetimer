import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math; // 회전 각도 계산을 위해 추가

import '../../../models/vision_care.dart';

class VisionGraph extends StatelessWidget {
  final List<VisionCare> visionList;
  final Color textColor;

  const VisionGraph({
    Key? key,
    required this.visionList,
    required this.textColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (visionList.isEmpty) {
      return const SizedBox.shrink();
    }

    // 선 굵기를 변수로 선언 (원하는 값으로 조정)
    final double lineThickness = 5.0;

    // 파스텔 톤 색상 변수 분리
    final Color leftEyeColor = const Color(0xFFBFD8FA); // 부드러운 파란색
    final Color rightEyeColor = const Color(0xFFA5D6A7); // 부드러운 녹색
    final Color dotStrokeColor = Colors.white;
    final Color gridLineColor = textColor.withOpacity(0.2);

    // 날짜순 정렬 (날짜 형식: "YYYY-MM-DD")
    List<VisionCare> sortedList = List.from(visionList)
      ..sort((a, b) => a.date.compareTo(b.date));

    List<FlSpot> leftSpots = [];
    List<FlSpot> rightSpots = [];
    Map<int, String> dateLabels = {};

    // dummy 데이터 추가: 데이터가 하나만 있는 경우
    if (sortedList.length == 1) {
      final vision = sortedList.first;
      leftSpots = [
        FlSpot(0, vision.leftEyeVision),
        FlSpot(1, vision.leftEyeVision),
      ];
      rightSpots = [
        FlSpot(0, vision.rightEyeVision),
        FlSpot(1, vision.rightEyeVision),
      ];
      dateLabels = {
        0: vision.date,
        1: vision.date,
      };
    } else {
      // 각 데이터를 FlSpot으로 변환 (x: 인덱스, y: 시력값)
      for (int i = 0; i < sortedList.length; i++) {
        final vision = sortedList[i];
        leftSpots.add(FlSpot(i.toDouble(), vision.leftEyeVision));
        rightSpots.add(FlSpot(i.toDouble(), vision.rightEyeVision));
        dateLabels[i] = vision.date;
      }
    }

    // x축 범위 설정: dummy 데이터인 경우 maxX는 2, 그 외는 (length - 1)
    double maxX = sortedList.length == 1 ? 1.0 : (sortedList.length - 1).toDouble();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // 범례(legend) 추가
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(width: 16, height: 16, color: leftEyeColor),
                  const SizedBox(width: 4),
                  Text(
                    'profile.left_eye'.tr(),
                    style: TextStyle(color: textColor, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Row(
                children: [
                  Container(width: 16, height: 16, color: rightEyeColor),
                  const SizedBox(width: 4),
                  Text(
                    'profile.right_eye'.tr(),
                    style: TextStyle(color: textColor, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          AspectRatio(
            aspectRatio: 1.7,
            child: LineChart(
              LineChartData(
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((LineBarSpot touchedSpot) {
                        String eyeType = touchedSpot.barIndex == 0
                            ? 'profile.left_eye'.tr()
                            : 'profile.right_eye'.tr();
                        return LineTooltipItem(
                          '$eyeType\n${dateLabels[touchedSpot.x.toInt()]}\n${touchedSpot.y.toStringAsFixed(1)}',
                          TextStyle(color: Colors.white, fontSize: 12),
                        );
                      }).toList();
                    },
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: gridLineColor,
                    strokeWidth: 1,
                  ),
                  getDrawingVerticalLine: (value) => FlLine(
                    color: gridLineColor,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    drawBelowEverything: false,
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt();
                        if (dateLabels.containsKey(index)) {
                          return SideTitleWidget(
                            meta: meta,
                            space: 4,
                            fitInside: SideTitleFitInsideData.fromTitleMeta(meta, distanceFromEdge: 0),
                            child: Transform.rotate(
                              angle: -math.pi / 6, // -30도 (왼쪽으로 30도 회전)
                              child: Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  dateLabels[index]!,
                                  style: TextStyle(color: textColor, fontSize: 12),
                                ),
                              ),
                            ),
                          );
                        }
                        return Container();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: 0.5,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toString(),
                          style: TextStyle(color: textColor, fontSize: 12),
                        );
                      },
                    ),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: gridLineColor),
                ),
                minX: 0,
                maxX: maxX,
                lineBarsData: [
                  LineChartBarData(
                    spots: leftSpots,
                    isCurved: true,
                    color: leftEyeColor,
                    barWidth: lineThickness,
                    dotData: FlDotData(
                      show: false, // 원을 제거
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: leftEyeColor.withOpacity(0.2),
                      gradient: LinearGradient(
                        colors: [
                          leftEyeColor.withOpacity(0.4),
                          leftEyeColor.withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  LineChartBarData(
                    spots: rightSpots,
                    isCurved: true,
                    color: rightEyeColor,
                    barWidth: lineThickness,
                    dotData: FlDotData(
                      show: false, // 원을 제거
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: rightEyeColor.withOpacity(0.2),
                      gradient: LinearGradient(
                        colors: [
                          rightEyeColor.withOpacity(0.4),
                          rightEyeColor.withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
