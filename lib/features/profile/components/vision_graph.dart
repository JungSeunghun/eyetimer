import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math; // for rotation calculations

import '../../../models/vision_care.dart';

class VisionGraph extends StatefulWidget {
  final List<VisionCare> visionList;
  final Color textColor;

  const VisionGraph({
    Key? key,
    required this.visionList,
    required this.textColor,
  }) : super(key: key);

  @override
  _VisionGraphState createState() => _VisionGraphState();
}

class _VisionGraphState extends State<VisionGraph> {
  late int _pageSize;
  int _currentPage = 0;
  static const int _minPageSize = 2;

  @override
  void initState() {
    super.initState();
    // If visionList is not empty, initialize _pageSize; otherwise, set to 0.
    if (widget.visionList.isNotEmpty) {
      _pageSize = widget.visionList.length == 1 ? 2 : widget.visionList.length;
      _currentPage = 0;
    } else {
      _pageSize = 0;
    }
  }

  void _updateCurrentPage() {
    // Avoid division by zero by checking _pageSize first.
    if (_pageSize == 0) return;
    final int totalPages = (effectiveList().length / _pageSize).ceil();
    if (totalPages == 0) {
      _currentPage = 0;
    } else if (_currentPage >= totalPages) {
      _currentPage = totalPages - 1;
    }
  }

  // Returns a list with a duplicate dummy entry if visionList has only one element.
  List<VisionCare> effectiveList() {
    List<VisionCare> list = List.from(widget.visionList);
    if (list.length == 1) {
      list.add(VisionCare(
        date: list.first.date,
        leftEyeVision: list.first.leftEyeVision,
        rightEyeVision: list.first.rightEyeVision,
      ));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    // If visionList becomes non-empty and _pageSize is 0, reinitialize _pageSize.
    if (widget.visionList.isNotEmpty && _pageSize == 0) {
      _pageSize = widget.visionList.length == 1 ? 2 : widget.visionList.length;
      _currentPage = 0;
    }

    List<VisionCare> dataList = effectiveList();
    if (dataList.isEmpty) {
      return const SizedBox.shrink();
    }

    // Ensure _pageSize does not exceed the available data length.
    if (dataList.length < _pageSize) {
      _pageSize = dataList.length;
    }

    final double lineThickness = 5.0;
    final Color leftEyeColor = const Color(0xFFBFD8FA);
    final Color rightEyeColor = const Color(0xFFA5D6A7);
    final Color gridLineColor = widget.textColor.withOpacity(0.2);

    // Sort the data by date.
    List<VisionCare> sortedList = List.from(dataList)
      ..sort((a, b) => a.date.compareTo(b.date));

    final int totalPages = (sortedList.length / _pageSize).ceil();
    if (_currentPage >= totalPages) {
      _currentPage = totalPages - 1;
    }

    List<VisionCare> pageData;
    if (sortedList.length <= _pageSize) {
      pageData = sortedList;
    } else if (_currentPage == totalPages - 1 &&
        sortedList.length % _pageSize != 0) {
      pageData = sortedList.sublist(sortedList.length - _pageSize);
    } else {
      final int startIndex = _currentPage * _pageSize;
      final int endIndex = (startIndex + _pageSize <= sortedList.length)
          ? startIndex + _pageSize
          : sortedList.length;
      pageData = sortedList.sublist(startIndex, endIndex);
    }

    // Create FlSpots and labels.
    List<FlSpot> leftSpots = [];
    List<FlSpot> rightSpots = [];
    Map<int, String> dateLabels = {};
    for (int i = 0; i < pageData.length; i++) {
      final vision = pageData[i];
      leftSpots.add(FlSpot(i.toDouble(), vision.leftEyeVision));
      rightSpots.add(FlSpot(i.toDouble(), vision.rightEyeVision));
      dateLabels[i] = vision.date;
    }

    double minX = 0;
    double maxX = pageData.length == 1 ? 1.0 : (pageData.length - 1).toDouble();

    Widget chart = AspectRatio(
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
                      fitInside: SideTitleFitInsideData.fromTitleMeta(meta,
                          distanceFromEdge: 0),
                      child: Transform.rotate(
                        angle: -math.pi / 6,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            dateLabels[index]!,
                            style: TextStyle(
                                color: widget.textColor, fontSize: 12),
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
                    style: TextStyle(
                        color: widget.textColor, fontSize: 12),
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
          minX: minX,
          maxX: maxX,
          lineBarsData: [
            LineChartBarData(
              spots: leftSpots,
              isCurved: true,
              color: leftEyeColor,
              barWidth: lineThickness,
              dotData: FlDotData(show: false),
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
              dotData: FlDotData(show: false),
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
    );

    Widget navigationAndZoomButtons = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: _currentPage > 0
              ? () {
            setState(() {
              _currentPage--;
            });
          }
              : null,
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.zoom_in),
              onPressed: _pageSize > _minPageSize
                  ? () {
                setState(() {
                  _pageSize--;
                  _updateCurrentPage();
                });
              }
                  : null,
            ),
            const SizedBox(width: 8),
            Text(
              '$_pageSize per page',
              style: TextStyle(color: widget.textColor),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.zoom_out),
              onPressed: () {
                final int maxPageSize = dataList.length;
                if (_pageSize < maxPageSize) {
                  setState(() {
                    _pageSize++;
                    _updateCurrentPage();
                  });
                }
              },
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.arrow_forward_ios),
          onPressed: _currentPage < totalPages - 1
              ? () {
            setState(() {
              _currentPage++;
            });
          }
              : null,
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(width: 16, height: 16, color: leftEyeColor),
                  const SizedBox(width: 4),
                  Text(
                    'profile.left_eye'.tr(),
                    style:
                    TextStyle(color: widget.textColor, fontSize: 12),
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
                    style:
                    TextStyle(color: widget.textColor, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          chart,
          const SizedBox(height: 8),
          navigationAndZoomButtons,
        ],
      ),
    );
  }
}
