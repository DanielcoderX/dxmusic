package github.danielcoderx.dxmusic // Ensure this matches your actual package name line

import io.flutter.embedding.android.FlutterActivity
import com.ryanheise.audioservice.AudioServiceActivity

class MainActivity: AudioServiceActivity() {
    // This allows audio_service to seamlessly capture and handle the background engine hook
}