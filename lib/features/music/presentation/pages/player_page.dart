import 'dart:ui';
import 'package:dxmusic/features/music/presentation/bloc/music_event.dart';
import 'package:dxmusic/features/music/presentation/bloc/music_state.dart';
import 'package:dxmusic/features/music/presentation/widgets/glass_box.dart';
import 'package:dxmusic/features/music/presentation/widgets/premium_title.dart';
import 'package:dxmusic/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../bloc/music_bloc.dart';
import 'package:dxmusic/features/music/presentation/widgets/liquid_background.dart';

class PlayerPage extends StatefulWidget {
  final SongModel song;

  const PlayerPage({super.key, required this.song});

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  // Gesture dynamic physics states
  double _verticalDragOffset = 0.0;
  double _horizontalDragOffset = 0.0;
  bool _isDragging = false;

  // Formats system durations into readable strings (e.g., 03:45)
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MusicBloc, MusicState>(
      buildWhen: (previous, current) =>
          previous.currentSong?.id != current.currentSong?.id ||
          previous.isPlaying != current.isPlaying ||
          previous.isShuffleEnabled != current.isShuffleEnabled ||
          previous.isRepeatEnabled != current.isRepeatEnabled ||
          previous.dominantColor != current.dominantColor ||
          previous.accentColor != current.accentColor,
      builder: (context, state) {
        final currentTrack = state.currentSong ?? widget.song;

        // Dynamic scale and tilt calculation based on drag gestures
        final double totalDrag = _verticalDragOffset.abs() + _horizontalDragOffset.abs();
        final double targetScale = (1.0 - (totalDrag / 1200)).clamp(0.82, 1.0);
        final double targetRotation = (_horizontalDragOffset / 1000).clamp(-0.12, 0.12);

        return GestureDetector(
          onVerticalDragUpdate: (details) {
            setState(() {
              _verticalDragOffset += details.primaryDelta!;
              _isDragging = true;
            });
          },
          onVerticalDragEnd: (details) {
            if (_verticalDragOffset > 140 || details.primaryVelocity! > 280) {
              Navigator.pop(context);
            } else {
              setState(() {
                _verticalDragOffset = 0.0;
                _isDragging = _horizontalDragOffset != 0.0;
              });
            }
          },
          onHorizontalDragUpdate: (details) {
            setState(() {
              _horizontalDragOffset += details.primaryDelta!;
              _isDragging = true;
            });
          },
          onHorizontalDragEnd: (details) {
            if (_horizontalDragOffset > 100 || details.primaryVelocity! > 280) {
              context.read<MusicBloc>().add(PreviousTrack());
            } else if (_horizontalDragOffset < -100 || details.primaryVelocity! < -280) {
              context.read<MusicBloc>().add(NextTrack());
            }
            setState(() {
              _horizontalDragOffset = 0.0;
              _isDragging = _verticalDragOffset != 0.0;
            });
          },
          child: Scaffold(
            body: LiquidBackground(
              dominantColor: state.dominantColor,
              accentColor: state.accentColor,
              child: Stack(
                children: [
                  // Ambient mesh overlay on top of liquid layout
                  Positioned.fill(
                    child: RepaintBoundary(
                      child: Opacity(
                        opacity: 0.12, // Subtle backdrop artwork texture overlay
                        child: state.currentArtworkBytes != null
                            ? Image.memory(
                                state.currentArtworkBytes!,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                gaplessPlayback: true,
                              )
                            : Container(color: Colors.transparent),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: RepaintBoundary(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                        child: Container(color: Colors.transparent),
                      ),
                    ),
                  ),

                  // 2. Main Player Control Hub Layout
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Top Action Row Bar
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  FeatherIcons.chevronDown,
                                  color: Colors.white,
                                  size: 26,
                                ),
                                onPressed: () => Navigator.pop(context),
                              ),
                              Text(
                                "NOW PLAYING",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.4),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2.0,
                                ),
                              ),
                              const SizedBox(
                                width: 48,
                              ),
                            ],
                          ),

                          // Large Premium Artwork Card Frame (Interactive Physical Reaction)
                          Expanded(
                            child: Center(
                              child: AnimatedScale(
                                scale: targetScale,
                                duration: _isDragging ? Duration.zero : const Duration(milliseconds: 350),
                                curve: Curves.easeOutBack,
                                child: AnimatedRotation(
                                  turns: targetRotation / (2 * 3.14159),
                                  duration: _isDragging ? Duration.zero : const Duration(milliseconds: 350),
                                  curve: Curves.easeOutBack,
                                  child: Container(
                                    width: MediaQuery.of(context).size.width * 0.82,
                                    height: MediaQuery.of(context).size.width * 0.82,
                                    decoration: BoxDecoration(
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.55),
                                          blurRadius: 40,
                                          offset: const Offset(0, 20),
                                        ),
                                      ],
                                    ),
                                    child: Hero(
                                      tag: 'artwork_${currentTrack.id}',
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(28),
                                        child: state.currentArtworkBytes != null
                                            ? Image.memory(
                                                state.currentArtworkBytes!,
                                                width: double.infinity,
                                                height: double.infinity,
                                                fit: BoxFit.cover,
                                                gaplessPlayback: true,
                                              )
                                            : GlassBox(
                                                opacity: 0.15,
                                                borderRadius: BorderRadius.circular(28),
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    borderRadius: BorderRadius.circular(28),
                                                    gradient: RadialGradient(
                                                      colors: [
                                                        Colors.white.withOpacity(0.1),
                                                        Colors.transparent,
                                                      ],
                                                    ),
                                                  ),
                                                  child: const Center(
                                                    child: Icon(
                                                      FeatherIcons.disc,
                                                      color: Colors.white54,
                                                      size: 80,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Metadata & Processing Playback Controls wrapped in a Glass Card
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: GlassBox(
                              opacity: 0.04,
                              borderRadius: BorderRadius.circular(28),
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Column(
                                  children: [
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: buildPremiumTitle(currentTrack.title, fontSize: 24, height: 36),
                                    ),
                                    const SizedBox(height: 6),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        currentTrack.displayNameWOExt,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.55),
                                          fontSize: 15,
                                          fontWeight: FontWeight.w400,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 24),

                                    // Slider track
                                    RepaintBoundary(
                                      child: StreamBuilder<Duration>(
                                        stream: globalAudioHandler.positionStream,
                                        builder: (context, snapshot) {
                                          final currentPosition = snapshot.data ?? state.position;
                                          final double positionInMs = currentPosition.inMilliseconds.toDouble();
                                          final double durationInMs = state.duration.inMilliseconds.toDouble();
                                          return SliderTheme(
                                            data: SliderTheme.of(context).copyWith(
                                              trackHeight: 3.5,
                                              activeTrackColor: state.accentColor,
                                              inactiveTrackColor: state.accentColor.withOpacity(0.12),
                                              thumbColor: state.accentColor,
                                              thumbShape: const RoundSliderThumbShape(
                                                enabledThumbRadius: 6,
                                              ),
                                              overlayColor: Colors.white.withOpacity(0.1),
                                              overlayShape: const RoundSliderOverlayShape(
                                                overlayRadius: 14,
                                              ),
                                            ),
                                            child: Slider(
                                              value: positionInMs.clamp(0.0, durationInMs == 0.0 ? 1.0 : durationInMs),
                                              max: durationInMs == 0.0 ? 1.0 : durationInMs,
                                              onChanged: (value) {
                                                context.read<MusicBloc>().add(
                                                      SeekToPosition(
                                                        Duration(milliseconds: value.toInt()),
                                                      ),
                                                    );
                                              },
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 22.0),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          StreamBuilder<Duration>(
                                            stream: globalAudioHandler.positionStream,
                                            builder: (context, snapshot) {
                                              final currentPos = snapshot.data ?? state.position;
                                              return Text(
                                                _formatDuration(currentPos),
                                                style: TextStyle(
                                                  color: Colors.white.withOpacity(0.35),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              );
                                            },
                                          ),
                                          Text(
                                            _formatDuration(state.duration),
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.35),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 20),

                                    // Controls buttons deck
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            FeatherIcons.shuffle,
                                            size: 20,
                                            color: state.isShuffleEnabled ? state.accentColor : Colors.white38,
                                          ),
                                          onPressed: () => context.read<MusicBloc>().add(ToggleShuffle()),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            FeatherIcons.skipBack,
                                            size: 28,
                                            color: Colors.white,
                                          ),
                                          onPressed: () => context.read<MusicBloc>().add(PreviousTrack()),
                                        ),
                                        GestureDetector(
                                          onTap: () => context.read<MusicBloc>().add(TogglePlayPause()),
                                          child: AnimatedScale(
                                            scale: state.isPlaying ? 1.05 : 1.0,
                                            duration: const Duration(milliseconds: 200),
                                            child: Container(
                                              width: 68,
                                              height: 68,
                                              decoration: const BoxDecoration(
                                                color: Colors.white,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Center(
                                                child: Icon(
                                                  state.isPlaying ? FeatherIcons.pause : FeatherIcons.play,
                                                  size: 26,
                                                  color: const Color(0xFF0A0A0C),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            FeatherIcons.skipForward,
                                            size: 28,
                                            color: Colors.white,
                                          ),
                                          onPressed: () => context.read<MusicBloc>().add(NextTrack()),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            FeatherIcons.repeat,
                                            size: 20,
                                            color: state.isRepeatEnabled ? state.accentColor : Colors.white38,
                                          ),
                                          onPressed: () => context.read<MusicBloc>().add(ToggleRepeat()),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
