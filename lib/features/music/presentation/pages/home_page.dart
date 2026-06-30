import 'dart:typed_data';
import 'dart:ui';
import 'package:dxmusic/features/music/presentation/bloc/music_event.dart';
import 'package:dxmusic/features/music/presentation/bloc/music_state.dart';
import 'package:dxmusic/features/music/presentation/bloc/soundcloud_bloc.dart';
import 'package:dxmusic/features/music/presentation/widgets/empty_state.dart';
import 'package:dxmusic/features/music/presentation/widgets/glass_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../bloc/music_bloc.dart';
import '../widgets/mini_player.dart';
import 'player_page.dart';
import 'soundcloud_page.dart'; // Route to your updated keyless streaming page
import '../widgets/liquid_background.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  String _formatListDuration(int milliseconds) {
    if (milliseconds <= 0) return "0:00";
    final duration = Duration(milliseconds: milliseconds);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  // Visual Confirmation Dialog to clean delete a track completely
  void _showDeleteConfirmation(
    BuildContext context,
    int index,
    SongModel song,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF121216),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Wanna delete song?",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        content: Text(
          "This will completely remove \"${song.title}\" from your device storage permanently.",
          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              "Cancel",
              style: TextStyle(color: Colors.white.withOpacity(0.4)),
            ),
          ),
          TextButton(
            onPressed: () {
              context.read<MusicBloc>().add(
                DeleteTrack(index: index, context: context),
              );
              Navigator.pop(dialogContext);
            },
            child: const Text(
              "Delete Wholly",
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MusicBloc, MusicState>(
      buildWhen: (prev, curr) =>
          prev.dominantColor != curr.dominantColor ||
          prev.accentColor != curr.accentColor,
      builder: (context, state) {
        return Scaffold(
          backgroundColor: const Color(0xFF0A0A0C), // Pure Deep Velvet Obsidian
          body: LiquidBackground(
            dominantColor: state.dominantColor,
            accentColor: state.accentColor,
            child: Stack(
              children: [

          SafeArea(
            child: CustomScrollView(
              slivers: [
                // Top Premium Header & Search Field
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "DXMusic",
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            // Apple Music style streaming entry button point
                            IconButton(
                              icon: const Icon(
                                FeatherIcons.cloudLightning,
                                color: Color(0xFFFF5500),
                                size: 26,
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    // Wrap the target page with a fresh scoped SoundCloudBloc provider instance
                                    builder: (context) =>
                                        BlocProvider<SoundCloudBloc>(
                                          create: (context) => SoundCloudBloc(),
                                          child: SoundCloudPage(),
                                        ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        GlassBox(
                          opacity: 0.05,
                          borderRadius: BorderRadius.circular(16),
                          child: TextField(
                            onChanged: (val) => context.read<MusicBloc>().add(
                              FilterSearch(val),
                            ),
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: "Search audio landscape...",
                              hintStyle: TextStyle(
                                color: Colors.white.withOpacity(0.35),
                              ),
                              prefixIcon: Icon(
                                FeatherIcons.search,
                                color: Colors.white.withOpacity(0.5),
                                size: 18,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Main System Song List
                BlocBuilder<MusicBloc, MusicState>(
                  buildWhen: (prev, curr) => 
                    prev.filteredSongs != curr.filteredSongs || 
                    prev.isPermissionDenied != curr.isPermissionDenied,
                  builder: (context, state) {
                    if (state.filteredSongs.isEmpty) {
                      return SliverFillRemaining(
                        child: GlassEmptyState(
                          isPermissionDenied: state.isPermissionDenied,
                        ),
                      );
                    }
                    return SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final song = state.filteredSongs[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                          child: InteractivePressCard(
                            onTap: () =>
                                context.read<MusicBloc>().add(PlayTrack(index)),
                            onLongPress: () =>
                                _showDeleteConfirmation(context, index, song),
                            child: GlassBox(
                              opacity: 0.04,
                              borderRadius: BorderRadius.circular(16),
                              child: ListTile(

                          leading: FutureBuilder<Uint8List?>(
                            future: OnAudioQuery().queryArtwork(
                              song.id,
                              ArtworkType.AUDIO,
                              format: ArtworkFormat.JPEG,
                              size: 150,
                            ),
                            builder: (context, snapshot) {
                              if (snapshot.hasData && snapshot.data != null) {
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.memory(
                                    snapshot.data!,
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                    gaplessPlayback: true,
                                  ),
                                );
                              }

                              return Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  FeatherIcons.music,
                                  color: Colors.white54,
                                  size: 18,
                                ),
                              );
                            },
                          ),

                          title: Text(
                            song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              letterSpacing: 0.2,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              song.displayNameWOExt,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                          // Trailing Container grouping duration text and context options cleanly
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _formatListDuration(song.duration ?? 0),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.3),
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Theme(
                                data: Theme.of(context).copyWith(
                                  popupMenuTheme: const PopupMenuThemeData(
                                    color: Color(0xFF121216),
                                  ),
                                ),
                                child: PopupMenuButton<String>(
                                  icon: Icon(
                                    FeatherIcons.moreVertical,
                                    color: Colors.white.withOpacity(0.4),
                                    size: 18,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  onSelected: (value) {
                                    if (value == 'play_next') {
                                      context.read<MusicBloc>().add(
                                        QueuePlayNext(song),
                                      );
                                    } else if (value == 'add_last') {
                                      context.read<MusicBloc>().add(
                                        QueueAddLast(song),
                                      );
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'play_next',
                                      child: Row(
                                        children: [
                                          Icon(
                                            FeatherIcons.cornerUpRight,
                                            color: Color(0xFFFF5500),
                                            size: 16,
                                          ),
                                          SizedBox(width: 10),
                                          Text(
                                            "Play Next",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'add_last',
                                      child: Row(
                                        children: [
                                          Icon(
                                            FeatherIcons.list,
                                            color: Colors.white60,
                                            size: 16,
                                          ),
                                          SizedBox(width: 10),
                                          Text(
                                            "Add to Queue",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            ),
                          ),
                        ),
                      ),
                    );
                      }, childCount: state.filteredSongs.length),
                    );
                  },
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 110)),
              ],
            ),
          ),

          // Floating Glassmorphic Control Overlay
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: BlocBuilder<MusicBloc, MusicState>(
              buildWhen: (prev, curr) => prev.currentSong != curr.currentSong,
              builder: (context, state) {
                if (state.currentSong == null) return const SizedBox.shrink();

                return GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onVerticalDragEnd: (details) {
                    if (details.primaryVelocity! < -300) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              PlayerPage(song: state.currentSong!),
                        ),
                      );
                    }
                  },
                  onHorizontalDragEnd: (details) {
                    if (details.primaryVelocity! > 300) {
                      // Swipe right -> Previous Track
                      context.read<MusicBloc>().add(PreviousTrack());
                    } else if (details.primaryVelocity! < -300) {
                      // Swipe left -> Next Track
                      context.read<MusicBloc>().add(NextTrack());
                    }
                  },
                  child: const MiniPlayer(),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
      },
    );
  }
}

class InteractivePressCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const InteractivePressCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
  });

  @override
  State<InteractivePressCard> createState() => _InteractivePressCardState();
}

class _InteractivePressCardState extends State<InteractivePressCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: AnimatedScale(
        scale: _isPressed ? 0.965 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}
