import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../components/memo_input_dialog.dart';
import '../models/photo.dart';
import '../providers/photo_provider.dart';

class GalleryScreen extends StatelessWidget {
  const GalleryScreen({super.key});

  String formatTimestamp(String timestamp) {
    final dateTime = DateTime.parse(timestamp);
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PhotoProvider>(
      builder: (context, photoProvider, child) {
        final groupedPhotos = photoProvider.groupedPhotos;
        final sortedDates = groupedPhotos.keys.toList()..sort((a, b) => b.compareTo(a));

        return Scaffold(
          body: groupedPhotos.isEmpty
              ? const Center(
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
              final photosForDate = groupedPhotos[date]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 날짜 헤더
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      date,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // 사진 그리드
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8.0,
                      mainAxisSpacing: 8.0,
                    ),
                    itemCount: photosForDate.length,
                    itemBuilder: (context, photoIndex) {
                      final photo = photosForDate[photoIndex];

                      return GestureDetector(
                        onTap: () async {
                          final updatedMemo = await showMemoInputDialog(
                            context,
                            initialMemo: photo.memo,
                            photoPath: photo.filePath,
                            isEditing: true,
                            onDelete: () async {
                              await photoProvider.deletePhoto(photo.id!);
                            },
                          );

                          if (updatedMemo != null) {
                            await photoProvider.updatePhotoMemo(photo.id!, updatedMemo);
                          }
                        },
                        child: _buildPhoto(photo),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPhoto(Photo photo) {
    return Stack(
      children: [
        // 이미지
        Image(
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
        // 날짜 및 시간
        Positioned(
          left: 8,
          bottom: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              formatTimestamp(photo.timestamp),
              style: const TextStyle(fontSize: 12, color: Colors.white),
            ),
          ),
        ),
        // 메모 오버레이
        if (photo.memo != null && photo.memo!.isNotEmpty)
          Center(
            child: Container(
              color: Colors.black.withValues(alpha: 0.5),
              padding: const EdgeInsets.all(8.0),
              child: Text(
                photo.memo!,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
