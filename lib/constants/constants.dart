// constants.dart
import 'dart:io';
import 'package:flutter/material.dart';

// UI 텍스트 상수
const String kFocusModeText = '지금은 나를 위한 시간이에요.';
const String kBreakModeText = '잠깐 쉬면서 하늘을 올려다볼까요.';
const String kNoPhotosMessage = '먼 곳의 풍경을 바라보며\n사진으로 기록해보세요.';
const String kBeforeStartText = '잠시 후 먼 곳을 바라보며 눈에 휴식을 선물하세요.';
const String kFocusTitle = '집중 시간';

// SharedPreferences 키
const String kFocusDurationMinutesKey = 'focusDuration_minutes';
const String kFocusDurationSecondsKey = 'focusDuration_seconds';
const String kBreakDurationMinutesKey = 'breakDuration_minutes';
const String kBreakDurationSecondsKey = 'breakDuration_seconds';

// 기본 타이머 값 (Duration)
const Duration kDefaultFocusDuration = Duration(minutes: 20);
const Duration kDefaultBreakDuration = Duration(minutes: 5);

// 이미지 리사이즈 상수
const int kImageResizeWidth = 512;
const int kImageResizeHeight = 512;

// 레이아웃 관련 상수
const double kPadding = 16.0;
const double kSizedBoxHeightSmall = 16.0;
const double kSizedBoxHeightMedium = 24.0;
const double kSizedBoxHeightLarge = 32.0;

// PageController 관련 상수
const double kViewportFraction = 1.0;

// 백색소음 관련 상수
const String kWhiteNoiseAssetKey = 'white_noise_asset';
const String kRainSound = '빗소리';
const String kOceanSound = '파도 소리';
const String kWindSound = '바람 소리';
const String kWhiteNoise = '백색소음';

const String kWhiteNoiseChannelId = 'white_noise_channel';
const String kWhiteNoiseChannelName = '백색소음 재생';
const String kWhiteNoiseChannelDescription = '백색소음 재생 서비스';
const String kAndroidNotificationIcon = 'mipmap/launcher_icon';
const Color kNotificationColor = Color(0xFF2196f3);
