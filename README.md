
# 🎵 Audio Visualizer

A Flutter package for seamlessly visualizing audio from files, assets, HTTP streams, microphone input, and raw PCM16 data.

---

## ✨ Features

| Feature                | Android | iOS |
|------------------------|---------|-----|
| Visualize File         | ✅      | ✅  |
| Visualize Asset        | ✅      | ✅  |
| Visualize HTTP         | ✅      | ✅  |
| Visualize Microphone   | ✅      | ✅  |
| Visualize Raw PCM16    | ✅      | ✅  |

---

## 📦 Components Overview

This package provides three major components:

1. **VisualizerPlayer**  
   For visualizing audio from files, assets, and HTTP streams.

2. **PCMVisualizer**  
   For visualizing raw PCM16 data from custom sources.

3. **VisualizerBuilder**  
   A widget to build and customize visualizers.

---

## 🚀 Visualizer Styles and Bands

### Pre-built Visualizer Styles

- **BarVisualizer**  
  Displays audio levels as vertical bars.
- **CircleVisualizer**  
  Represents audio levels in a circular design.
- **LineVisualizer**  
  Shows levels as a line graph.
- **MultiWaveVisualizer**  
  Displays levels as multi-layered waves.

### Band Types

Choose from six band types to suit your visualization needs:

- `fourBand`
- `fourBandVisual`
- `eightBand`
- `tenBand`
- `twentySixBand`
- `thirtyOneBand`

---

## 🎧 How to Use

### Visualizing an Audio File

Load audio using the appropriate prefix:

- **Assets:** `asset://path_to_asset`
- **Files:** `file://path_to_file`
- **HTTP:** `http://url` or `https://url`

Example:

```dart
// Initialize VisualizerPlayer
final audioPlayer = VisualizerPlayer();
await audioPlayer.initialize();
await audioPlayer.setDataSource("asset://assets/sample.mp3");
await audioPlayer.play();

// Visualize with BarVisualizer
VisualizerBuilder(
  controller: audioPlayer,
  builder: (context, value, child) {
    return BarVisualizer(
      input: value.levels,
      color: Colors.yellow,
      backgroundColor: Colors.black,
      gap: 2,
    );
  },
);

// Dispose VisualizerPlayer
audioPlayer.dispose();
```

---

### Visualizing Microphone Input

This package does not directly handle microphone input. You can use the [record](https://pub.dev/packages/record) package to capture audio and feed it into the visualizer.

Example:

```dart
// Initialize PCMVisualizer
final pcmVisualizer = PCMVisualizer();
pcmVisualizer.feed(rawPCM16Data);

// Visualize with BarVisualizer
VisualizerBuilder(
  controller: pcmVisualizer,
  builder: (context, value, child) {
    return BarVisualizer(
      input: value.levels,
      color: Colors.yellow,
      backgroundColor: Colors.black,
      gap: 2,
    );
  },
);

// Dispose PCMVisualizer
pcmVisualizer.dispose();
```

---

### 📚 Examples

Explore additional examples in the [examples directory](https://github.com/Eittipat/audio_visualizer/blob/master/example).

![Demo App on Android](https://github.com/Eittipat/audio_visualizer/blob/master/example/demo.gif?raw=true)

---

## ⚙️ Permissions

On Android, the following permission is required to visualize audio:

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
```

---

## 🙏 Acknowledgements

This project is inspired by and leverages ideas and code from the following:

- [Flutter Visualizers](https://github.com/iamSahdeep/FlutterVisualizers)
- [Unity Audio Spectrum](https://github.com/keijiro/unity-audio-spectrum)
- [Android Open Source](https://android.googlesource.com)

---

