// EVENTS
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

abstract class MusicEvent {}

class LoadLibrary extends MusicEvent {
  final List<SongModel> songs;
  LoadLibrary(this.songs);
}

class FilterSearch extends MusicEvent {
  final String query;
  FilterSearch(this.query);
}

class PlayTrack extends MusicEvent {
  final int index;
  PlayTrack(this.index);
}

class TogglePlayPause extends MusicEvent {}

class NextTrack extends MusicEvent {}

class PreviousTrack extends MusicEvent {}

class ScanLibrary extends MusicEvent {}



class SeekToPosition extends MusicEvent {
  final Duration position;
  SeekToPosition(this.position);
}

class ToggleShuffle extends MusicEvent {}

class ToggleRepeat extends MusicEvent {}

class InternalPlaybackStatusUpdate extends MusicEvent {
  final bool isPlaying;
  InternalPlaybackStatusUpdate(this.isPlaying);
}
// Secondary structural update events for stability
class InternalPositionUpdate extends MusicEvent {
  final Duration position;
  InternalPositionUpdate(this.position);
}

class InternalDurationUpdate extends MusicEvent {
  final Duration duration;
  InternalDurationUpdate(this.duration);
}
class InternalTrackFinished extends MusicEvent {}
class DeleteTrack extends MusicEvent {
  final int index;
  final BuildContext context;
  DeleteTrack({required this.index, required this.context});
}
class QueuePlayNext extends MusicEvent {
  final SongModel song;
  QueuePlayNext(this.song);
}

class QueueAddLast extends MusicEvent {
  final SongModel song;
  QueueAddLast(this.song);
}