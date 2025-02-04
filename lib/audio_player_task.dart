import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';

/// MyAudioHandler는 BaseAudioHandler를 상속받아 just_audio를 통해 백그라운드에서 오디오를 재생합니다.
class MyAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player = AudioPlayer();

  MyAudioHandler() {
    // 플레이어 상태를 listen하여 playbackState 스트림을 업데이트합니다.
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

      final controls = playing
          ? [MediaControl.pause, MediaControl.stop]
          : [MediaControl.play, MediaControl.stop];

      playbackState.add(
        PlaybackState(
          controls: controls,
          systemActions: const {
            MediaAction.seek,
            MediaAction.seekForward,
            MediaAction.seekBackward,
          },
          androidCompactActionIndices: const [0, 1],
          processingState: audioProcessingState,
          playing: playing,
          updatePosition: _player.position,
          bufferedPosition: _player.bufferedPosition,
          speed: _player.speed,
          queueIndex: 0,
        ),
      );
    });
  }

  /// MediaItem 업데이트: mediaItem.id에는 asset 경로가 저장되어 있습니다.
  Future<void> updateMediaItem(MediaItem newMediaItem) async {
    // BaseAudioHandler의 mediaItem 스트림에 새 MediaItem 전달
    mediaItem.add(newMediaItem);
    try {
      await _player.setAudioSource(AudioSource.asset(newMediaItem.id));
      _player.setLoopMode(LoopMode.one);
    } catch (e) {
      print("오디오 로드 실패: $e");
    }
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
    // _player.dispose() 대신, 플레이어를 pause하고 위치를 0으로 이동시킵니다.
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

  @override
  Future<dynamic> customAction(String name, [dynamic extras]) async {
    if (name == 'updateMediaItem' && extras is Map<String, dynamic>) {
      final newMediaItem = MediaItem(
        id: extras['id'] as String,
        album: extras['album'] as String? ?? '',
        title: extras['title'] as String? ?? '',
        // 필요한 다른 필드가 있다면 추가합니다.
      );
      await updateMediaItem(newMediaItem);
    }
    return null;
  }
}
