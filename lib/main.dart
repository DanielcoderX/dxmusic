import 'package:audio_service/audio_service.dart';
import 'package:dxmusic/features/music/data/sources/audio_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'features/music/presentation/bloc/music_bloc.dart';
import 'features/music/presentation/bloc/music_event.dart';
import 'features/music/presentation/pages/home_page.dart';

late DXAudioHandler globalAudioHandler;
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize the native audio service background engine
  globalAudioHandler = await AudioService.init(
    builder: () => DXAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.dxmusic.channel.audio',
      androidNotificationChannelName: 'DXMusic Playback',
      androidNotificationOngoing: true,
      androidShowNotificationBadge: true,
    ),
  );
  runApp(const DXMusicApp());
}
class DXMusicApp extends StatelessWidget {
  const DXMusicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // Instantiate the audio system BLoC and instantly trigger the media storage scan
      create: (context) => MusicBloc()..add(ScanLibrary()),
      child: MaterialApp(
        title: 'DXMusic',
        debugShowCheckedModeBanner: false,
        
        // Premium Core System Dark Typography & Theme Config
        themeMode: ThemeMode.dark,
        darkTheme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF0A0A0C), // Deep Obsidian
          colorScheme: const ColorScheme.dark(
            primary: Colors.white,
            surface: Color(0xFF121216),
            onSurface: Colors.white,
          ),
          fontFamily: 'Roboto', // Default fallback, matches premium layouts cleanly
        ),
        
        // Lifecycle wrapper component ensuring auto-scans take place seamlessly
        home: const AppLifecycleWatcher(child: HomePage()),
      ),
    );
  }
}

/// A wrapper widget that tracks the Android OS app state lifecycle.
/// Whenever a user downloads music via an external browser and resumes DXMusic,
/// this component fires an automated background scan to refresh the playlist instantly.
class AppLifecycleWatcher extends StatefulWidget {
  final Widget child;
  const AppLifecycleWatcher({super.key, required this.child});

  @override
  State<AppLifecycleWatcher> createState() => _AppLifecycleWatcherState();
}

class _AppLifecycleWatcherState extends State<AppLifecycleWatcher> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When user returns to the app from the background, force clean scan
    if (state == AppLifecycleState.resumed) {
      context.read<MusicBloc>().add(ScanLibrary());
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}