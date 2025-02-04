import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/photo.dart';
import '../../../components/memo_input_dialog.dart';

class PhotoSlider extends StatelessWidget {
  final List<Photo> todayPhotos;
  final PageController pageController;
  final String noPhotosMessage;
  final Color textColor;
  final Function(Photo, String) onEditMemo; // 수정 시 호출
  final Function(Photo) onDeletePhoto; // 삭제 시 호출

  const PhotoSlider({
    required this.todayPhotos,
    required this.pageController,
    required this.noPhotosMessage,
    required this.textColor,
    required this.onEditMemo,
    required this.onDeletePhoto,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      height: MediaQuery.of(context).size.width * 0.9,
      child: todayPhotos.isEmpty
          ? _buildEmptyState()
          : _buildPhotoSlider(context),
    );
  }

  Widget _buildEmptyState() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8.0),
      child: Stack(
        children: [
          // 흐릿한 랜드스케이프 배경 이미지 (애니메이션 적용)
          Positioned.fill(
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(seconds: 1),
              builder: (context, opacity, child) {
                return Opacity(
                  opacity: opacity,
                  child: child,
                );
              },
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
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
          ),
          // 전체에 반투명 박스 씌우기
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.4),
            ),
          ),
          // 메시지 표시
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                noPhotosMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.normal,
                  height: 1.8,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSlider(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8.0),
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
        if (photo.memo != null) _buildMemoOverlay(),
        _buildTimestamp(),
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
  }

  Widget _buildMemoOverlay() {
    if (photo.memo != null && photo.memo!.isNotEmpty) {
      return Center(
        child: Container(
          color: Colors.black.withValues(alpha: 0.5),
          padding: const EdgeInsets.all(8.0),
          child: Text(
            photo.memo ?? '',
            style: const TextStyle(color: Colors.white, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return const SizedBox.shrink(); // 빈 위젯 반환
  }

  Widget _buildTimestamp() {
    return Positioned(
      left: 10,
      bottom: 10,
      child: Container(
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
    );
  }

  String formatTimestamp(String timestamp) {
    final DateTime dateTime = DateTime.parse(timestamp);
    return DateFormat('yyyy/MM/dd HH:mm:ss').format(dateTime);
  }
}
