import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class DXAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  // Pass handleInterruptions: true and androidApplyAudioAttributes: true
  // into the constructor. This natively handles calls and headphone unplugging.
  final AudioPlayer _player = AudioPlayer(
    handleInterruptions: true,
    androidApplyAudioAttributes: true,
    handleAudioSessionActivation: true,
  );
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  // Maintain a local boolean inside the background engine thread
  bool isRepeatEnabled = false;

  // Callback hook to let our UI know it needs to advance the track array
  Function? onTrackCompleteCallback;
  DXAudioHandler() {
    // Forward playback states directly to the Android system notifications
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);
    _initAudioInteractions();
    _listenToCompletion();
  }
  void _listenToCompletion() {
    _player.processingStateStream.listen((state) async {
      if (state == ProcessingState.completed) {
        if (isRepeatEnabled) {
          // Loop seamlessly at the source layer without firing outer event queues
          await _player.seek(Duration.zero);
          _player.play();
        } else {
          // Notify the UI layer to advance the track array index
          if (onTrackCompleteCallback != null) {
            onTrackCompleteCallback!();
          }
        }
      }
    });
  }

  void _initAudioInteractions() async {
    try {
      // Use just_audio's native platform property configuration mapping
      await _player.setAndroidAudioAttributes(
        const AndroidAudioAttributes(
          contentType: AndroidAudioContentType.music,
          usage: AndroidAudioUsage.media,
        ),
      );
    } catch (e) {
      debugPrint("Audio attributes configuration error: $e");
    }
  }

  // Set the track currently playing and broadcast its details to the lock screen
  Future<void> playItem(MediaItem item) async {
    mediaItem.add(item);
    try {
      await _player.setAudioSource(AudioSource.uri(Uri.parse(item.id)));
      play();
    } catch (e) {
      debugPrint("Error setting audio source: $e");
    }
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() async {
    await _player.stop();
    await playbackState.firstWhere(
      (state) => state.processingState == AudioProcessingState.idle,
    );
  }

  @override
  Future<void> skipToNext() async {}

  @override
  Future<void> skipToPrevious() async {}

  /// Converts just_audio's stream configurations into audio_service platform events
  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 3],
      processingState:
          const {
            ProcessingState.idle: AudioProcessingState.idle,
            ProcessingState.loading: AudioProcessingState.loading,
            ProcessingState.buffering: AudioProcessingState.buffering,
            ProcessingState.ready: AudioProcessingState.ready,
            ProcessingState.completed: AudioProcessingState.completed,
          }[_player.processingState] ??
          AudioProcessingState.idle, // Fallback safety clamp
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    );
  }
}
