import 'dart:async';
import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';

class FlappyBlinkGame extends FlameGame
    with CollisionCallbacks, HasGameRef<FlappyBlinkGame> {
  static FlappyBlinkGame? gameRefer;
  late Bird _bird;
  final double _gravity = 0.8;
  final double _jumpForce = -12.0;
  final Random _random = Random();
  bool _isGameOver = false;
  int _score = 0;
  TimerComponent? _pipeSpawner;
  final TextComponent _scoreText = TextComponent();

  @override
  Future<void> onLoad() async {
    gameRefer = this;
    await _setupGame();
  }

  Future<void> _setupGame() async {
    final background = SpriteComponent(
      sprite: await Sprite.load('background.png'),
      size: size,
    );
    add(background);

    _bird = Bird();
    _bird.position = Vector2(size.x * 0.2, size.y / 2);
    add(_bird);

    final ground = Ground()
      ..position = Vector2(0, size.y - 50)
      ..size = Vector2(size.x, 50);
    add(ground);

    _scoreText
      ..text = 'Score: $_score'
      ..position = Vector2(size.x / 2, 50)
      ..anchor = Anchor.topCenter
      ..textRenderer = TextPaint(
        style: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [
            Shadow(
              color: Colors.black,
              blurRadius: 10,
              offset: Offset(2, 2),
            ),
          ],
        ),
      );
    add(_scoreText);

    _pipeSpawner = TimerComponent(
      period: 2.5,
      repeat: true,
      onTick: _spawnPipePair,
    );
    add(_pipeSpawner!);
  }

  void _spawnPipePair() {
    const pipeWidth = 80.0;
    const gapHeight = 200.0;
    final gapPosition = _random.nextDouble() * (size.y - gapHeight - 200);

    final topPipe = Pipe(isTop: true)
      ..position = Vector2(size.x, gapPosition - size.y)
      ..size = Vector2(pipeWidth, size.y);
    add(topPipe);

    final bottomPipe = Pipe(isTop: false)
      ..position = Vector2(size.x, gapPosition + gapHeight)
      ..size = Vector2(pipeWidth, size.y);
    add(bottomPipe);

    final scoreZone = ScoreZone()
      ..position = Vector2(size.x + pipeWidth / 2, gapPosition)
      ..size = Vector2(10, gapHeight);
    add(scoreZone);
  }

  void onBlinkDetected() {
    if (!_isGameOver) {
      _bird.jump(_jumpForce);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_isGameOver) {
      _bird.velocity.y += _gravity;
      _bird.position.y += _bird.velocity.y;
      _checkBoundaries();
    }
  }

  void _checkBoundaries() {
    if (_bird.position.y > size.y - 100) {
      _gameOver();
    }
  }

  void _gameOver() {
    _isGameOver = true;
    _pipeSpawner?.removeFromParent();
    overlays.add('gameOver');
  }

  void resetGame() {
    _isGameOver = false;
    _score = 0;
    _scoreText.text = 'Score: $_score';
    _bird.reset();
    _pipeSpawner = TimerComponent(
      period: 2.5,
      repeat: true,
      onTick: _spawnPipePair,
    );
    add(_pipeSpawner!);
    overlays.remove('gameOver');
  }

  void increaseScore() {
    _score++;
    _scoreText.text = 'Score: $_score';
  }
}

class Bird extends SpriteAnimationComponent with CollisionCallbacks, HasGameRef {
  Vector2 velocity = Vector2.zero();
  final double _rotationSpeed = 0.15;

  Bird() : super(size: Vector2.all(50));

  @override
  Future<void> onLoad() async {
    final spriteSheet = SpriteSheet(
      image: await gameRef.images.load('bird_sprite.png'),
      srcSize: Vector2.all(32),
    );

    animation = spriteSheet.createAnimation(
      row: 0,
      stepTime: 0.1,
      to: 3,
    );

    add(CircleHitbox()..collisionType = CollisionType.active);
  }

  void jump(double force) {
    velocity.y = force;
    // add(
    //   EffectController(
    //     duration: 0.3,
    //     alternate: true,
    //     infinite: false,
    //   ).addEffect(
    //     RotateEffect.by(
    //       -0.5,
    //       EffectController(
    //         duration: 0.3,
    //       ),
    //     ),
    //   ),
    // );
  }

  void reset() {
    position = Vector2(gameRef.size.x * 0.2, gameRef.size.y / 2);
    velocity = Vector2.zero();
    angle = 0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    angle = velocity.y * _rotationSpeed;
  }
}

class Pipe extends SpriteComponent with CollisionCallbacks {
  final bool isTop;

  Pipe({required this.isTop}) : super(size: Vector2.all(0));

  @override
  Future<void> onLoad() async {
    sprite = await Sprite.load('pipe.png');
    if (isTop) {
      angle = pi;
      anchor = Anchor.topCenter;
    } else {
      anchor = Anchor.bottomCenter;
    }
    add(RectangleHitbox()..collisionType = CollisionType.passive);
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.x -= 3;
    if (position.x < -width) {
      removeFromParent();
    }
  }
}

class Ground extends PositionComponent with CollisionCallbacks {
  @override
  Future<void> onLoad() async {
    add(RectangleHitbox()..collisionType = CollisionType.passive);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.drawRect(
      size.toRect(),
      Paint()..color = const Color(0xFF4CAF50),
    );
  }
}

class ScoreZone extends PositionComponent with CollisionCallbacks {
  @override
  Future<void> onLoad() async {
    add(RectangleHitbox()
      ..collisionType = CollisionType.passive
      ..isSolid = false);
  }

  @override
  void onCollisionStart(Set<Vector2> points, PositionComponent other) {
    super.onCollisionStart(points, other);
    if (other is Bird) {
      FlappyBlinkGame.gameRefer?.increaseScore();
      removeFromParent();
    }
  }
}