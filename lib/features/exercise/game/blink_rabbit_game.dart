// lib/game/blink_rabbit_game.dart
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

class BlinkRabbitGame extends FlameGame {
  static const double kJumpForce = -3.5;
  static const double kGravity = 0.25;
  // 기본 상수들
  static const double kBarrierWidth = 0.2;
  static const double kBarrierSpeed = 0.02;
  static const double kBarrierAcceleration = 0.001;
  static const double kRabbitXCenter = 0.3;
  static const double kBarrierInitialX = 2.0;
  static const double kMaxRandomXOffset = 0.2;
  static const double kRabbitSize = 50;
  static const double kRabbitHitboxHalfSize = 25;
  static const double kRabbitRotationMultiplier = 0.03;
  static const double kRabbitVelocityMultiplier = 0.02;
  static const double kCeilingFloorHeight = 40;

  final math.Random _random = math.Random();

  late double screenW;
  late double screenH;

  bool isGameStarted = false;
  bool isGameOver = false;
  bool hasPassedPipe = false;

  double birdY = 0;
  double birdVelocity = 0;

  double barrierX = kBarrierInitialX;
  // 상단 파이프 높이: 0.2 ~ 0.6 (화면의 비율)
  late double barrierTopHeight;
  // 파이프 gap 크기: 0.25 ~ 0.35 (화면의 비율)
  late double barrierGapRandom;
  // 현재 파이프 속도 (게임 진행에 따라 증가)
  double currentBarrierSpeed = kBarrierSpeed;

  int score = 0;

  // 콜백
  VoidCallback? onScoreChanged;
  VoidCallback? onGameOver;

  // 이미지 변수 (dart:ui 의 Image 타입)
  late ui.Image backgroundImage;
  late ui.Image pipeImage;
  late ui.Image birdImage;
  late ui.Image tileImage; // 천장/바닥 타일 이미지

  BlinkRabbitGame();

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // 에셋 로드 (Flame의 images.load() 사용)
    backgroundImage = await images.load('blink_rabbit/background.png');
    pipeImage = await images.load('blink_rabbit/pipe.png');
    birdImage = await images.load('blink_rabbit/rabbit.png');
    tileImage = await images.load('blink_rabbit/tile.png');

    // 초기 파이프 간격 및 상단 파이프 높이 설정
    barrierTopHeight = 0.2 + _random.nextDouble() * 0.4; // 0.2 ~ 0.6
    barrierGapRandom = 0.25 + _random.nextDouble() * 0.1;  // 0.25 ~ 0.35
  }

  @override
  void onGameResize(Vector2 canvasSize) {
    super.onGameResize(canvasSize);
    screenW = canvasSize.x;
    screenH = canvasSize.y;
  }

  // 원-사각형 충돌 검사 헬퍼 함수
  bool circleRectCollision({
    required double cx,
    required double cy,
    required double r,
    required Rect rect,
  }) {
    // rect의 가장 가까운 점 찾기
    double closestX = cx.clamp(rect.left, rect.right);
    double closestY = cy.clamp(rect.top, rect.bottom);
    double dx = cx - closestX;
    double dy = cy - closestY;
    return (dx * dx + dy * dy) < (r * r);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (screenW <= 0 || screenH <= 0) return;
    if (!isGameStarted || isGameOver) return;

    // 중력 적용
    birdVelocity += kGravity;
    birdY += birdVelocity * kRabbitVelocityMultiplier;

    // 파이프 이동 (현재 속도를 사용)
    barrierX -= currentBarrierSpeed;
    // dt에 비례하여 파이프 속도를 증가시킴 (가속 효과)
    currentBarrierSpeed += kBarrierAcceleration * dt;

    // 점수 체크 (파이프를 지나쳤을 때)
    final pipeRight = barrierX * screenW + (screenW * kBarrierWidth);
    final birdRight = (screenW * kRabbitXCenter) + kRabbitSize;
    if (!hasPassedPipe && birdRight > pipeRight) {
      score++;
      hasPassedPipe = true;
      onScoreChanged?.call();
    }

    // 파이프 재생성 (화면 왼쪽으로 완전히 벗어나면)
    if (barrierX < -1.8) {
      barrierX = kBarrierInitialX + _random.nextDouble() * kMaxRandomXOffset;
      barrierTopHeight = 0.2 + _random.nextDouble() * 0.4; // 0.2 ~ 0.6
      barrierGapRandom = 0.25 + _random.nextDouble() * 0.1;  // 0.25 ~ 0.35
      hasPassedPipe = false;
    }

    // 토끼(원)의 중심 좌표 (충돌 검사를 위한 원)
    final double birdCenterX = screenW * kRabbitXCenter + kRabbitSize / 2;
    final double birdCenterY = screenH * 0.5 + birdY * 100 + kRabbitSize / 2;
    final double birdRadius = kRabbitHitboxHalfSize; // 반지름

    // 천장/바닥 충돌 체크 (원 기준으로는 단순히 y좌표 검사)
    if ((birdCenterY - birdRadius) < kCeilingFloorHeight ||
        (birdCenterY + birdRadius) > screenH - kCeilingFloorHeight) {
      endGame();
      return;
    }

    // 파이프 충돌 체크 (원-사각형 충돌)
    // 상단 파이프 사각형
    final Rect topPipeRect = Rect.fromLTWH(
      barrierX * screenW,
      0,
      screenW * kBarrierWidth,
      screenH * barrierTopHeight,
    );
    // 하단 파이프 사각형
    final Rect bottomPipeRect = Rect.fromLTWH(
      barrierX * screenW,
      screenH * barrierTopHeight + screenH * barrierGapRandom,
      screenW * kBarrierWidth,
      screenH * (1 - barrierTopHeight - barrierGapRandom),
    );
    // 상단 또는 하단 파이프와 충돌 시 게임 종료
    if (circleRectCollision(cx: birdCenterX, cy: birdCenterY, r: birdRadius, rect: topPipeRect) ||
        circleRectCollision(cx: birdCenterX, cy: birdCenterY, r: birdRadius, rect: bottomPipeRect)) {
      endGame();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (screenW == 0 || screenH == 0) return;

    // 배경 이미지 (화면 전체)
    final Rect bgRect = Rect.fromLTWH(0, 0, screenW, screenH);
    paintImage(canvas: canvas, rect: bgRect, image: backgroundImage, fit: BoxFit.fill);

    // 상단 파이프 렌더링
    final Rect topPipeRect = Rect.fromLTWH(
      barrierX * screenW,
      0,
      screenW * kBarrierWidth,
      screenH * barrierTopHeight,
    );
    paintImage(canvas: canvas, rect: topPipeRect, image: pipeImage, fit: BoxFit.fill);

    // 하단 파이프 렌더링
    final Rect bottomPipeRect = Rect.fromLTWH(
      barrierX * screenW,
      screenH * barrierTopHeight + screenH * barrierGapRandom,
      screenW * kBarrierWidth,
      screenH * (1 - barrierTopHeight - barrierGapRandom),
    );
    paintImage(canvas: canvas, rect: bottomPipeRect, image: pipeImage, fit: BoxFit.fill);

    // 타일 스케일 계산 (타일 높이를 kCeilingFloorHeight에 맞춤)
    final double tileScale = kCeilingFloorHeight / tileImage.height.toDouble();
    final Matrix4 tileTransform = Matrix4.diagonal3Values(tileScale, tileScale, 1);

    // 천장 타일 패턴 (ImageShader 사용)
    final Rect ceilingRect = Rect.fromLTWH(0, 0, screenW, kCeilingFloorHeight);
    final Paint ceilingPaint = Paint()
      ..shader = ui.ImageShader(tileImage, TileMode.repeated, TileMode.repeated, tileTransform.storage);
    canvas.drawRect(ceilingRect, ceilingPaint);

    // 바닥 타일 패턴 (y축 뒤집기 적용)
    final Matrix4 floorTransform = Matrix4.identity()
      ..translate(0.0, kCeilingFloorHeight)
      ..scale(tileScale, -tileScale);
    final Rect floorRect = Rect.fromLTWH(0, screenH - kCeilingFloorHeight, screenW, kCeilingFloorHeight);
    final Paint floorPaint = Paint()
      ..shader = ui.ImageShader(tileImage, TileMode.repeated, TileMode.repeated, floorTransform.storage);
    canvas.drawRect(floorRect, floorPaint);

    // 캐릭터(토끼) 렌더링
    final double birdRenderY = screenH * 0.5 + birdY * 100;
    final Rect birdRect = Rect.fromLTWH(screenW * kRabbitXCenter, birdRenderY, kRabbitSize, kRabbitSize);
    final double angle = birdVelocity * kRabbitRotationMultiplier;
    canvas.save();
    canvas.translate(birdRect.center.dx, birdRect.center.dy);
    canvas.rotate(angle);
    canvas.translate(-birdRect.center.dx, -birdRect.center.dy);
    paintImage(canvas: canvas, rect: birdRect, image: birdImage, fit: BoxFit.fill);
    canvas.restore();
  }

  void startGame() {
    isGameStarted = true;
    isGameOver = false;
    score = 0;
    birdY = 0;
    birdVelocity = 0;
    barrierX = kBarrierInitialX + _random.nextDouble() * kMaxRandomXOffset;
    barrierTopHeight = 0.2 + _random.nextDouble() * 0.4; // 0.2 ~ 0.6
    barrierGapRandom = 0.25 + _random.nextDouble() * 0.1;  // 0.25 ~ 0.35
    currentBarrierSpeed = kBarrierSpeed;
    hasPassedPipe = false;
  }

  void endGame() {
    isGameOver = true;
    isGameStarted = false;
    onGameOver?.call();
  }

  void onBlink() {
    if (!isGameStarted || isGameOver) return;
    birdVelocity = kJumpForce;
  }
}
