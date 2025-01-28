import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../components/memo_input_dialog.dart';
import '../models/photo.dart';
import '../services/photo_service.dart';
import '../components/custom_app_bar.dart';
import '../components/custom_bottom_navigation_bar.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  _GalleryScreenState createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final PhotoService _photoService = PhotoService();
  Map<String, List<Photo>> groupedPhotos = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllPhotos().then((_) {
      setState(() {
        isLoading = false;
      });
    });
  }

  Future<void> _loadAllPhotos() async {
    final photos = await _photoService.getAllPhotos();

    // 사진을 날짜별로 그룹화
    final Map<String, List<Photo>> grouped = {};
    for (final photo in photos) {
      final date = DateFormat('yyyy-MM-dd').format(DateTime.parse(photo.timestamp));
      if (!grouped.containsKey(date)) {
        grouped[date] = [];
      }
      grouped[date]?.add(photo);
    }

    // 상태 업데이트
    setState(() {
      groupedPhotos = grouped;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyMedium?.color ?? Colors.black;
    final primaryColor = theme.primaryColor;

    final sortedDates = groupedPhotos.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // 최신순으로 정렬

    return Scaffold(
      appBar: CustomAppBar(
        title: '갤러리',
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : groupedPhotos.isEmpty
          ? Center(
        child: Text(
          '아직 찍은 사진이 없습니다.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: sortedDates.length,
        itemBuilder: (context, index) {
          final date = sortedDates[index];
          final photos = groupedPhotos[date]!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 날짜 헤더
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  date,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
              // 사진 그리드
              GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, // 사진을 3열로 표시
                  crossAxisSpacing: 8.0,
                  mainAxisSpacing: 8.0,
                ),
                itemCount: photos.length,
                itemBuilder: (context, photoIndex) {
                  final photo = photos[photoIndex];
                  return GestureDetector(
                    onTap: () async {
                      // 메모 입력 다이얼로그 호출
                      final updatedMemo = await showMemoInputDialog(
                        context,
                        initialMemo: photo.memo,
                        photoPath: photo.filePath,
                        isEditing: true,
                        onDelete: () async {
                          await _photoService.deletePhoto(photo.id!);
                          _loadAllPhotos();
                        },
                      );

                      // 메모가 업데이트된 경우 처리
                      if (updatedMemo != null) {
                        await _photoService.updatePhotoMemo(photo.id!, updatedMemo);
                        _loadAllPhotos();
                      }
                    },
                    child: Image(
                      image: ResizeImage(
                        FileImage(File(photo.filePath)),
                        width: 300,
                        height: 300,
                      ),
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.low,
                      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                        if (wasSynchronouslyLoaded) return child;
                        return AnimatedOpacity(
                          child: child,
                          opacity: frame == null ? 0 : 1,
                          duration: const Duration(seconds: 1),
                          curve: Curves.easeOut,
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
     );
  }
}
