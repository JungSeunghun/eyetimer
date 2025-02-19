import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'blink_rabbit_screen.dart';
import 'jump_rabbit_screen.dart';

class ExerciseScreen extends StatefulWidget {
  const ExerciseScreen({Key? key}) : super(key: key);

  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen> {
  // 선택한 캐릭터 인덱스 (기본값: 0 - rabbit)
  int _selectedCharacterIndex = 0;
  // 캐릭터 이름 리스트
  final List<String> characterNames = [
    'character.rabbit',
    'character.cat',
    'character.dog'
  ];
  // 캐릭터 이미지 리스트 (경로는 character/ 하위에 있음)
  final List<String> characterImages = [
    'character/rabbit.png',
    'character/cat.png',
    'character/dog.png',
  ];

  // 각 게임의 예시 이미지 경로 (예시: game/ 하위에 있음)
  final String blinkGamePreview = 'assets/images/blink_rabbit/blink_game_preview.png';
  final String jumpGamePreview = 'assets/images/jump_rabbit/jump_game_preview.png';

  static const String _prefKey = 'selectedCharacterIndex';

  @override
  void initState() {
    super.initState();
    _loadSelectedCharacter();
  }

  Future<void> _loadSelectedCharacter() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedCharacterIndex = prefs.getInt(_prefKey) ?? 0;
    });
  }

  Future<void> _saveSelectedCharacter(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefKey, index);
  }

  // 에셋 경로에 "assets/images/" 접두어를 붙여 반환하는 헬퍼 함수
  String _fullAssetPath(String path) {
    return 'assets/images/$path';
  }

  // 미니멀한 스타일의 게임 카드 위젯 (정사각형 카드, 이미지 꽉 채움, 제목 오버레이)
  Widget _buildGameCard({
    required BuildContext context,
    required VoidCallback onTap,
    required String title,
    required String imagePath,
    required Color backgroundColor,
  }) {
    double cardSize = MediaQuery.of(context).size.width * 0.8; // 정사각형 크기
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: cardSize,
        height: cardSize,
        child: Card(
          color: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 10),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyMedium?.color ?? Colors.black;
    final backgroundColor = theme.scaffoldBackgroundColor;
    final primaryColor = theme.primaryColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // 상단 캐릭터 선택 리스트
              SizedBox(
                height: 102,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: characterImages.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemBuilder: (context, index) {
                    final isSelected = index == _selectedCharacterIndex;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCharacterIndex = index;
                        });
                        _saveSelectedCharacter(index);
                      },
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4.0), // 원하는 패딩 값으로 조정하세요.
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isSelected ? primaryColor : Colors.transparent,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Image.asset(
                              _fullAssetPath(characterImages[index]),
                              width: 60,
                              height: 60,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            characterNames[index].tr(),
                            style: TextStyle(
                              fontSize: 14,
                              color: textColor,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              // Blink Rabbit Card (예시 이미지 사용)
              _buildGameCard(
                context: context,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BlinkRabbitScreen(
                        selectedCharacterAsset: characterImages[_selectedCharacterIndex],
                      ),
                    ),
                  );
                },
                title: 'blink_game_appbar_title',
                imagePath: blinkGamePreview,
                backgroundColor: backgroundColor,
              ),
              const SizedBox(height: 20),
              // Jump Rabbit Card (예시 이미지 사용)
              _buildGameCard(
                context: context,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => JumpRabbitScreen(
                        selectedCharacterAsset: characterImages[_selectedCharacterIndex],
                      ),
                    ),
                  );
                },
                title: 'jump_game_appbar_title',
                imagePath: jumpGamePreview,
                backgroundColor: backgroundColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
