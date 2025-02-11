import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';

class MyAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  MediaItem? _currentMediaItem;

  late final StreamSubscription<PlayerState> _playerStateSubscription;
  late final StreamSubscription<Duration> _positionSubscription;
  late final StreamSubscription<Duration> _bufferedPositionSubscription;

  MyAudioHandler() {
    // 플레이어의 상태, 위치, 버퍼링 위치를 각각 구독하여 playbackState를 업데이트
    _playerStateSubscription = _player.playerStateStream.listen(_broadcastState);
    _positionSubscription = _player.positionStream.listen((position) {
      final currentState = playbackState.value;
      playbackState.add(currentState.copyWith(updatePosition: position));
    });
    _bufferedPositionSubscription = _player.bufferedPositionStream.listen((bufferedPosition) {
      final currentState = playbackState.value;
      playbackState.add(currentState.copyWith(bufferedPosition: bufferedPosition));
    });
  }

  // just_audio의 ProcessingState를 audio_service의 AudioProcessingState로 변환
  AudioProcessingState _mapProcessingState(ProcessingState state) {
    switch (state) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;
      case ProcessingState.loading:
        return AudioProcessingState.loading;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
      default:
        return AudioProcessingState.idle;
    }
  }

  // 플레이어 상태에 따라 playbackState를 전파
  void _broadcastState(PlayerState state) {
    final playing = state.playing;
    final processingState = state.processingState;
    final audioProcessingState = _mapProcessingState(processingState);

    playbackState.add(
      PlaybackState(
        controls: [
          MediaControl.rewind,
          playing ? MediaControl.pause : MediaControl.play,
          MediaControl.fastForward,
          MediaControl.stop,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: audioProcessingState,
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: 0,
      ),
    );
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> fastForward() async {
    final newPosition = _player.position + const Duration(seconds: 10);
    await _player.seek(newPosition);
  }

  @override
  Future<void> rewind() async {
    final newPosition = _player.position - const Duration(seconds: 10);
    await _player.seek(newPosition < Duration.zero ? Duration.zero : newPosition);
  }

  // 새로운 미디어 항목 업데이트
  Future<void> updateMediaItem(MediaItem newMediaItem) async {
    if (_currentMediaItem?.id == newMediaItem.id) return;
    _currentMediaItem = newMediaItem;

    try {
      // newMediaItem.id가 자산(asset) 경로라고 가정하고 오디오 소스를 설정
      final duration = await _player.setAudioSource(AudioSource.asset(newMediaItem.id));
      final updatedItem = newMediaItem.copyWith(duration: duration);
      mediaItem.add(updatedItem);
    } catch (e) {
      print("❗ 오디오 로드 실패: $e");
      final updatedItem = newMediaItem.copyWith(duration: Duration.zero);
      mediaItem.add(updatedItem);
    }

    // 반복 재생을 위해 LoopMode.one 설정 (just_audio의 LoopMode.one과 동일)
    await _player.setLoopMode(LoopMode.one);
  }

  // 리소스 해제를 위한 dispose 메서드
  Future<void> dispose() async {
    await _playerStateSubscription.cancel();
    await _positionSubscription.cancel();
    await _bufferedPositionSubscription.cancel();
    await _player.dispose();
  }
}
