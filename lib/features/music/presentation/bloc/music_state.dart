// STATE
import 'dart:typed_data';
import 'dart:ui';

import 'package:on_audio_query/on_audio_query.dart';

class MusicState {
  final List<SongModel> allSongs;
  final List<SongModel> filteredSongs;
  final SongModel? currentSong;
  final Uint8List? currentArtworkBytes;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final bool isShuffleEnabled;
  final bool isRepeatEnabled;
  final bool isPermissionDenied;
  final Color dominantColor;
  final Color accentColor;
  MusicState({
    required this.allSongs,
    required this.filteredSongs,
    this.currentSong,
    this.currentArtworkBytes,
    this.isPlaying = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.isShuffleEnabled = false,
    this.isRepeatEnabled = false,
    this.isPermissionDenied = false,
    this.dominantColor = const Color(0xFF1E1E24), // Sleek default dark gray
    this.accentColor = const Color(0xFF5F5CFF),   // Your original premium purple neon
  });

  MusicState copyWith({
    List<SongModel>? allSongs,
    List<SongModel>? filteredSongs,
    SongModel? currentSong,
    Uint8List? currentArtworkBytes,
    bool? isPlaying,
    Duration? position,
    Duration? duration,
    bool? isShuffleEnabled,
    bool? isRepeatEnabled,
    bool? isPermissionDenied,
    Color? dominantColor,
    Color? accentColor,
  }) {
    return MusicState(
      allSongs: allSongs ?? this.allSongs,
      filteredSongs: filteredSongs ?? this.filteredSongs,
      currentSong: currentSong ?? this.currentSong,
      currentArtworkBytes: currentArtworkBytes ?? this.currentArtworkBytes,
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      isShuffleEnabled: isShuffleEnabled ?? this.isShuffleEnabled,
      isRepeatEnabled: isRepeatEnabled ?? this.isRepeatEnabled,
      isPermissionDenied: isPermissionDenied ?? this.isPermissionDenied,
      dominantColor: dominantColor ?? this.dominantColor,
      accentColor: accentColor ?? this.accentColor,
    );
  }
}
