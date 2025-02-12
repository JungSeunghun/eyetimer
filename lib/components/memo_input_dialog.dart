import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class MemoInputScreen extends StatefulWidget {
  final String? initialMemo;
  final String photoPath; // 사진 경로
  final bool isEditing;
  final Future<void> Function()? onDelete; // Future<void>로 변경

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

  Future<void> _confirmDelete() async {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyMedium?.color ?? Colors.black;
    final backgroundColor = theme.scaffoldBackgroundColor;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: backgroundColor,
          title: Text(
            'delete_confirm_title'.tr(),
            style: TextStyle(color: textColor),
          ),
          content: Text(
            'delete_confirm_content'.tr(),
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
        );
      },
    );

    if (confirm == true) {
      if (widget.onDelete != null) {
        await widget.onDelete!(); // 삭제 작업을 await
      }
      Navigator.pop(context, "deleted"); // 삭제 완료 결과 전달
    }
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
          widget.isEditing ? 'edit'.tr() : 'save'.tr(),
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
                  fit: BoxFit.contain,
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
                hintText: 'enter_memo_hint'.tr(),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: textColor),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: textColor),
                ),
                hintStyle: TextStyle(color: textColor.withValues(alpha: 0.7)),
              ),
            ),
            const SizedBox(height: 16),
            // 버튼 영역 (메모 입력 필드 아래)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (widget.isEditing && widget.onDelete != null)
                  TextButton(
                    onPressed: _confirmDelete,
                    child: Text('delete'.tr(),
                        style: const TextStyle(color: Colors.red)),
                  ),
                TextButton(
                  onPressed: _saveMemo,
                  child: Text(
                    widget.isEditing ? 'edit'.tr() : 'save'.tr(),
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
