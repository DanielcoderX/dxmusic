# DXMusic 🌌

DXMusic is a premium, high-fidelity music player for Android featuring an Apple-inspired **Liquid Glassmorphism** interface. It blends dynamic ambient gradients, frosted glass panels, and touch-interactive physics gestures into a luxurious mobile audio landscape.

---

## 🎨 Design Philosophy & Aesthetics

DXMusic is crafted to deliver a visually stunning, responsive, and tactile listening experience:
* **Interactive Liquid Backdrops**: Powered by a custom real-time particle shader simulation. Three ambient colored orbs drift, morph, and gravitate dynamically toward your touch coordinates, swelling organically (125%) on press events.
* **Frosted Glass Panels**: Custom-engineered card trays using advanced multi-layered blurring and a looping 12-second diagonal border light-refraction sweep.
* **Physics-Based Gesture Dynamics**: Dragging or swiping on the player pages causes the artwork cards to scale down and tilt dynamically in the drag direction, springing back to position.
* **Haptic Micro-Animations**: Buttons and list cards scale down subtly to 96.5% during touch, producing responsive, physical-feeling feedback.

---

## 🚀 Key Features

* **Offline Library Scanning**: Automatically scans your device's audio files, resolves artwork metadata, and formats details cleanly.
* **Cloud Search & Stream**: Integrated SoundCloud client to search, stream keyless, and download tracks straight to your offline library with live circular download progress notifications.
* **Premium Audio Engine**: Backed by `just_audio` and standard platform integrations to handle background service audio lifecycle events seamlessly.
* **Dynamic Color Matching**: Extracting primary and accent colors from song artwork to color-shift the liquid background dynamically on track changes.

---

## 🛠 Tech Stack

* **Framework**: Flutter (Dart)
* **State Management**: flutter_bloc (BLoC Pattern)
* **Audio Pipeline**: just_audio & audio_service (for native lock-screen controls and background processes)
* **UI & Interactions**: Custom Glassmorphism shaders, FeatherIcons, and physics transform nodes.

---

## 📦 Getting Started

### Prerequisites
* Flutter SDK (v3.9.2 or higher)
* Android Studio / Gradle configurations set up

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/DanielcoderX/dxmusic.git
   ```
2. Navigate to directory:
   ```bash
   cd dxmusic
   ```
3. Fetch dependencies:
   ```bash
   flutter pub get
   ```
4. Run the application:
   ```bash
   flutter run --release
   ```

---

## 🤝 Contributing
Feel free to open issues or submit pull requests to enhance the liquid glass engine, add visualization presets, or improve cloud streaming features.
