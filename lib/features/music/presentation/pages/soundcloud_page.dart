import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import '../bloc/soundcloud_bloc.dart';
import '../bloc/music_bloc.dart';
import '../bloc/music_event.dart';
import '../bloc/music_state.dart';
import '../widgets/glass_box.dart';
import '../widgets/liquid_background.dart';

class SoundCloudPage extends StatelessWidget {
  final TextEditingController _urlController = TextEditingController();

  SoundCloudPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MusicBloc, MusicState>(
      builder: (context, musicState) {
        return Scaffold(
          backgroundColor: const Color(0xFF0A0A0C), // Pure Deep Velvet Obsidian
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text(
              "Cloud Search & Stream",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
            leading: IconButton(
              icon: const Icon(FeatherIcons.chevronLeft, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          extendBodyBehindAppBar: true,
          body: LiquidBackground(
            dominantColor: musicState.dominantColor,
            accentColor: musicState.accentColor,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    // Apple-style minimalist glass search bar field container
                    GlassBox(
                      opacity: 0.05,
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: TextField(
                          controller: _urlController,
                          style: const TextStyle(color: Colors.white),
                          onSubmitted: (value) {
                            if (value.isNotEmpty) {
                              context.read<SoundCloudBloc>().add(LoadSoundCloudContent(value));
                            }
                          },
                          decoration: InputDecoration(
                            icon: const Icon(FeatherIcons.search, color: Colors.white38, size: 20),
                            hintText: "Search tracks or paste SoundCloud link...",
                            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                            border: InputBorder.none,
                            suffixIcon: IconButton(
                              icon: const Icon(FeatherIcons.arrowRight, color: Color(0xFFFF5500)),
                              onPressed: () {
                                if (_urlController.text.isNotEmpty) {
                                  context.read<SoundCloudBloc>().add(LoadSoundCloudContent(_urlController.text));
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Rendered Track Grid / List Layout
                    Expanded(
                      child: BlocConsumer<SoundCloudBloc, SoundCloudState>(
                        listener: (context, state) {
                          if (state is SoundCloudDownloadSuccess) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Saved straight to offline library!"),
                                backgroundColor: Color(0xFF5F5CFF),
                              ),
                            );
                            // Instantly sweeps your off-line folder to update HomePage UI list frames
                            context.read<MusicBloc>().add(ScanLibrary());
                          }
                        },
                        builder: (context, state) {
                          if (state is SoundCloudLoading) {
                            return const Center(child: CircularProgressIndicator(color: Color(0xFFFF5500)));
                          }
                          
                          if (state is SoundCloudLoaded) {
                            return ListView.builder(
                              itemCount: state.tracks.length,
                              itemBuilder: (context, index) {
                                final track = state.tracks[index];
                                
                                // Safely resolve nullable Uri to clean String format
                                final String? artworkStringUrl = track.artworkUrl?.toString();

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12.0),
                                  child: GlassBox(
                                    opacity: 0.04,
                                    borderRadius: BorderRadius.circular(16),
                                    child: ListTile(
                                      leading: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: (artworkStringUrl != null && artworkStringUrl.isNotEmpty)
                                            ? Image.network(
                                                artworkStringUrl,
                                                width: 48,
                                                height: 48,
                                                fit: BoxFit.cover,
                                                errorBuilder: (c, e, s) => const Icon(FeatherIcons.music),
                                              )
                                            : Container(
                                                color: Colors.white10,
                                                width: 48,
                                                height: 48,
                                                child: const Icon(FeatherIcons.music),
                                              ),
                                      ),
                                      title: Text(
                                        track.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                      ),
                                      subtitle: Text(
                                        track.user.username,
                                        style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
                                      ),
                                      trailing: Builder(
                                        builder: (context) {
                                          final isDownloading = state.downloadProgress.containsKey(track.id);
                                          if (isDownloading) {
                                            final progress = state.downloadProgress[track.id] ?? 0.0;
                                            return SizedBox(
                                              width: 40,
                                              height: 40,
                                              child: Stack(
                                                alignment: Alignment.center,
                                                children: [
                                                  CircularProgressIndicator(
                                                    value: progress.clamp(0.0, 1.0),
                                                    strokeWidth: 2,
                                                    color: const Color(0xFFFF5500),
                                                    backgroundColor: Colors.white10,
                                                  ),
                                                  Text(
                                                    "${(progress * 100).toInt()}",
                                                    style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }
                                          return IconButton(
                                            icon: const Icon(FeatherIcons.downloadCloud, color: Color(0xFFFF5500)),
                                            onPressed: () {
                                              context.read<SoundCloudBloc>().add(DownloadExplodedTrack(track));
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          }

                          if (state is SoundCloudError) {
                            return Center(child: Text(state.message, style: const TextStyle(color: Colors.redAccent)));
                          }

                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(FeatherIcons.search, size: 40, color: Colors.white.withOpacity(0.2)),
                                const SizedBox(height: 12),
                                Text(
                                  "Search for tracks or paste a public link\nto download offline music cleanly.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white.withOpacity(0.4), height: 1.4),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
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