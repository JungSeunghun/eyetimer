import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

/// MyAudioHandler는 BaseAudioHandler를 상속받아 just_audio를 통해 백그라운드에서 오디오를 재생합니다.
class MyAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player = AudioPlayer();

  // 현재 로드된 미디어 아이템 캐싱
  MediaItem? _currentMediaItem;

  MyAudioHandler() {
    // 플레이어 상태 변화에 따른 playbackState 업데이트
    _player.playerStateStream.listen((playerState) {
      final playing = playerState.playing;
      final processingState = playerState.processingState;
      AudioProcessingState audioProcessingState;
      switch (processingState) {
        case ProcessingState.idle:
          audioProcessingState = AudioProcessingState.idle;
          break;
        case ProcessingState.loading:
          audioProcessingState = AudioProcessingState.loading;
          break;
        case ProcessingState.buffering:
          audioProcessingState = AudioProcessingState.buffering;
          break;
        case ProcessingState.ready:
          audioProcessingState = AudioProcessingState.ready;
          break;
        case ProcessingState.completed:
          audioProcessingState = AudioProcessingState.completed;
          break;
        default:
          audioProcessingState = AudioProcessingState.idle;
          break;
      }

      // 컨트롤 버튼 목록에 rewind와 fastForward 추가
      final controls = [
        MediaControl.rewind,
        playing ? MediaControl.pause : MediaControl.play,
        MediaControl.fastForward,
        MediaControl.stop,
      ];

      final currentState = playbackState.valueOrNull;
      playbackState.add(
        (currentState ?? PlaybackState()).copyWith(
          controls: controls,
          processingState: audioProcessingState,
          playing: playing,
          updatePosition: _player.position,
          bufferedPosition: _player.bufferedPosition,
          speed: _player.speed,
          queueIndex: 0,
        ),
      );
    });

    // 재생 위치 스트림을 listen하여 updatePosition과 bufferedPosition을 실시간 업데이트
    _player.positionStream.listen((position) {
      final currentState = playbackState.valueOrNull;
      if (currentState != null) {
        playbackState.add(
          currentState.copyWith(
            updatePosition: position,
            bufferedPosition: _player.bufferedPosition,
          ),
        );
      }
    });
  }

  /// MediaItem 업데이트: 미디어 아이템이 변경된 경우에만 자산을 로드하고, 실제 오디오 길이(duration)를 가져옵니다.
  Future<void> updateMediaItem(MediaItem newMediaItem) async {
    if (_currentMediaItem?.id == newMediaItem.id) {
      print("이미 로드된 미디어 아이템입니다.");
      return;
    }
    _currentMediaItem = newMediaItem;
    Duration? audioDuration;
    try {
      // setAudioSource()는 오디오 자산을 로드한 후, 해당 오디오의 전체 길이(duration)를 반환합니다.
      audioDuration = await _player.setAudioSource(AudioSource.asset(newMediaItem.id));
    } catch (e) {
      print("오디오 로드 실패: $e");
    }
    final updatedMediaItem = newMediaItem.copyWith(
      duration: audioDuration ?? Duration.zero,
    );
    mediaItem.add(updatedMediaItem);
    // 반복 재생을 위해 LoopMode.one 설정
    await _player.setLoopMode(LoopMode.one);
  }

  @override
  Future<void> play() async {
    await _player.play();
  }

  @override
  Future<void> pause() async {
    await _player.pause();
  }

  @override
  Future<void> stop() async {
    await _player.pause();
    await _player.seek(Duration.zero);
    playbackState.add(
      PlaybackState(
        controls: [MediaControl.play, MediaControl.stop],
        processingState: AudioProcessingState.ready,
        playing: false,
        updatePosition: Duration.zero,
        bufferedPosition: Duration.zero,
        speed: 1.0,
        queueIndex: 0,
      ),
    );
    return super.stop();
  }

  // 15초 빠르게 앞으로 이동 (fastForward)
  @override
  Future<void> fastForward() async {
    final newPosition = _player.position + Duration(seconds: 10);
    await _player.seek(newPosition);
  }

  // 15초 뒤로 이동 (rewind)
  @override
  Future<void> rewind() async {
    var newPosition = _player.position - Duration(seconds: 10);
    if (newPosition < Duration.zero) newPosition = Duration.zero;
    await _player.seek(newPosition);
  }

  @override
  Future<dynamic> customAction(String name, [dynamic extras]) async {
    if (name == 'updateMediaItem' && extras is Map<String, dynamic>) {
      final newMediaItem = MediaItem(
        id: extras['id'] as String,
        album: extras['album'] as String? ?? '',
        title: extras['title'] as String? ?? '',
        duration: extras['duration'] as Duration?,
      );
      await updateMediaItem(newMediaItem);
    }
    return null;
  }
}
