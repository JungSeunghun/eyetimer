import 'dart:io';
import 'package:flutter/material.dart';

class MemoInputScreen extends StatefulWidget {
  final String? initialMemo;
  final String photoPath; // 사진 경로
  final bool isEditing;
  final VoidCallback? onDelete;

  const MemoInputScreen({
    Key? key,
    this.initialMemo,
    required this.photoPath,
    this.isEditing = false,
    this.onDelete,
  }) : super(key: key);

  @override
  _MemoInputScreenState createState() => _MemoInputScreenState();
}

class _MemoInputScreenState extends State<MemoInputScreen> {
  late TextEditingController _controller;
  String? memo;

  @override
  void initState() {
    super.initState();
    memo = widget.initialMemo;
    _controller = TextEditingController(text: widget.initialMemo);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _saveMemo() {
    Navigator.pop(context, memo);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyMedium?.color ?? Colors.black;
    final backgroundColor = theme.scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        title: Text(
          widget.isEditing ? '수정' : '저장',
          style: TextStyle(color: textColor),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 사진 영역
            Expanded(
              child: Container(
                width: double.infinity,
                child: Image(
                  image: ResizeImage(
                    FileImage(File(widget.photoPath)),
                    width: 500,
                  ),
                  fit: BoxFit.contain, // BoxFit.contain로 사진을 화면에 맞게 조정
                  filterQuality: FilterQuality.low,
                  frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                    if (wasSynchronouslyLoaded) return child;
                    return AnimatedOpacity(
                      opacity: frame == null ? 0 : 1,
                      duration: const Duration(seconds: 1),
                      curve: Curves.easeOut,
                      child: child,
                    );
                  },
                ),
              ),
            ),
            // 메모 입력 필드
            TextField(
              cursorColor: textColor,
              style: TextStyle(color: textColor),
              controller: _controller,
              onChanged: (value) => memo = value,
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
            const SizedBox(height: 16),
            // 버튼 영역 (메모 입력 필드 아래)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (widget.isEditing && widget.onDelete != null)
                  TextButton(
                    onPressed: () {
                      widget.onDelete!();
                      Navigator.pop(context);
                    },
                    child: Text('삭제', style: TextStyle(color: Colors.red)),
                  ),
                TextButton(
                  onPressed: _saveMemo,
                  child: Text(
                    widget.isEditing ? '수정' : '저장',
                    style: TextStyle(color: textColor),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
