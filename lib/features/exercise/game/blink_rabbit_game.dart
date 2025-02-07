// lib/game/blink_rabbit_game.dart
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';

/// CeilingComponent는 천장을 타일 패턴으로 그리며, 충돌 감지를 위해 Hitbox를 추가합니다.
class CeilingComponent extends PositionComponent with HasGameRef<BlinkRabbitGame>, CollisionCallbacks {
  final ui.Image tileImage;
  CeilingComponent({
    required this.tileImage,
    required Vector2 size,
  }) : super(size: size, position: Vector2.zero(), anchor: Anchor.topLeft);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox());
  }

  @override
  void render(Canvas canvas) {
    final double tileScale = size.y / tileImage.height;
    final Matrix4 tileTransform = Matrix4.diagonal3Values(tileScale, tileScale, 1);
    final Paint paint = Paint()
      ..shader = ui.ImageShader(tileImage, TileMode.repeated, TileMode.repeated, tileTransform.storage);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), paint);
  }
}

/// FloorComponent는 바닥을 타일 패턴으로 그리며, 충돌 감지를 위해 Hitbox를 추가합니다.
class FloorComponent extends PositionComponent with HasGameRef<BlinkRabbitGame>, CollisionCallbacks {
  final ui.Image tileImage;
  FloorComponent({
    required this.tileImage,
    required Vector2 size,
    required Vector2 position,
  }) : super(size: size, position: position, anchor: Anchor.topLeft);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox());
  }

  @override
  void render(Canvas canvas) {
    final double tileScale = size.y / tileImage.height;
    final Matrix4 tileTransform = Matrix4.diagonal3Values(tileScale, tileScale, 1);
    final Paint paint = Paint()
      ..shader = ui.ImageShader(tileImage, TileMode.repeated, TileMode.repeated, tileTransform.storage);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), paint);
  }
}

/// RabbitComponent는 토끼 캐릭터를 나타내며, 충돌 감지를 위해 Hitbox를 추가하고,
// 충돌 발생 시 gameRef.endGame()을 호출합니다.
class RabbitComponent extends SpriteComponent with CollisionCallbacks, HasGameRef<BlinkRabbitGame> {
  double velocity = 0.0;

  RabbitComponent({
    required Sprite sprite,
    required Vector2 position,
    required Vector2 size,
  }) : super(sprite: sprite, position: position, size: size, anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    if (!gameRef.isGameStarted) return;
    super.update(dt);
    velocity += BlinkRabbitGame.kGravity;
    position.y += velocity * BlinkRabbitGame.kRabbitVelocityMultiplier * 100;
    angle = velocity * BlinkRabbitGame.kRabbitRotationMultiplier;
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is PipeComponent || other is CeilingComponent || other is FloorComponent) {
      gameRef.endGame();
    }
  }

  void jump() {
    velocity = BlinkRabbitGame.kJumpForce;
  }
}

/// PipeComponent는 파이프 쌍을 그리며, 상단과 하단 영역에 각각 Hitbox를 추가합니다.
class PipeComponent extends PositionComponent with CollisionCallbacks, HasGameRef<BlinkRabbitGame> {
  double relativeX; // 실제 x 좌표: (relativeX - 1.0) * screenWidth
  double topHeight; // 상단 파이프 높이 (비율)
  double gap;       // 파이프 사이의 간격 (비율)
  Sprite sprite;

  late RectangleHitbox topHitbox;
  late RectangleHitbox bottomHitbox;

  PipeComponent({
    required this.relativeX,
    required this.topHeight,
    required this.gap,
    required this.sprite,
    required Vector2 size,
  }) : super(size: size, position: Vector2.zero(), anchor: Anchor.topLeft);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // 상단, 하단 영역에 대해 각각 히트박스를 추가합니다.
    topHitbox = RectangleHitbox();
    bottomHitbox = RectangleHitbox();
    add(topHitbox);
    add(bottomHitbox);
  }

  @override
  void update(double dt) {
    super.update(dt);
    relativeX -= gameRef.currentBarrierSpeed * dt;
    position.x = (relativeX - 1.0) * gameRef.size.x;
    if (relativeX < 1.0 - BlinkRabbitGame.kBarrierWidth) {
      gameRef.repositionPipe(this);
    }

    // 매 프레임마다 파이프의 hitbox 크기와 위치를 업데이트합니다.
    final double pipeWidth = gameRef.size.x * BlinkRabbitGame.kBarrierWidth;
    final double topPipeHeight = gameRef.size.y * topHeight;
    final double bottomY = gameRef.size.y * topHeight + gameRef.size.y * gap;
    final double bottomPipeHeight = gameRef.size.y - bottomY;

    topHitbox
      ..size = Vector2(pipeWidth, topPipeHeight)
      ..position = Vector2.zero();
    bottomHitbox
      ..size = Vector2(pipeWidth, bottomPipeHeight)
      ..position = Vector2(0, bottomY);
  }

  @override
  void render(Canvas canvas) {
    final double pipeWidth = gameRef.size.x * BlinkRabbitGame.kBarrierWidth;
    final double topPipeHeight = gameRef.size.y * topHeight;
    final Rect topRect = Rect.fromLTWH(0, 0, pipeWidth, topPipeHeight);
    sprite.renderRect(canvas, topRect);
    final double bottomY = gameRef.size.y * topHeight + gameRef.size.y * gap;
    final double bottomHeight = gameRef.size.y - bottomY;
    final Rect bottomRect = Rect.fromLTWH(0, bottomY, pipeWidth, bottomHeight);
    sprite.renderRect(canvas, bottomRect);
  }
}

/// BlinkRabbitGame은 전체 게임을 관리하며, HasCollisionDetection을 믹스인하여
/// Flame의 충돌 시스템을 활성화합니다.
class BlinkRabbitGame extends FlameGame with TapDetector, HasCollisionDetection {
  // 상수들 (픽셀 및 상대 좌표)
  static const double kJumpForce = -3.5;
  static const double kGravity = 0.25;
  static const double kBarrierWidth = 0.2;
  static const double kBarrierSpeed = 0.2;
  static const double kBarrierAcceleration = 0.001;
  static const double kRabbitXCenter = 0.3;
  static const double kBarrierInitialX = 2.0;
  static const double kMaxRandomXOffset = 0.2;
  static const double kRabbitSize = 50;
  static const double kRabbitHitboxHalfSize = 25; // 사용하지 않음.
  static const double kRabbitRotationMultiplier = 0.03;
  static const double kRabbitVelocityMultiplier = 0.02;
  static const double kCeilingFloorHeight = 40;
  static const double kPipeSpacing = 1.0;

  // 게임 상태 필드
  bool isGameStarted = false;
  bool isGameOver = false;
  double currentBarrierSpeed = kBarrierSpeed;
  double score = 0;
  double scoreTimer = 0.0;
  double _nextPipeX = kBarrierInitialX;

  late Sprite backgroundSprite;
  late Sprite pipeSprite;
  late Sprite rabbitSprite;
  late ui.Image tileImage;
  late RabbitComponent rabbit;

  final math.Random _random = math.Random();

  // 오브젝트 풀: 파이프들을 재사용하기 위한 리스트
  final List<PipeComponent> _pipePool = [];

  // 외부(UI)에서 설정할 수 있는 콜백들
  VoidCallback? onScoreChanged;
  VoidCallback? onGameOver;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    backgroundSprite = Sprite(await images.load('blink_rabbit/background.png'));
    pipeSprite = Sprite(await images.load('blink_rabbit/pipe.png'));
    rabbitSprite = Sprite(await images.load('blink_rabbit/rabbit.png'));
    tileImage = await images.load('blink_rabbit/tile.png');

    // 정적 환경 컴포넌트 추가
    add(SpriteComponent(
      sprite: backgroundSprite,
      position: Vector2.zero(),
      size: size,
      priority: 0,
    ));
    add(CeilingComponent(
      tileImage: tileImage,
      size: Vector2(size.x, kCeilingFloorHeight),
    )..priority = 2);
    add(FloorComponent(
      tileImage: tileImage,
      size: Vector2(size.x, kCeilingFloorHeight),
      position: Vector2(0, size.y - kCeilingFloorHeight),
    )..priority = 2);
    // 토끼 컴포넌트 추가 (게임 시작 전에도 표시)
    rabbit = RabbitComponent(
      sprite: rabbitSprite,
      position: Vector2(size.x * kRabbitXCenter, size.y * 0.5),
      size: Vector2(kRabbitSize, kRabbitSize),
    )..priority = 3;
    add(rabbit);
  }

  @override
  void onGameResize(Vector2 canvasSize) {
    super.onGameResize(canvasSize);
  }

  /// 게임 시작 시, 파이프 오브젝트 풀을 이용해 파이프를 생성하거나 재설정합니다.
  void startGame() {
    isGameStarted = true;
    isGameOver = false;
    currentBarrierSpeed = kBarrierSpeed;
    score = 0;
    scoreTimer = 0.0;
    _nextPipeX = kBarrierInitialX;

    if (_pipePool.isEmpty) {
      int pipeCount = 5;
      for (int i = 0; i < pipeCount; i++) {
        double relX = _nextPipeX;
        _nextPipeX = relX + kPipeSpacing + (_random.nextDouble() * kMaxRandomXOffset);
        double topH = 0.2 + _random.nextDouble() * 0.4;
        double gap = 0.25 + _random.nextDouble() * 0.1;
        Vector2 pipeSize = Vector2(size.x * kBarrierWidth, size.y);
        var pipe = PipeComponent(
          relativeX: relX,
          topHeight: topH,
          gap: gap,
          sprite: pipeSprite,
          size: pipeSize,
        )..priority = 1;
        _pipePool.add(pipe);
        add(pipe);
      }
    } else {
      for (var pipe in _pipePool) {
        double relX = _nextPipeX;
        _nextPipeX = relX + kPipeSpacing + (_random.nextDouble() * kMaxRandomXOffset);
        pipe.relativeX = relX;
        pipe.topHeight = 0.2 + _random.nextDouble() * 0.4;
        pipe.gap = 0.25 + _random.nextDouble() * 0.1;
      }
    }

    rabbit.position = Vector2(size.x * kRabbitXCenter, size.y * 0.5);
    rabbit.velocity = 0.0;
    rabbit.angle = 0.0;
  }

  /// 파이프가 화면 왼쪽으로 벗어나면 재설정합니다.
  void repositionPipe(PipeComponent pipe) {
    pipe.relativeX = _nextPipeX;
    _nextPipeX = pipe.relativeX + kPipeSpacing + (_random.nextDouble() * kMaxRandomXOffset);
    pipe.topHeight = 0.2 + _random.nextDouble() * 0.4;
    pipe.gap = 0.25 + _random.nextDouble() * 0.1;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!isGameStarted || isGameOver) return;

    scoreTimer += dt;
    if (scoreTimer >= 1.0) {
      score++;
      scoreTimer -= 1.0;
      onScoreChanged?.call();
    }

    currentBarrierSpeed += kBarrierAcceleration * dt;
  }

  @override
  void onTapDown(TapDownInfo info) {
    onBlink();
  }

  /// 토끼의 점프를 유도합니다.
  void onBlink() {
    if (!isGameStarted || isGameOver) return;
    rabbit.jump();
  }

  void endGame() {
    isGameOver = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      onGameOver?.call();
    });
  }
}
