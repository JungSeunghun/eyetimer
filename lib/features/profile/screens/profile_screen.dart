import 'package:flutter/material.dart';
import '../../../models/vision_care.dart';
import '../../../services/vision_care_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final VisionCareService _visionCareService = VisionCareService();
  List<VisionCare> _visionList = [];

  @override
  void initState() {
    super.initState();
    _loadVisionData();
  }

  Future<void> _loadVisionData() async {
    final visions = await _visionCareService.getVisionHistory();
    setState(() {
      _visionList = visions;
    });
  }

  void _showVisionDialog({VisionCare? vision}) {
    final bool isEditing = vision != null;
    final TextEditingController leftEyeController = TextEditingController(
        text: isEditing ? vision!.leftEyeVision.toString() : '');
    final TextEditingController rightEyeController = TextEditingController(
        text: isEditing ? vision!.rightEyeVision.toString() : '');

    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyMedium?.color ?? Colors.black;
    final backgroundColor = theme.scaffoldBackgroundColor;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: backgroundColor,
          title: Text(
            isEditing ? '시력 수정' : '시력 추가',
            style: TextStyle(color: textColor),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: leftEyeController,
                cursorColor: textColor,
                decoration: InputDecoration(
                  labelText: '왼쪽 시력',
                  labelStyle: TextStyle(color: textColor),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: textColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: textColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: textColor),
                  ),
                ),
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(color: textColor),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: rightEyeController,
                cursorColor: textColor,
                decoration: InputDecoration(
                  labelText: '오른쪽 시력',
                  labelStyle: TextStyle(color: textColor),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: textColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: textColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: textColor),
                  ),
                ),
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(color: textColor),
              ),
            ],
          ),
          actions: [
            if (isEditing)
              TextButton(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: backgroundColor,
                      title: Text(
                        '삭제 확인',
                        style: TextStyle(color: textColor),
                      ),
                      content: Text(
                        '해당 시력 기록을 삭제하시겠습니까?',
                        style: TextStyle(color: textColor),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('취소'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('삭제'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await _visionCareService.deleteVision(vision!.id!);
                    Navigator.pop(context);
                    _loadVisionData();
                  }
                },
                child: const Text(
                  '삭제',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                '취소',
                style: TextStyle(color: textColor),
              ),
            ),
            TextButton(
              onPressed: () async {
                final leftEye =
                    double.tryParse(leftEyeController.text) ?? 0.0;
                final rightEye =
                    double.tryParse(rightEyeController.text) ?? 0.0;
                final newVision = VisionCare(
                  id: vision?.id,
                  date: DateTime.now().toIso8601String().split('T')[0],
                  leftEyeVision: leftEye,
                  rightEyeVision: rightEye,
                );

                await _visionCareService.saveVision(newVision);
                Navigator.pop(context);
                _loadVisionData();
              },
              child: Text(
                isEditing ? '수정' : '저장',
                style: TextStyle(color: textColor),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyMedium?.color ?? Colors.black;
    final backgroundColor = theme.scaffoldBackgroundColor;
    final primaryColor = theme.primaryColor;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        onPressed: () => _showVisionDialog(),
        child: Icon(
          Icons.add,
          color: backgroundColor,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '시력 기록',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _visionList.isEmpty
                  ? Center(
                child: Text(
                  '기록이 없습니다.\nFAB 버튼을 눌러 시력을 추가하세요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: textColor),
                ),
              )
                  : ListView.separated(
                itemCount: _visionList.length,
                separatorBuilder: (context, index) =>
                const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final vision = _visionList[index];
                  return GestureDetector(
                    onTap: () => _showVisionDialog(vision: vision),
                    child: Card(
                      color: backgroundColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              vision.date,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '왼쪽 시력: ${vision.leftEyeVision}   오른쪽 시력: ${vision.rightEyeVision}',
                              style: TextStyle(
                                fontSize: 14,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
