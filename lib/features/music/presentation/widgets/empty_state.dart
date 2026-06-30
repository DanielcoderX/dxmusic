import 'package:dxmusic/features/music/presentation/widgets/glass_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import '../bloc/music_bloc.dart';
import '../bloc/music_event.dart';

class GlassEmptyState extends StatelessWidget {
  final bool isPermissionDenied;

  const GlassEmptyState({super.key, this.isPermissionDenied = false});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: GlassBox(
          blur: 20,
          opacity: 0.06,
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Minimal glowing icon circle
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Icon(
                    isPermissionDenied ? FeatherIcons.shieldOff : FeatherIcons.disc,
                    color: const Color(0xFF5F5CFF),
                    size: 32,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  isPermissionDenied ? "Access Required" : "Audio Desert",
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.5),
                ),
                const SizedBox(height: 12),
                Text(
                  isPermissionDenied
                      ? "DXMusic needs access to your local media files to curate your sonic landscape."
                      : "We couldn't identify any compatible audio tracks matching your device storage landscape.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 14, height: 1.4),
                ),
                const SizedBox(height: 28),
                // Premium Glass Button Action
                GestureDetector(
                  onTap: () => context.read<MusicBloc>().add(ScanLibrary()),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFF5F5CFF).withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 8)),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        isPermissionDenied ? "Grant Permission" : "Initialize Scan",
                        style: const TextStyle(color: Color(0xFF0A0A0C), fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}