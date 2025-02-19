import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/collisions.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';

class RabbitComponent extends SpriteComponent with CollisionCallbacks, HasGameRef<JumpRabbitGame> {
  double verticalVelocity = 0.0;
  double horizontalVelocity = 0.0;
  // 속도 조절 상수
  final double gravity = 0.5;
  final double jumpForce = -12.0;
  // 수평 속도 변화량 (눈 깜빡임으로 가해지는 힘)
  final double horizontalSpeedIncrement = 120.0; // 픽셀/초
  // 마찰 계수 (속도를 자연스럽게 감쇠)
  final double friction = 3.0; // 3/sec
  // 커스텀 visible 변수 추가
  bool _visible = true;
  bool get visible => _visible;
  set visible(bool value) {
    _visible = value;
  }

  RabbitComponent({
    required Sprite sprite,
    required Vector2 position,
    required Vector2 size,
  }) : super(sprite: sprite, position: position, size: size, anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox()..radius = size.x / 2);
  }

  @override
  void render(Canvas canvas) {
    if (!_visible) return; // visible이 false면 렌더링하지 않음
    super.render(canvas);
  }

  @override
  void update(double dt) {
    // 게임 시작 전에는 물리 업데이트를 중단하여 고정된 위치를 유지합니다.
    if (!gameRef.isGameStarted) return;
    super.update(dt);
    // 중력 적용
    verticalVelocity += gravity;
    position.y += verticalVelocity;

    // 수평 이동: 현재 속도에 dt를 곱해 이동하고, friction을 적용해 서서히 감속
    position.x += horizontalVelocity * dt;
    horizontalVelocity = ui.lerpDouble(horizontalVelocity, 0, friction * dt) ?? 0;

    // 화면 좌우 wrapping 처리
    final halfWidth = size.x / 2;
    if (position.x < -halfWidth) {
      position.x = gameRef.size.x + halfWidth;
    } else if (position.x > gameRef.size.x + halfWidth) {
      position.x = -halfWidth;
    }
  }

  void jump() {
    verticalVelocity = jumpForce;
    FlameAudio.play('jump_sound.mp3', volume: 1.0);
  }

  void moveRight() {
    horizontalVelocity -= horizontalSpeedIncrement;
  }

  void moveLeft() {
    horizontalVelocity += horizontalSpeedIncrement;
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is PlatformComponent && verticalVelocity > 0 && gameRef.isGameStarted) {
      final rabbitBottom = position.y + size.y / 2;
      final platformTop = other.position.y;

      if (rabbitBottom >= platformTop) {
        if (!other.scored) {
          other.scored = true;
          gameRef.score++;
          gameRef.onScoreChanged?.call();
        }
        jump();
      }
    }
  }
}

class PlatformComponent extends PositionComponent with CollisionCallbacks, HasGameRef<JumpRabbitGame> {
  // 동일 발판에서 중복 점수를 방지하는 플래그
  bool scored = false;

  PlatformComponent({
    required Vector2 position,
    required Vector2 size,
  }) : super(position: position, size: size, anchor: Anchor.topLeft);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox());
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = Colors.green;
    canvas.drawRect(size.toRect(), paint);
  }
}

class JumpRabbitGame extends FlameGame with HasCollisionDetection {
  // 추가: 선택된 캐릭터 에셋 경로를 외부에서 생성자 주입 받습니다.
  final String selectedCharacterAsset;
  JumpRabbitGame({required this.selectedCharacterAsset});

  // 게임 상태 필드
  bool isGameStarted = false;
  bool isGameOver = false;
  double score = 0;
  // 첫 게임 여부 플래그: 첫 게임은 onLoad()에서 생성된 발판들을 사용, 재시작 시 새롭게 생성합니다.
  bool hasStartedBefore = false;

  // 외부 콜백
  VoidCallback? onScoreChanged;
  VoidCallback? onGameOver;

  late Sprite rabbitSprite;
  late RabbitComponent rabbit;
  List<PlatformComponent> platforms = [];

  // 화면 하단 여백 및 발판, 토끼 크기 설정
  final double bottomMargin = 40.0;
  final Vector2 platformSize = Vector2(100, 20);
  final Vector2 rabbitSize = Vector2(50, 50);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await FlameAudio.audioCache.loadAll(['background_music.mp3', 'jump_sound.mp3']);
    FlameAudio.bgm.initialize();
    FlameAudio.bgm.play('background_music.mp3');

    final bgSprite = Sprite(await images.load('jump_rabbit/background.png'));
    final background = SpriteComponent(
      sprite: bgSprite,
      size: size,
      position: Vector2.zero(),
      anchor: Anchor.topLeft,
    );
    add(background);

    rabbitSprite = Sprite(await images.load(selectedCharacterAsset));
    final double firstPlatformY = size.y - bottomMargin - platformSize.y;
    final double rabbitY = firstPlatformY - rabbitSize.y / 2;
    rabbit = RabbitComponent(
      sprite: rabbitSprite,
      position: Vector2(size.x / 2, rabbitY),
      size: rabbitSize,
    );
    // 게임 시작 전에는 토끼를 보이지 않게 함.
    rabbit.visible = false;
    add(rabbit);

    // 최초 발판 생성: 첫 발판은 화면 하단 중앙에 위치
    _createInitialPlatforms(initial: true);
  }

  void _createInitialPlatforms({bool initial = false}) {
    // 재시작 시 기존 발판 제거
    if (!initial) {
      for (final platform in platforms) {
        remove(platform);
      }
      platforms.clear();
    }
    // 첫 발판: 화면 하단 중앙에 위치
    final double firstPlatformY = size.y - bottomMargin - platformSize.y;
    final double firstPlatformX = (size.x - platformSize.x) / 2;
    final firstPlatform = PlatformComponent(
      position: Vector2(firstPlatformX, firstPlatformY),
      size: platformSize,
    );
    platforms.add(firstPlatform);
    add(firstPlatform);

    // 나머지 발판들은 첫 발판 위쪽(화면 상단 방향)으로 일정 간격 유지하며 생성
    for (int i = 1; i < 10; i++) {
      final double y = firstPlatformY - i * 100;
      final double x = math.Random().nextDouble() * (size.x - platformSize.x);
      final newPlatform = PlatformComponent(
        position: Vector2(x, y),
        size: platformSize,
      );
      platforms.add(newPlatform);
      add(newPlatform);
    }
  }

  void startGame() {
    isGameStarted = true;
    isGameOver = false;
    score = 0;
    // 게임 시작 시 토끼의 위치와 속도 초기화
    final double firstPlatformY = size.y - bottomMargin - platformSize.y;
    final double rabbitY = firstPlatformY - rabbitSize.y / 2;
    rabbit.position = Vector2(size.x / 2, rabbitY);
    rabbit.verticalVelocity = 0;
    rabbit.horizontalVelocity = 0;
    // 토끼를 보이게 전환
    rabbit.visible = true;
    if (hasStartedBefore) {
      _createInitialPlatforms(initial: false);
    }
    hasStartedBefore = true;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isGameStarted && !isGameOver) {
      // 토끼의 바닥이 화면 하단을 넘으면 게임 오버 처리
      if (rabbit.position.y + rabbit.size.y / 2 > size.y) {
        isGameOver = true;
        isGameStarted = false;
        onGameOver?.call();
      }
    }

    // 화면 중앙 이상으로 올라가면 전체 스크롤
    if (rabbit.position.y < size.y / 2) {
      final double delta = (size.y / 2) - rabbit.position.y;
      rabbit.position.y += delta;
      for (final platform in platforms) {
        platform.position.y += delta;
      }
    }

    // 게임 중에도 화면 아래로 벗어난 발판 제거 후 새 발판 추가
    platforms.removeWhere((platform) => platform.position.y > size.y);
    while (platforms.length < 10) {
      final double y = platforms.isNotEmpty
          ? platforms.map((p) => p.position.y).reduce(math.min) - 100
          : size.y - bottomMargin - platformSize.y;
      final double x = math.Random().nextDouble() * (size.x - platformSize.x);
      final newPlatform = PlatformComponent(
        position: Vector2(x, y),
        size: platformSize,
      );
      platforms.add(newPlatform);
      add(newPlatform);
    }
  }

  @override
  void onDetach() {
    // 게임 종료 시 배경음악 중지 및 해제
    FlameAudio.bgm.stop();
    super.onDetach();
  }
}
