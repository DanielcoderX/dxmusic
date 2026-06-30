import 'package:on_audio_query/on_audio_query.dart';

class MusicScanner {
  final OnAudioQuery _audioQuery = OnAudioQuery();

  /// Fetches the latest songs from the device's MediaStore.
  /// Sorting by DATE_ADDED ensuring newly downloaded tracks appear at the top.
  Future<List<SongModel>> scanDeviceSongs() async {
      return await _audioQuery.querySongs(
        sortType: SongSortType.DATE_ADDED, // Sorts by filesystem timestamp
        orderType: OrderType.DESC_OR_GREATER, // Forces newest entries to the top
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );
    }

  /// Corrected permission handling using on_audio_query's built-in methods
  Future<bool> checkAndRequestPermissions() async {
    // This automatically handles Android 13+ READ_MEDIA_AUDIO vs older READ_EXTERNAL_STORAGE
    bool hasPermission = await _audioQuery.checkAndRequest(
      retryRequest: true,
    );
    return hasPermission;
  }
}