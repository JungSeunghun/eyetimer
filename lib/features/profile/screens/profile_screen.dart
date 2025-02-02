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
    final TextEditingController leftEyeController =
    TextEditingController(text: vision?.leftEyeVision.toString() ?? '');
    final TextEditingController rightEyeController =
    TextEditingController(text: vision?.rightEyeVision.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(vision == null ? '시력 추가' : '시력 수정'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: leftEyeController,
                decoration: const InputDecoration(labelText: '왼쪽 시력'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              TextField(
                controller: rightEyeController,
                decoration: const InputDecoration(labelText: '오른쪽 시력'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () async {
                final leftEye = double.tryParse(leftEyeController.text) ?? 0.0;
                final rightEye = double.tryParse(rightEyeController.text) ?? 0.0;
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
              child: const Text('저장'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteVision(int id) async {
    await _visionCareService.deleteVision(id);
    _loadVisionData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('프로파일'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '시력 기록',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: _visionList.length,
                itemBuilder: (context, index) {
                  final vision = _visionList[index];
                  return Card(
                    child: ListTile(
                      title: Text('${vision.date}'),
                      subtitle: Text(
                          '왼쪽 시력: ${vision.leftEyeVision}, 오른쪽 시력: ${vision.rightEyeVision}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _showVisionDialog(vision: vision),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _deleteVision(vision.id!),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: ElevatedButton(
                onPressed: () => _showVisionDialog(),
                child: const Text('시력 추가'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
