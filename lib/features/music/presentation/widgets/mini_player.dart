import 'package:animations/animations.dart';
import 'package:dxmusic/features/music/presentation/bloc/music_event.dart';
import 'package:dxmusic/features/music/presentation/bloc/music_state.dart';
import 'package:dxmusic/features/music/presentation/pages/player_page.dart';
import 'package:dxmusic/features/music/presentation/widgets/glass_box.dart';
import 'package:dxmusic/features/music/presentation/widgets/premium_title.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../bloc/music_bloc.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MusicBloc, MusicState>(
      buildWhen: (prev, curr) => 
          prev.currentSong != curr.currentSong || 
          prev.isPlaying != curr.isPlaying,
      builder: (context, state) {
        // Hide completely if no song has been chosen/loaded yet
        if (state.currentSong == null) return const SizedBox.shrink();

        final song = state.currentSong!;

        return OpenContainer(
          transitionType: ContainerTransitionType.fadeThrough,
          openColor: const Color(0xFF0A0A0C),
          closedColor: Colors.transparent,
          closedElevation: 0,
          openElevation: 0,
          // Defines the full expanded player screen route safely
          openBuilder: (context, _) => PlayerPage(song: song),
          closedBuilder: (context, openContainer) => GestureDetector(
            onTap: openContainer,
            child: GlassBox(
              blur: 30,
              opacity: 0.09,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14.0,
                  vertical: 10.0,
                ),
                child: Row(
                  children: [
                    // Dynamic Artwork
                    Hero(
                      tag: 'artwork_${song.id}',
                      child: QueryArtworkWidget(
                        id: song.id,
                        type: ArtworkType.AUDIO,
                        size: 200,
                        format: ArtworkFormat.JPEG,
                        quality: 100,
                        artworkBorder: BorderRadius.circular(12),
                        artworkWidth: 48,
                        artworkHeight: 48,
                        nullArtworkWidget: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            FeatherIcons.music,
                            color: Colors.white60,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Song Info (Title & Metadata)
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          buildPremiumTitle(
                            song.title,
                            fontSize: 14,
                            height: 20,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            song.artist ?? "Unknown Artist",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.45),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Media Action Button Controls
                    IconButton(
                      icon: Icon(
                        state.isPlaying
                            ? FeatherIcons.pause
                            : FeatherIcons.play,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () {
                        context.read<MusicBloc>().add(TogglePlayPause());
                      },
                    ),
                    IconButton(
                      icon: const Icon(
                        FeatherIcons.skipForward,
                        color: Colors.white70,
                        size: 20,
                      ),
                      onPressed: () {
                        context.read<MusicBloc>().add(NextTrack());
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
