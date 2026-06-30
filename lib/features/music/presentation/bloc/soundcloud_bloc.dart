import 'dart:io';
import 'package:audiotags/audiotags.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:path_provider/path_provider.dart';
import 'package:soundcloud_explode_dart/soundcloud_explode_dart.dart';

// --- EVENTS ---
abstract class SoundCloudEvent {}
class LoadSoundCloudContent extends SoundCloudEvent { final String url; LoadSoundCloudContent(this.url); }
class DownloadExplodedTrack extends SoundCloudEvent { final SoundcloudTrack track; DownloadExplodedTrack(this.track); }

// --- STATES ---
abstract class SoundCloudState {}
class SoundCloudInitial extends SoundCloudState {}
class SoundCloudLoading extends SoundCloudState {}
class SoundCloudLoaded extends SoundCloudState { 
  final List<SoundcloudTrack> tracks; 
  final Map<int, double> downloadProgress;
  SoundCloudLoaded(this.tracks, {this.downloadProgress = const {}}); 

  SoundCloudLoaded copyWith({
    List<SoundcloudTrack>? tracks,
    Map<int, double>? downloadProgress,
  }) {
    return SoundCloudLoaded(
      tracks ?? this.tracks,
      downloadProgress: downloadProgress ?? this.downloadProgress,
    );
  }
}
class SoundCloudDownloadSuccess extends SoundCloudLoaded { 
  final String filePath; 
  SoundCloudDownloadSuccess(List<SoundcloudTrack> tracks, this.filePath, {Map<int, double> downloadProgress = const {}}) : super(tracks, downloadProgress: downloadProgress); 
}
class SoundCloudError extends SoundCloudState { 
  final String message; 
  final List<SoundcloudTrack>? tracks;
  SoundCloudError(this.message, {this.tracks}); 
}

// --- BLOC ---
class SoundCloudBloc extends Bloc<SoundCloudEvent, SoundCloudState> {
  final SoundcloudClient _scClient = SoundcloudClient();
  final Dio _dio = Dio();

  SoundCloudBloc() : super(SoundCloudInitial()) {
    
    // Resolves profiles, individual tracks, or whole albums/playlists keyless
    on<LoadSoundCloudContent>((event, emit) async {
      emit(SoundCloudLoading());
      try {
        List<SoundcloudTrack> targetTracks = [];
        final inputUrl = event.url.trim();

        if (inputUrl.startsWith('http://') ||
            inputUrl.startsWith('https://') ||
            inputUrl.contains('soundcloud.com') ||
            inputUrl.contains('/')) {
          if (inputUrl.contains('/sets/')) {
            // It's a Playlist or Album
            final playlist = await _scClient.playlists.getByUrl(inputUrl);
            // Fetch tracks within that playlist payload
            final trackStream = _scClient.playlists.getTracks(playlist.id);
            await for (var batch in trackStream) {
              targetTracks.addAll(batch);
            }
          } else if (inputUrl.contains('/tracks/') || inputUrl.split('/').length == 5) {
            // Direct individual track link
            final track = await _scClient.tracks.getByUrl(inputUrl);
            targetTracks.add(track);
          } else {
            // Assume it's a User profile URL - load their public tracks
            final user = await _scClient.users.getByUrl(inputUrl);
            final trackStream = _scClient.users.getTracks(user.id);
            await for (var batch in trackStream) {
              targetTracks.addAll(batch);
            }
          }
        } else {
          // Regular text search
          final searchStream = _scClient.search.getTracks(inputUrl, limit: 30);
          final firstBatch = await searchStream.first;
          targetTracks.addAll(firstBatch);
        }

        emit(SoundCloudLoaded(targetTracks));
      } catch (e) {
        emit(SoundCloudError("Couldn't process search or URL: $e"));
      }
    });

    on<DownloadExplodedTrack>((event, emit) async {
      final currentState = state;
      final List<SoundcloudTrack> currentTracks = currentState is SoundCloudLoaded ? currentState.tracks : [];
      final Map<int, double> currentProgress = currentState is SoundCloudLoaded ? Map.from(currentState.downloadProgress) : {};

      try {
        currentProgress[event.track.id] = 0.01;
        emit(SoundCloudLoaded(currentTracks, downloadProgress: Map.from(currentProgress)));

        // Get the internal stream layout from soundcloud_explode
        final streamInfo = await _scClient.tracks.getStreams(event.track.id);
        
        // Find a valid stream URL (prefer progressive or high-quality streams if available)
        if (streamInfo.isEmpty) {
          emit(SoundCloudError("No available audio stream found for this track.", tracks: currentTracks));
          return;
        }

        // Find a progressive stream first (direct download)
        final stream = streamInfo.firstWhere(
          (s) => s.protocol == 'progressive' || s.protocol.toString().toLowerCase().contains('progressive'),
          orElse: () => streamInfo.first,
        );
        final String directStreamUrl = stream.url;

        // Resolve local file system targets safely
        final Directory downloadDir = Platform.isAndroid 
            ? Directory('/storage/emulated/0/Download') 
            : await getApplicationDocumentsDirectory();
            
        final String appFolder = "${downloadDir.path}/DXMusic";
        await Directory(appFolder).create(recursive: true);

        // Sanitize symbols from title to prevent OS storage errors
        final sanitizedTitle = event.track.title.replaceAll(RegExp(r'[^\w\s\-\.]'), '');
        final String savePath = "$appFolder/$sanitizedTitle.mp3";

        final isProgressive = stream.protocol == 'progressive' ||
            stream.protocol.toString().toLowerCase().contains('progressive');

        if (isProgressive) {
          // Direct progressive download
          await _dio.download(
            directStreamUrl, 
            savePath,
            onReceiveProgress: (received, total) {
              if (total != -1) {
                currentProgress[event.track.id] = received / total;
                emit(SoundCloudLoaded(currentTracks, downloadProgress: Map.from(currentProgress)));
              }
            },
          );
        } else {
          // It's HLS (m3u8) - parse and download segments
          final playlistResponse = await _dio.get<String>(directStreamUrl);
          if (playlistResponse.data == null) {
            emit(SoundCloudError("Failed to fetch stream playlist.", tracks: currentTracks));
            return;
          }
          final lines = playlistResponse.data!.split('\n');
          final segmentUrls = lines
              .map((line) => line.trim())
              .where((line) => line.isNotEmpty && !line.startsWith('#'))
              .toList();

          if (segmentUrls.isEmpty) {
            emit(SoundCloudError("No audio segments found in stream.", tracks: currentTracks));
            return;
          }

          final File file = File(savePath);
          final IOSink sink = file.openWrite();

          for (int i = 0; i < segmentUrls.length; i++) {
            final segmentUrl = segmentUrls[i];
            final response = await _dio.get<List<int>>(
              segmentUrl,
              options: Options(responseType: ResponseType.bytes),
            );
            if (response.data != null) {
              sink.add(response.data!);
            }
            currentProgress[event.track.id] = (i + 1) / segmentUrls.length;
            emit(SoundCloudLoaded(currentTracks, downloadProgress: Map.from(currentProgress)));
          }
          await sink.flush();
          await sink.close();
        }

        // --- Write ID3 tags and artwork cover ---
        try {
          // Get artwork bytes
          Uint8List? artworkBytes;
          if (event.track.artworkUrl != null) {
            final artResponse = await _dio.get<List<int>>(
              event.track.artworkUrl!.toString(),
              options: Options(responseType: ResponseType.bytes),
            );
            if (artResponse.data != null) {
              artworkBytes = Uint8List.fromList(artResponse.data!);
            }
          }          
          final tag = Tag(
            title: event.track.title,
            trackArtist: event.track.user.username,
            album: "SoundCloud",
            pictures: artworkBytes != null ? [
              Picture(
                bytes: artworkBytes,
                mimeType: MimeType.jpeg,
                pictureType: PictureType.coverFront,
              ),
            ] : [],
          );
          
          await AudioTags.write(savePath, tag);
        } catch (tagError) {
          debugPrint("Failed to write ID3 tags/artwork: $tagError");
        }

        try {
          final OnAudioQuery audioQuery = OnAudioQuery();
          await audioQuery.scanMedia(savePath);
        } catch (scanError) {
          debugPrint("Failed to scan media into MediaStore: $scanError");
        }

        currentProgress.remove(event.track.id);
        emit(SoundCloudDownloadSuccess(currentTracks, savePath, downloadProgress: Map.from(currentProgress)));
      } catch (e) {
        currentProgress.remove(event.track.id);
        emit(SoundCloudError("Download pipeline dropped track stream frame: $e", tracks: currentTracks));
      }
    });
  }
}