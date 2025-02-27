import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';

import '../components/photo_slider.dart';
import '../components/status_text.dart';
import '../components/timer_display.dart';
import '../components/control_buttons.dart';
import '../components/duration_picker_dialog.dart';
import '../../../providers/photo_provider.dart';
import '../../../providers/timer_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _takePhoto(BuildContext context) async {
    await Provider.of<PhotoProvider>(context, listen: false).takePhoto(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyMedium?.color ?? Colors.black;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // PhotoSlider와 TimerDisplay를 Stack으로 겹쳐 배치
            Stack(
              children: [
                Consumer<PhotoProvider>(
                  builder: (context, photoProvider, child) {
                    return PhotoSlider(
                      pageController: _pageController,
                      todayPhotos: photoProvider.todayPhotos,
                      textColor: textColor,
                      onEditMemo: (photo, updatedMemo) async {
                        await photoProvider.updatePhotoMemo(photo.id!, updatedMemo);
                        await photoProvider.loadTodayPhotosWithCache(context);
                      },
                      onDeletePhoto: (photo) async {
                        await photoProvider.deletePhoto(photo.id!);
                        await photoProvider.loadTodayPhotosWithCache(context);
                      },
                    );
                  },
                ),
                Consumer<TimerProvider>(
                  builder: (context, timerProvider, child) {
                    return Positioned.fill(
                      child: Center(
                        child: TimerDisplay(
                          currentDuration: timerProvider.currentDuration,
                          focusDuration: timerProvider.focusDuration,
                          breakDuration: timerProvider.breakDuration,
                          isFocusMode: timerProvider.isFocusMode,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 32.0),
            Consumer<TimerProvider>(
              builder: (context, timerProvider, child) {
                return StatusText(
                  isRunning: timerProvider.isTimerRunning,
                  isFocusMode: timerProvider.isFocusMode,
                  focusModeText: 'focus_mode_text'.tr(),
                  breakModeText: 'break_mode_text'.tr(),
                  beforeStartText: 'before_start_text'.tr(),
                  textColor: textColor,
                );
              },
            ),
            const SizedBox(height: 32.0),
            Consumer<TimerProvider>(
              builder: (context, timerProvider, child) {
                return ControlButtons(
                  isRunning: timerProvider.isTimerRunning,
                  isPaused: timerProvider.isPaused,
                  onPlay: () {
                    if (timerProvider.isTimerRunning && timerProvider.isPaused) {
                      timerProvider.resumeTimer();
                    } else {
                      timerProvider.startTimer();
                    }
                  },
                  onPause: timerProvider.pauseTimer,
                  onStop: timerProvider.stopTimer,
                  onTakePhoto: () => _takePhoto(context),
                );
              },
            ),
            const SizedBox(height: 24.0),
            TextButton(
              child: Text(
                "timer_setting".tr(),
                style: TextStyle(color: textColor.withOpacity(0.7)),
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => DurationPickerDialog(
                    focusDuration: Provider.of<TimerProvider>(context, listen: false).focusDuration,
                    breakDuration: Provider.of<TimerProvider>(context, listen: false).breakDuration,
                    onSave: (newFocusDuration, newBreakDuration) async {
                      final timerProvider = Provider.of<TimerProvider>(context, listen: false);
                      timerProvider.focusDuration = newFocusDuration;
                      timerProvider.breakDuration = newBreakDuration;
                      timerProvider.currentDuration = newFocusDuration;
                      timerProvider.isFocusMode = true;
                      timerProvider.stopTimer();
                      await timerProvider.saveDurations();
                      timerProvider.notifyListeners();
                    },
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

