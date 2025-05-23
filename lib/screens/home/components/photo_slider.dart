import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/photo.dart';
import '../../../components/memo_input_dialog.dart';

class PhotoSlider extends StatelessWidget {
  final List<Photo> todayPhotos;
  final PageController pageController;
  final Color textColor;
  final Function(Photo, String) onEditMemo; // 수정 시 호출
  final Function(Photo) onDeletePhoto; // 삭제 시 호출

  const PhotoSlider({
    required this.todayPhotos,
    required this.pageController,
    required this.textColor,
    required this.onEditMemo,
    required this.onDeletePhoto,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.width,
        child: todayPhotos.isEmpty
            ? _buildEmptyState()
            : _buildPhotoSlider(context),
      ),
    );
  }


  Widget _buildEmptyState() {
    return ClipRRect(
      child: Stack(
        children: [
          Positioned.fill(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
              child: Image(
                image: ResizeImage(
                  AssetImage('assets/images/landscape.jpg'),
                  width: 512,
                  height: 512,
                ),
                fit: BoxFit.cover,
                filterQuality: FilterQuality.low,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSlider(BuildContext context) {
    return ClipRRect(
      child: PageView.builder(
        controller: pageController,
        itemCount: todayPhotos.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () async {
              final updatedMemo = await Navigator.push<String?>(
                context,
                MaterialPageRoute(
                  builder: (context) => MemoInputScreen(
                    initialMemo: todayPhotos[index].memo,
                    photoPath: todayPhotos[index].filePath,
                    isEditing: true,
                    onDelete: () async {
                      await onDeletePhoto(todayPhotos[index]);
                    },
                  ),
                ),
              );

              if (updatedMemo != null) {
                await onEditMemo(todayPhotos[index], updatedMemo);
              }
            },
            child: PhotoItem(
              photo: todayPhotos[index],
              textColor: textColor,
            ),
          );
        },
      ),
    );
  }
}

class PhotoItem extends StatelessWidget {
  final Photo photo;
  final Color textColor;

  const PhotoItem({
    required this.photo,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _buildImage(),
        _buildTimestampAndMemo(),
      ],
    );
  }

  Widget _buildImage() {
    return Positioned.fill(
      child: Image(
        image: ResizeImage(
          FileImage(File(photo.filePath)),
          width: 512,
          height: 512,
        ),
        gaplessPlayback: true,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.low,
        // frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        //   if (wasSynchronouslyLoaded) return child;
        //   return AnimatedOpacity(
        //     child: child,
        //     opacity: frame == null ? 0 : 1,
        //     duration: const Duration(seconds: 1),
        //     curve: Curves.easeOut,
        //   );
        // },
      ),
    );
  }

  Widget _buildTimestampAndMemo() {
    return Positioned(
      right: 10, // 왼쪽 대신 오른쪽에 위치
      bottom: 10,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end, // 오른쪽 정렬
        mainAxisSize: MainAxisSize.min,
        children: [
          // 타임스탬프
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              formatTimestamp(photo.timestamp),
              style: TextStyle(fontSize: 12, color: Colors.white),
            ),
          ),
          // 메모 (타임스탬프 아래에 위치)
          if (photo.memo != null && photo.memo!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  photo.memo ?? '',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String formatTimestamp(String timestamp) {
    final DateTime dateTime = DateTime.parse(timestamp);
    return DateFormat('yyyy/MM/dd HH:mm:ss').format(dateTime);
  }
}
