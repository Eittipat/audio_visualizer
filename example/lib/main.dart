import 'dart:async';
import 'dart:io';

import 'package:audio_visualizer/fft.dart';
import 'package:audio_visualizer/visualizers/visualizers.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:audio_visualizer/audio_visualizer.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final pcmVisualizer = PCMVisualizer();
  final audioPlayer = VisualizerPlayer();
  final record = AudioRecorder();
  bool isRecording = false;
  StreamSubscription? _micData;

  @override
  void initState() {
    super.initState();
    setup();
  }

  void setup() async {
    pcmVisualizer.reset();
    await audioPlayer.initialize();
  }

  @override
  void dispose() {
    _micData?.cancel();
    pcmVisualizer.dispose();
    audioPlayer.dispose();
    super.dispose();
  }

  AudioVisualizer get source {
    return isRecording ? pcmVisualizer : audioPlayer;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Center(child: Text('Audio Visualizer')),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isRecording ? Colors.deepOrangeAccent : null,
                    ),
                    onPressed: () async {
                      if (await record.isRecording()) {
                        _micData?.cancel();
                        record.stop();
                        setState(() {
                          isRecording = false;
                        });
                        return;
                      }
                      final stream = await record.startStream(
                        const RecordConfig(
                          encoder: AudioEncoder.pcm16bits,
                          autoGain: true,
                          echoCancel: true,
                          noiseSuppress: true,
                          sampleRate: 44100,
                          numChannels: 1,
                        ),
                      );
                      _micData = stream.listen((data) {
                        pcmVisualizer.feed(data);
                      });
                      setState(() {
                        isRecording = true;
                      });
                    },
                    child: const Text('Mic'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      audioPlayer.setDataSource(
                        "https://files.testfile.org/AUDIO/C/M4A/sample1.m4a",
                      );
                    },
                    child: const Text('HTTP'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final path = await downloadFile(
                        "https://files.testfile.org/anime.mp3",
                        "anime.mp3",
                      );
                      audioPlayer.setDataSource("file://$path");
                    },
                    child: const Text('File'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      audioPlayer.setDataSource(
                        "asset://assets/sample.mp3",
                      );
                    },
                    child: const Text('Asset'),
                  ),
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      audioPlayer.play();
                    },
                    child: const Icon(Icons.play_arrow),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      audioPlayer.pause();
                    },
                    child: const Icon(Icons.pause),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      audioPlayer.stop();
                    },
                    child: const Icon(Icons.stop),
                  ),
                ],
              ),
              ListenableBuilder(
                listenable: audioPlayer,
                builder: (context, child) {
                  final value = audioPlayer.value;
                  return Text(
                    "Status: ${value.status} (${value.position}/${value.duration})",
                  );
                },
              ),
              Expanded(
                child: GridView(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  shrinkWrap: true,
                  children: [
                    const Center(child: Text("Wave")),
                    const Center(child: Text("Frequency")),
                    VisualizerBuilder(
                      controller: source,
                      builder: (context, value, child) {
                        return BarVisualizer(
                          input: value.amplitudes,
                          backgroundColor: Colors.black,
                          color: Colors.greenAccent,
                          gap: 2,
                        );
                      },
                    ),
                    VisualizerBuilder(
                      controller: source,
                      builder: (context, value, child) {
                        return BarVisualizer(
                          input: value.levels,
                          color: Colors.yellow,
                          backgroundColor: Colors.black,
                          gap: 2,
                        );
                      },
                    ),
                    VisualizerBuilder(
                      controller: source,
                      builder: (context, value, child) {
                        return Container(
                          color: Colors.black,
                          child: CustomPaint(
                            painter: CircularBarVisualizer(
                              color: Colors.greenAccent,
                              data: value.amplitudes,
                              gap: 2,
                            ),
                          ),
                        );
                      },
                    ),
                    VisualizerBuilder(
                      controller: source,
                      builder: (context, value, child) {
                        final buffer = value.magnitudes.sublist(
                          0,
                          math.min(value.magnitudes.length, 128),
                        );
                        return Container(
                          color: Colors.black,
                          child: CustomPaint(
                            painter: CircularBarVisualizer(
                              color: Colors.yellow,
                              data: buffer,
                              gap: 2,
                            ),
                          ),
                        );
                      },
                    ),
                    VisualizerBuilder(
                      controller: source,
                      builder: (context, value, child) {
                        return Container(
                          color: Colors.black,
                          child: CustomPaint(
                            painter: MultiWaveVisualizer(
                              color: Colors.greenAccent,
                              data: value.amplitudes,
                            ),
                          ),
                        );
                      },
                    ),
                    VisualizerBuilder(
                      controller: source,
                      builder: (context, value, child) {
                        return Container(
                          color: Colors.black,
                          child: CustomPaint(
                            painter: MultiWaveVisualizer(
                              color: Colors.yellow,
                              data: value.magnitudes,
                            ),
                          ),
                        );
                      },
                    ),
                    VisualizerBuilder(
                      controller: source,
                      builder: (context, value, child) {
                        return Container(
                          color: Colors.black,
                          child: CustomPaint(
                            painter: LineBarVisualizer(
                              color: Colors.greenAccent,
                              data: value.amplitudes,
                            ),
                          ),
                        );
                      },
                    ),
                    VisualizerBuilder(
                      controller: source,
                      builder: (context, value, child) {
                        final buffer = value.magnitudes.sublist(
                          0,
                          math.min(value.magnitudes.length, 128),
                        );
                        return Container(
                          color: Colors.black,
                          child: CustomPaint(
                            painter: LineBarVisualizer(
                              color: Colors.yellow,
                              data: buffer,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<String> downloadFile(String url, String filename) async {
  // Make HTTP request with streaming
  final response =
      await http.Client().send(http.Request('GET', Uri.parse(url)));

  if (response.statusCode != 200) {
    throw Exception('Failed to download file: ${response.statusCode}');
  }
  final directory = await getTemporaryDirectory();
  final filePath = '${directory.path}/$filename';
  final file = File(filePath);

  // Create file and write chunks
  final sink = file.openWrite();
  await response.stream.forEach((chunk) {
    sink.add(chunk);
  });

  await sink.close();
  return filePath;
}
