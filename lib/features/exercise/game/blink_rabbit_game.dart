// lib/game/blink_rabbit_game.dart
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';

class Pipe {
  double x;
  double topHeight;
  double gap;
  bool hasPassed;

  Pipe({
    required this.x,
    required this.topHeight,
    required this.gap,
    this.hasPassed = false,
  });
}

class BlinkRabbitGame extends FlameGame with TapDetector {
  static const double kJumpForce = -3.5;
  static const double kGravity = 0.25;
  // 기본 상수들
  static const double kBarrierWidth = 0.2;
  static const double kBarrierSpeed = 0.01;
  static const double kBarrierAcceleration = 0.001;
  static const double kRabbitXCenter = 0.3;
  static const double kBarrierInitialX = 2.0;
  static const double kMaxRandomXOffset = 0.2;
  static const double kRabbitSize = 50;
  static const double kRabbitHitboxHalfSize = 25;
  static const double kRabbitRotationMultiplier = 0.03;
  static const double kRabbitVelocityMultiplier = 0.02;
  static const double kCeilingFloorHeight = 40;
  // 파이프 간 간격 (파이프 재생성 시 기준): 간격을 좁게 하기 위해 1.8 -> 1.0으로 변경
  static const double kPipeSpacing = 1.0;

  final math.Random _random = math.Random();

  late double screenW;
  late double screenH;

  bool isGameStarted = false;
  bool isGameOver = false;

  double birdY = 0;
  double birdVelocity = 0;
  // 모든 파이프에 공통으로 적용되는 속도 (게임 진행에 따라 증가)
  double currentBarrierSpeed = kBarrierSpeed;

  int score = 0;
  // 1초마다 점수를 올리기 위한 타이머 변수
  double scoreTimer = 0.0;

  // 콜백
  VoidCallback? onScoreChanged;
  VoidCallback? onGameOver;

  // 이미지 변수 (dart:ui 의 Image 타입)
  late ui.Image backgroundImage;
  late ui.Image pipeImage;
  late ui.Image birdImage;
  late ui.Image tileImage; // 천장/바닥 타일 이미지

  // 파이프 리스트: 초기화 시 빈 리스트로 설정
  List<Pipe> pipes = [];
  // 게임 시작 시 파이프 개수를 5개로 결정
  int pipeCount = 5;

  BlinkRabbitGame();

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    backgroundImage = await images.load('blink_rabbit/background.png');
    pipeImage = await images.load('blink_rabbit/pipe.png');
    birdImage = await images.load('blink_rabbit/rabbit.png');
    tileImage = await images.load('blink_rabbit/tile.png');
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

    // 1초마다 점수 증가 (누적된 시간 활용)
    scoreTimer += dt;
    if (scoreTimer >= 1.0) {
      score++;
      scoreTimer -= 1.0;
      onScoreChanged?.call();
    }

    // 중력 적용
    birdVelocity += kGravity;
    birdY += birdVelocity * kRabbitVelocityMultiplier;

    // 각 파이프 업데이트
    for (var pipe in pipes) {
      pipe.x -= currentBarrierSpeed;

      // 파이프 재생성: 화면 왼쪽 끝(-1.8)보다 많이 벗어나면 오른쪽에서 재생성
      if (pipe.x < -1.8) {
        // 최소값으로 kBarrierInitialX를 보장
        final double maxX =
        pipes.fold<double>(kBarrierInitialX, (prev, p) => math.max(prev, p.x));
        pipe.x = maxX + kPipeSpacing + _random.nextDouble() * kMaxRandomXOffset;
        pipe.topHeight = 0.2 + _random.nextDouble() * 0.4; // 0.2 ~ 0.6
        pipe.gap = 0.25 + _random.nextDouble() * 0.1;       // 0.25 ~ 0.35
        pipe.hasPassed = false;
      }
    }
    // 파이프 속도 가속
    currentBarrierSpeed += kBarrierAcceleration * dt;

    // 토끼(원)의 중심 좌표 (충돌 검사를 위한 원)
    final double birdCenterX = screenW * kRabbitXCenter + kRabbitSize / 2;
    final double birdCenterY = screenH * 0.5 + birdY * 100 + kRabbitSize / 2;
    final double birdRadius = kRabbitHitboxHalfSize;

    // 천장/바닥 충돌 체크
    if ((birdCenterY - birdRadius) < kCeilingFloorHeight ||
        (birdCenterY + birdRadius) > screenH - kCeilingFloorHeight) {
      endGame();
      return;
    }

    // 각 파이프에 대해 충돌 체크
    for (var pipe in pipes) {
      final Rect topPipeRect = Rect.fromLTWH(
        pipe.x * screenW,
        0,
        screenW * kBarrierWidth,
        screenH * pipe.topHeight,
      );
      final Rect bottomPipeRect = Rect.fromLTWH(
        pipe.x * screenW,
        screenH * pipe.topHeight + screenH * pipe.gap,
        screenW * kBarrierWidth,
        screenH * (1 - pipe.topHeight - pipe.gap),
      );
      if (circleRectCollision(cx: birdCenterX, cy: birdCenterY, r: birdRadius, rect: topPipeRect) ||
          circleRectCollision(cx: birdCenterX, cy: birdCenterY, r: birdRadius, rect: bottomPipeRect)) {
        endGame();
        return;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (screenW == 0 || screenH == 0) return;

    // 배경 렌더링
    final Rect bgRect = Rect.fromLTWH(0, 0, screenW, screenH);
    paintImage(canvas: canvas, rect: bgRect, image: backgroundImage, fit: BoxFit.fill);

    // 각 파이프 렌더링
    for (var pipe in pipes) {
      final Rect topPipeRect = Rect.fromLTWH(
        pipe.x * screenW,
        0,
        screenW * kBarrierWidth,
        screenH * pipe.topHeight,
      );
      paintImage(canvas: canvas, rect: topPipeRect, image: pipeImage, fit: BoxFit.fill);

      final Rect bottomPipeRect = Rect.fromLTWH(
        pipe.x * screenW,
        screenH * pipe.topHeight + screenH * pipe.gap,
        screenW * kBarrierWidth,
        screenH * (1 - pipe.topHeight - pipe.gap),
      );
      paintImage(canvas: canvas, rect: bottomPipeRect, image: pipeImage, fit: BoxFit.fill);
    }

    // 천장 타일 패턴 렌더링
    final double tileScale = kCeilingFloorHeight / tileImage.height.toDouble();
    final Matrix4 tileTransform = Matrix4.diagonal3Values(tileScale, tileScale, 1);
    final Rect ceilingRect = Rect.fromLTWH(0, 0, screenW, kCeilingFloorHeight);
    final Paint ceilingPaint = Paint()
      ..shader =
      ui.ImageShader(tileImage, TileMode.repeated, TileMode.repeated, tileTransform.storage);
    canvas.drawRect(ceilingRect, ceilingPaint);

    // 바닥 타일 패턴 렌더링 (y축 뒤집기 적용)
    final Matrix4 floorTransform = Matrix4.identity()
      ..translate(0.0, kCeilingFloorHeight)
      ..scale(tileScale, -tileScale);
    final Rect floorRect = Rect.fromLTWH(0, screenH - kCeilingFloorHeight, screenW, kCeilingFloorHeight);
    final Paint floorPaint = Paint()
      ..shader =
      ui.ImageShader(tileImage, TileMode.repeated, TileMode.repeated, floorTransform.storage);
    canvas.drawRect(floorRect, floorPaint);

    // 토끼 렌더링
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

  // 게임 시작 시 호출하는 메서드 (startGame)
  void startGame() {
    isGameStarted = true;
    isGameOver = false;
    score = 0;
    scoreTimer = 0.0;
    birdY = 0;
    birdVelocity = 0;
    currentBarrierSpeed = kBarrierSpeed;

    // 파이프를 5개 생성
    pipeCount = 5;
    pipes = [];
    for (int i = 0; i < pipeCount; i++) {
      double initX =
          kBarrierInitialX + i * (kPipeSpacing + _random.nextDouble() * kMaxRandomXOffset);
      double topHeight = 0.2 + _random.nextDouble() * 0.4; // 0.2 ~ 0.6
      double gap = 0.25 + _random.nextDouble() * 0.1;        // 0.25 ~ 0.35
      pipes.add(Pipe(x: initX, topHeight: topHeight, gap: gap));
    }
  }

  void endGame() {
    isGameOver = true;
    isGameStarted = false;
    onGameOver?.call();
  }

  // Blink 또는 터치 시 호출되는 메서드 (점프)
  void onBlink() {
    if (!isGameStarted || isGameOver) return;
    birdVelocity = kJumpForce;
  }

  @override
  void onTapDown(TapDownInfo info) {
    // 터치 이벤트 발생 시 onBlink 호출
    onBlink();
  }
}
