import 'dart:io';
import 'dart:typed_data';

import 'package:audio_service/audio_service.dart';
import 'package:dxmusic/features/music/data/sources/music_scanner.dart';
import 'package:dxmusic/features/music/presentation/bloc/music_event.dart';
import 'package:dxmusic/features/music/presentation/bloc/music_state.dart';
import 'package:dxmusic/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:palette_generator/palette_generator.dart';

// BLOC
class MusicBloc extends Bloc<MusicEvent, MusicState> {
  final MusicScanner _scanner = MusicScanner();
  int _currentIndex = -1;

  MusicBloc() : super(MusicState(allSongs: [], filteredSongs: [])) {
    on<LoadLibrary>((event, emit) {
      emit(state.copyWith(allSongs: event.songs, filteredSongs: event.songs));
    });

    on<ScanLibrary>((event, emit) async {
      final hasPermission = await _scanner.checkAndRequestPermissions();
      if (hasPermission) {
        // This list now natively arrives sorted with newest songs at index 0
        final songs = await _scanner.scanDeviceSongs();
        emit(state.copyWith(allSongs: songs, filteredSongs: songs));
      } else {
        emit(state.copyWith(allSongs: [], filteredSongs: []));
      }
    });
    on<FilterSearch>((event, emit) {
      final query = event.query.toLowerCase();

      // If search query is blank, restore original active state queue respect to shuffle
      if (query.isEmpty) {
        List<SongModel> originalQueue = List.from(state.allSongs);
        if (state.isShuffleEnabled) {
          originalQueue.shuffle();
          if (state.currentSong != null) {
            originalQueue.removeWhere(
              (song) => song.id == state.currentSong!.id,
            );
            originalQueue.insert(0, state.currentSong!);
            _currentIndex = 0;
          }
        }
        emit(state.copyWith(filteredSongs: originalQueue));
        return;
      }

      final filtered = state.allSongs.where((song) {
        return song.title.toLowerCase().contains(query) ||
            (song.artist?.toLowerCase().contains(query) ?? false);
      }).toList();

      // Reset tracking position to match the filtered array sequence cleanly if playing
      if (state.currentSong != null) {
        _currentIndex = filtered.indexWhere(
          (song) => song.id == state.currentSong!.id,
        );
      }

      emit(state.copyWith(filteredSongs: filtered));
    });

    on<PlayTrack>((event, emit) async {
      if (event.index >= state.filteredSongs.length || event.index < 0) return;

      _currentIndex = event.index;
      final targetSong = state.filteredSongs[_currentIndex];

      // 1. Fetch Raw Artwork Bytes Asynchronously ONCE
      Uint8List? artworkBytes;
      try {
        artworkBytes = await OnAudioQuery().queryArtwork(
          targetSong.id,
          ArtworkType.AUDIO,
          format: ArtworkFormat.JPEG,
          size: 500, // Higher resolution for main player background/cover
        );
      } catch (e) {
        debugPrint("Failed to fetch native artwork bytes: $e");
      }

      // 2. Extract palette colors dynamically from our fetched bytes
      Color extractedDominant = const Color(0xFF1A1A1A);
      Color extractedAccent = const Color(0xFF5F5CFF);

      try {
        ImageProvider imgProvider = artworkBytes != null
            ? MemoryImage(artworkBytes)
            : const AssetImage('assets/images/default_album.png')
                  as ImageProvider;

        final paletteGenerator = await PaletteGenerator.fromImageProvider(
          imgProvider,
          size: const Size(50, 50), // Scale down drastically for color extraction
          maximumColorCount: 10,
        );

        if (paletteGenerator.dominantColor != null) {
          extractedDominant = Color.alphaBlend(
            Colors.black.withOpacity(0.45),
            paletteGenerator.dominantColor!.color,
          );
        }
        extractedAccent =
            paletteGenerator.vibrantColor?.color ??
            paletteGenerator.lightVibrantColor?.color ??
            const Color(0xFF5F5CFF);
      } catch (e) {
        debugPrint("Palette color extraction skipped: $e");
      }

      final mediaItem = MediaItem(
        id: targetSong.uri!,
        album: "Local Audio",
        title: targetSong.title,
        artist: targetSong.artist ?? "Unknown Artist",
        duration: Duration(milliseconds: targetSong.duration ?? 0),
      );

      await globalAudioHandler.playItem(mediaItem);

      // 3. Emit the state with the persistent image bytes cached safely
      emit(
        state.copyWith(
          currentSong: targetSong,
          currentArtworkBytes: artworkBytes, // <-- CACHED HERE
          isPlaying: true,
          dominantColor: extractedDominant,
          accentColor: extractedAccent,
        ),
      );
    });
    on<DeleteTrack>((event, emit) async {
      if (event.index < 0 || event.index >= state.filteredSongs.length) return;

      final targetSong = state.filteredSongs[event.index];

      try {
        // 1. Handle active audio streaming safety layers
        if (state.currentSong?.id == targetSong.id) {
          if (state.filteredSongs.length > 1) {
            add(NextTrack());
          } else {
            globalAudioHandler.stop();
            emit(
              state.copyWith(
                currentSong: null,
                currentArtworkBytes: null,
                isPlaying: false,
              ),
            );
          }
        }

        // 2. Perform direct storage purge
        final file = File(targetSong.data);
        if (await file.exists()) {
          await file.delete();
        }

        // 3. Mutate persistent tracking states natively
        final updatedAllSongs = List<SongModel>.from(state.allSongs)
          ..removeWhere((song) => song.id == targetSong.id);

        final updatedFilteredSongs = List<SongModel>.from(state.filteredSongs)
          ..removeAt(event.index);

        // Recalculate index sequence offsets safely
        if (state.currentSong != null) {
          _currentIndex = updatedFilteredSongs.indexWhere(
            (song) => song.id == state.currentSong!.id,
          );
        }

        emit(
          state.copyWith(
            allSongs: updatedAllSongs,
            filteredSongs: updatedFilteredSongs,
          ),
        );

        ScaffoldMessenger.of(event.context).showSnackBar(
          SnackBar(
            content: Text('"${targetSong.title}" deleted completely.'),
            backgroundColor: const Color(0xFF5F5CFF),
          ),
        );
      } catch (e) {
        // Native fallback check if storage permissions prevent direct Dart IO access
        debugPrint(
          "File delete failed, executing reactive collection purge: $e",
        );

        // Evict from active application views even if file system is protected
        final updatedAllSongs = List<SongModel>.from(state.allSongs)
          ..removeWhere((song) => song.id == targetSong.id);
        final updatedFilteredSongs = List<SongModel>.from(state.filteredSongs)
          ..removeAt(event.index);

        emit(
          state.copyWith(
            allSongs: updatedAllSongs,
            filteredSongs: updatedFilteredSongs,
          ),
        );

        ScaffoldMessenger.of(event.context).showSnackBar(
          const SnackBar(
            content: Text('Song removed from library view.'),
            backgroundColor: Colors.amber,
          ),
        );
      }
    });
    on<TogglePlayPause>((event, emit) {
      if (state.isPlaying) {
        globalAudioHandler.pause();
        emit(state.copyWith(isPlaying: false));
      } else {
        globalAudioHandler.play();
        emit(state.copyWith(isPlaying: true));
      }
    });
    on<SeekToPosition>((event, emit) async {
      await globalAudioHandler.seek(event.position);
    });

    on<ToggleShuffle>((event, emit) {
      final currentTrack = state.currentSong;
      final bool newShuffleState = !state.isShuffleEnabled;

      // Clones the timeline-sorted master list
      List<SongModel> updatedQueue = List.from(state.allSongs);

      if (newShuffleState) {
        updatedQueue.shuffle();
        if (currentTrack != null) {
          updatedQueue.removeWhere((song) => song.id == currentTrack.id);
          updatedQueue.insert(0, currentTrack);
          _currentIndex = 0;
        }
      } else {
        if (currentTrack != null) {
          // Maps current song index back to its correct timeline location seamlessly
          _currentIndex = updatedQueue.indexWhere(
            (song) => song.id == currentTrack.id,
          );
        }
      }

      emit(
        state.copyWith(
          isShuffleEnabled: newShuffleState,
          filteredSongs:
              updatedQueue, // Returns smoothly to Date-Added order if false
        ),
      );
    });

    on<ToggleRepeat>((event, emit) {
      final newRepeatState = !state.isRepeatEnabled;
      globalAudioHandler.isRepeatEnabled =
          newRepeatState; // Update background service layer
      emit(state.copyWith(isRepeatEnabled: newRepeatState));
    });

    // REGISTER NEXT TRACK HANDLER
    on<NextTrack>((event, emit) async {
      if (state.filteredSongs.isEmpty) return;

      // Calculate next index looping back to 0 if at the end
      int nextIndex = _currentIndex + 1;
      if (nextIndex >= state.filteredSongs.length) {
        nextIndex = 0;
      }

      // Trigger the existing PlayTrack logic dynamically
      add(PlayTrack(nextIndex));
    });

    // REGISTER PREVIOUS TRACK HANDLER
    on<PreviousTrack>((event, emit) async {
      if (state.filteredSongs.isEmpty) return;

      // Calculate previous index looping to the end if at 0
      int prevIndex = _currentIndex - 1;
      if (prevIndex < 0) {
        prevIndex = state.filteredSongs.length - 1;
      }

      add(PlayTrack(prevIndex));
    });

    on<InternalPlaybackStatusUpdate>((event, emit) {
      emit(state.copyWith(isPlaying: event.isPlaying));
    });

    on<InternalPositionUpdate>((event, emit) {
      emit(state.copyWith(position: event.position));
    });

    on<InternalDurationUpdate>((event, emit) {
      emit(state.copyWith(duration: event.duration));
    });
    on<InternalTrackFinished>((event, emit) async {
      if (state.isRepeatEnabled) {
        // If repeat is ON: Seek back to the beginning and restart playback
        await globalAudioHandler.seek(Duration.zero);
        await globalAudioHandler.play();
      } else {
        // If repeat is OFF: Auto-advance to the next track in queue
        add(NextTrack());
      }
    });
    on<QueuePlayNext>((event, emit) {
      if (state.filteredSongs.isEmpty) {
        emit(state.copyWith(allSongs: [event.song], filteredSongs: [event.song]));
        add(PlayTrack(0));
        return;
      }

      // Create mutable clones of our active lists
      final updatedFiltered = List<SongModel>.from(state.filteredSongs);
      
      // Remove the song if it already exists somewhere else in the active display list to prevent duplicates
      updatedFiltered.removeWhere((s) => s.id == event.song.id);

      // Determine where to insert it (immediately right after our currently active index track)
      int insertIndex = _currentIndex + 1;
      if (insertIndex < 0 || insertIndex > updatedFiltered.length) {
        insertIndex = 0;
      }

      updatedFiltered.insert(insertIndex, event.song);
      
      emit(state.copyWith(filteredSongs: updatedFiltered));
    });

    on<QueueAddLast>((event, emit) {
      final updatedFiltered = List<SongModel>.from(state.filteredSongs);
      
      // Prevent duplicating the exact same instance in the current view array
      updatedFiltered.removeWhere((s) => s.id == event.song.id);
      updatedFiltered.add(event.song);
      
      emit(state.copyWith(filteredSongs: updatedFiltered));
    });
    // Listen to real-time audio positions to keep sliders perfectly synchronized
    globalAudioHandler.positionStream.listen((pos) {
      add(InternalPositionUpdate(pos));
    });

    // Listen to duration stream to dynamically update track length
    globalAudioHandler.durationStream.listen((dur) {
      add(InternalDurationUpdate(dur ?? Duration.zero));
    });

    globalAudioHandler.playbackState.listen((playbackState) {
      // 1. Live slider position updates
      add(InternalPositionUpdate(playbackState.position));

      // 2. Synchronize notification play/pause button state with the Flutter UI
      add(InternalPlaybackStatusUpdate(playbackState.playing));
    });

    globalAudioHandler.mediaItem.listen((item) {
      if (item?.duration != null) {
        add(InternalDurationUpdate(item!.duration!));
      }
    });
    globalAudioHandler.onTrackCompleteCallback = () {
      add(NextTrack());
    };
  }
}
