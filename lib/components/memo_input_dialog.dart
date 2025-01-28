import 'dart:io';
import 'package:flutter/material.dart';

Future<String?> showMemoInputDialog(
    BuildContext context, {
      String? initialMemo,
      required String photoPath, // 사진 경로 추가
      bool isEditing = false,
      VoidCallback? onDelete,
    }) {
  final theme = Theme.of(context);
  final textColor = theme.textTheme.bodyMedium?.color ?? Colors.black;
  final backgroundColor = theme.scaffoldBackgroundColor;

  String? memo = initialMemo;

  return showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: backgroundColor,
        title: Text(
          isEditing ? '메모 수정' : '메모',
          style: TextStyle(color: textColor),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 16.0),
              height: 200,
              child: Image(
                image: ResizeImage(
                  FileImage(File(photoPath)),
                  height: 200
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
            ),
            // 메모 입력 필드
            TextField(
              cursorColor: textColor,
              style: TextStyle(color: textColor),
              onChanged: (value) => memo = value,
              controller: TextEditingController(text: initialMemo),
              decoration: InputDecoration(
                hintText: '메모를 입력하세요.',
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: textColor),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: textColor),
                ),
                hintStyle: TextStyle(color: textColor.withOpacity(0.7)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('취소', style: TextStyle(color: textColor)),
          ),
          if (isEditing && onDelete != null)
            TextButton(
              onPressed: () {
                onDelete();
                Navigator.pop(context);
              },
              child: Text('삭제', style: TextStyle(color: Colors.red)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context, memo),
            child: Text(isEditing ? '수정' : '저장', style: TextStyle(color: textColor)),
          ),
        ],
      );
    },
  );
}
