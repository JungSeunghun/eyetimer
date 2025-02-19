import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../../components/google_banner_ad_widget.dart';
import '../../../models/vision_care.dart';
import '../../../services/vision_care_service.dart';
import '../components/vision_graph.dart';

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
            isEditing ? 'profile.vision_edit'.tr() : 'profile.vision_add'.tr(),
            style: TextStyle(color: textColor),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: leftEyeController,
                cursorColor: textColor,
                decoration: InputDecoration(
                  labelText: 'profile.left_eye'.tr(),
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
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true, signed: true),
                style: TextStyle(color: textColor),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: rightEyeController,
                cursorColor: textColor,
                decoration: InputDecoration(
                  labelText: 'profile.right_eye'.tr(),
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
                const TextInputType.numberWithOptions(
                    decimal: true, signed: true,
                ),
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
                        'profile.delete_confirm_title'.tr(),
                        style: TextStyle(color: textColor),
                      ),
                      content: Text(
                        'profile.delete_confirm_content'.tr(),
                        style: TextStyle(color: textColor),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(
                            'cancel'.tr(),
                            style: TextStyle(color: textColor),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(
                            'delete'.tr(),
                            style: const TextStyle(color: Colors.red),
                          ),
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
                child: Text(
                  'delete'.tr(),
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'cancel'.tr(),
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
                isEditing ? 'edit'.tr() : 'save'.tr(),
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
      body: _visionList.isEmpty
          ? Center(
        child: Text(
          'profile.no_record'.tr(),
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: textColor),
        ),
      )
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // VisionGraph를 ListView의 첫 항목으로 넣음
            VisionGraph(
              visionList: _visionList,
              textColor: textColor,
            ),
            const SizedBox(height: 16),
            ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: _visionList.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final reversedList = _visionList.reversed.toList();
                final vision = reversedList[index];
                return GestureDetector(
                  onTap: () => _showVisionDialog(vision: vision),
                  child: Card(
                    color: backgroundColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: textColor.withOpacity(0.2)),
                    ),
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vision.date,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Column(
                                children: [
                                  Text(
                                    'profile.left_eye'.tr(),
                                    style: TextStyle(fontSize: 14, color: textColor),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    vision.leftEyeVision.toString(),
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                children: [
                                  Text(
                                    'profile.right_eye'.tr(),
                                    style: TextStyle(fontSize: 14, color: textColor),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    vision.rightEyeVision.toString(),
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
