import 'package:flutter/material.dart';
import 'flappy_bird_screen.dart';

class ExerciseScreen extends StatelessWidget {
  const ExerciseScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('운동/게임 선택 화면'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '운동/게임 목록',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // 예시 다른 게임 버튼들
              ElevatedButton(
                onPressed: () {
                  // TODO: 다른 게임1 시작
                },
                child: const Text('다른 게임1 시작하기'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  // TODO: 다른 게임2 시작
                },
                child: const Text('다른 게임2 시작하기'),
              ),
              const SizedBox(height: 30),

              // 플래피 버드 시작하기 버튼
              ElevatedButton(
                onPressed: () {
                  // [중요] FlappyBirdScreen으로 이동
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FlappyBirdScreen(),
                    ),
                  );
                },
                child: const Text('플래피 버드 시작하기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
