import 'dart:math';

import 'package:audio_visualizer/audio_visualizer.dart';
import 'package:audio_visualizer/utils.dart';
import 'package:audio_visualizer/visualizers/audio_spectrum.dart';
import 'package:audio_visualizer/visualizers/visualizers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(MaterialApp(
    themeMode: ThemeMode.dark,
    darkTheme: ThemeData.dark(useMaterial3: true),
    home: const MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() {
    return _MyAppState();
  }
}

class _MyAppState extends State<MyApp> {
  final audioPlayer = VisualizerPlayer();

  final sources = [
    "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3",
    "https://files.testfile.org/AUDIO/C/M4A/sample1.m4a",
  ];
  var sourceIndex = 0;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    audioPlayer.initialize();
    audioPlayer.setDataSource(sources[sourceIndex]);
    audioPlayer.addListener(onUpdate);
  }

  void onUpdate() {
    if (audioPlayer.value.status == PlayerStatus.ready) {
      audioPlayer.play(looping: true);
    }
  }

  @override
  void dispose() {
    audioPlayer.removeListener(onUpdate);
    audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(
          child: Text('Audio Visualizer'),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ListenableBuilder(
              listenable: audioPlayer,
              builder: (context, child) {
                final duration = audioPlayer.value.duration;
                final position = audioPlayer.value.position;
                final durationText = formatDuration(duration);
                final positionText = formatDuration(position);
                return Text(
                  "$positionText / $durationText",
                  style: Theme.of(context).textTheme.headlineLarge,
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ListenableBuilder(
              listenable: audioPlayer,
              builder: (context, child) {
                return Text(
                  audioPlayer.value.status == PlayerStatus.playing
                      ? "Now Playing"
                      : "",
                  style: Theme.of(context).textTheme.bodyLarge,
                );
              },
            ),
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: audioPlayer,
              builder: (context, child) {
                final data = getMagnitudes(audioPlayer.value.fft);
                return AudioSpectrum(
                  fftMagnitudes: data,
                  bandType: BandType.tenBand,
                  builder: (context, value, child) {
                    return RainbowBlockVisualizer(
                      data: value.levels,
                      maxSample: 32,
                      blockHeight: 14,
                    );
                  },
                );
              },
            ),
          ),
          ListenableBuilder(
            listenable: audioPlayer,
            builder: (context, child) {
              final duration = audioPlayer.value.duration.inMilliseconds;
              final position = audioPlayer.value.position.inMilliseconds;
              return LinearProgressIndicator(
                value: position / max(1, duration),
                minHeight: 8,
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: const Icon(Icons.play_arrow),
              onPressed: () {
                audioPlayer.play(looping: true);
              },
            ),
            IconButton(
              icon: const Icon(Icons.pause),
              onPressed: () {
                audioPlayer.pause();
              },
            ),
            IconButton(
              icon: const Icon(Icons.stop),
              onPressed: () {
                audioPlayer.stop();
              },
            ),
            IconButton(
              icon: const Icon(Icons.loop),
              onPressed: () {
                sourceIndex = (sourceIndex + 1) % sources.length;
                audioPlayer.stop();
                audioPlayer.setDataSource(sources[sourceIndex]);
              },
            ),
          ],
        ),
      ),
    );
  }
}

String formatDuration(Duration duration) {
  final minutes = duration.inMinutes;
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return "$minutes:$seconds";
}
