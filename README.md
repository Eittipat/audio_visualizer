# audio_visualizer

This package transforms any integer stream into target frequency bands.
Because this package just do a computation. 
So it should work on any platforms!

## Credit
For ui https://github.com/iamSahdeep/FlutterVisualizers

For frequency bands https://github.com/keijiro/unity-audio-spectrum/blob/master/AudioSpectrum.cs

For sample.pcm https://file-examples-com.github.io/uploads/2017/11/file_example_MP3_700KB.mp3

## Getting Started

You should look at [example](https://github.com/Eittipat/audio_visualizer/blob/master/example). It demostrates bar visualizer from microphone and music (pcm)

![The example app running in Android](https://github.com/Eittipat/audio_visualizer/blob/master/example/demo.gif?raw=true)

```
// Import package
import 'package:audio_visualizer/audio_visualizer.dart';

// Init visualizer
final visualizer = AudioVisualizer(
      windowSize: bufferSize,
      bandType: bandType,
      sampleRate: sampleRate,
      zeroHzScale: 0.05,
      fallSpeed: 0.08,
      sensibility: 8.0,
    );

// Do transform
StreamController<List<double>> audioFFT = ...
final result = visualizer.transform(samples, minRange: 0, maxRange: 255)
audioFFT.add(result)

// Use Stream to build widget
StreamBuilder(
    stream: audioFFT.stream,
    builder: (context, snapshot) {     
        final buffer = snapshot.data as List<double>;
        // render buffer somehow
```


