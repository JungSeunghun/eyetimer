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
  late final double _tileScale;
  late final Matrix4 _tileTransform;
  late final Paint _paint;

  CeilingComponent({
    required this.tileImage,
    required Vector2 size,
  }) : super(size: size, position: Vector2.zero(), anchor: Anchor.topLeft);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox());
    // onLoad에서 타일 스케일, Matrix4, 그리고 Paint(이미지 shader 포함)를 한 번 계산하여 캐싱합니다.
    _tileScale = size.y / tileImage.height;
    _tileTransform = Matrix4.diagonal3Values(_tileScale, _tileScale, 1);
    _paint = Paint()
      ..shader = ui.ImageShader(tileImage, TileMode.repeated, TileMode.repeated, _tileTransform.storage);
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), _paint);
  }
}

/// FloorComponent는 바닥을 타일 패턴으로 그리며, 충돌 감지를 위해 Hitbox를 추가합니다.
class FloorComponent extends PositionComponent with HasGameRef<BlinkRabbitGame>, CollisionCallbacks {
  final ui.Image tileImage;
  late final double _tileScale;
  late final Matrix4 _tileTransform;
  late final Paint _paint;

  FloorComponent({
    required this.tileImage,
    required Vector2 size,
    required Vector2 position,
  }) : super(size: size, position: position, anchor: Anchor.topLeft);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox());
    // onLoad에서 캐싱
    _tileScale = size.y / tileImage.height;
    _tileTransform = Matrix4.diagonal3Values(_tileScale, _tileScale, 1);
    _paint = Paint()
      ..shader = ui.ImageShader(tileImage, TileMode.repeated, TileMode.repeated, _tileTransform.storage);
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), _paint);
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
    // 토끼의 물리 계산: 매 프레임마다 중력, 위치, 회전을 업데이트합니다.
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
    // 상단, 하단 영역에 대해 각각 Hitbox를 추가합니다.
    topHitbox = RectangleHitbox();
    bottomHitbox = RectangleHitbox();
    add(topHitbox);
    add(bottomHitbox);
  }

  @override
  void update(double dt) {
    super.update(dt);
    // 화면 크기를 지역 변수에 저장하여 반복 연산 줄임
    final double screenWidth = gameRef.size.x;
    final double screenHeight = gameRef.size.y;
    relativeX -= gameRef.currentBarrierSpeed * dt;
    position.x = (relativeX - 1.0) * screenWidth;
    if (relativeX < 1.0 - BlinkRabbitGame.kBarrierWidth) {
      gameRef.repositionPipe(this);
    }
    // 파이프 관련 계산을 지역 변수로 미리 계산
    final double pipeWidth = screenWidth * BlinkRabbitGame.kBarrierWidth;
    final double topPipeHeight = screenHeight * topHeight;
    final double bottomY = screenHeight * topHeight + screenHeight * gap;
    final double bottomPipeHeight = screenHeight - bottomY;

    topHitbox
      ..size = Vector2(pipeWidth, topPipeHeight)
      ..position = Vector2.zero();
    bottomHitbox
      ..size = Vector2(pipeWidth, bottomPipeHeight)
      ..position = Vector2(0, bottomY);
  }

  @override
  void render(Canvas canvas) {
    // 렌더링 최적화: 파이프가 화면 밖(오른쪽 또는 왼쪽)에 있으면 렌더링 건너뜁니다.
    final double screenWidth = gameRef.size.x;
    if (position.x + size.x < 0 || position.x > screenWidth) {
      return;
    }

    final double screenHeight = gameRef.size.y;
    final double pipeWidth = screenWidth * BlinkRabbitGame.kBarrierWidth;
    final double topPipeHeight = screenHeight * topHeight;
    final Rect topRect = Rect.fromLTWH(0, 0, pipeWidth, topPipeHeight);
    sprite.renderRect(canvas, topRect);
    final double bottomY = screenHeight * topHeight + screenHeight * gap;
    final double bottomHeight = screenHeight - bottomY;
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
  // 가속도를 높여 파이프 속도가 점점 빨라지도록 (예: 0.01)
  static const double kBarrierAcceleration = 0.01;
  static const double kRabbitXCenter = 0.3;
  static const double kBarrierInitialX = 2.0;
  static const double kMaxRandomXOffset = 0.2;
  static const double kRabbitSize = 50;
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

  // 오브젝트 풀: 파이프 재사용을 위한 리스트
  final List<PipeComponent> _pipePool = [];

  // 외부(UI)에서 설정 가능한 콜백들
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

  /// 게임 시작 시, 파이프 오브젝트 풀을 이용해 파이프를 생성 또는 재설정합니다.
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
        _nextPipeX = relX + kPipeSpacing; // 무작위 오프셋 제거
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
        _nextPipeX = relX + kPipeSpacing; // 무작위 오프셋 제거
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
    // _pipePool 내 가장 오른쪽 파이프의 relativeX를 기준으로 재배치
    double maxRelativeX = _pipePool.map((p) => p.relativeX).reduce(math.max);
    pipe.relativeX = maxRelativeX + kPipeSpacing;
    _nextPipeX = pipe.relativeX + kPipeSpacing;
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

    // 매 프레임 파이프 속도가 증가하도록 업데이트합니다.
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
