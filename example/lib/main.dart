import 'package:audio_visualizer/fft.dart';
import 'package:audio_visualizer/visualizers/visualizer.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:convert';
import 'package:audio_visualizer/audio_visualizer.dart';
import 'package:mic_stream/mic_stream.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription _audioSubscription;
  Stream audioStream;
  int sampleRate = 44100;
  IOSink _sink;
  StreamController<List<double>> audioFFT;
  bool isRecording = false;

  @override
  void initState() {
    super.initState();
    init();
  }

  @override
  void dispose() {
    cleanUp();
    super.dispose();
  }

  Future<void> init() async {
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw Exception('Microphone permission not granted');
    }
  }

  Future<void> cleanUp() async {
    await _audioSubscription?.cancel();
    await _sink?.close();
    await audioFFT?.close();
    setState(() {
      audioFFT = null;
      _audioSubscription = null;
      _sink = null;
    });
  }

  Future<IOSink> _createFile() async {
    var tempDir = await getTemporaryDirectory();
    var outputFile = File('${tempDir.path}/sound.pcm');
    if (outputFile.existsSync()) {
      await outputFile.delete();
    }
    return outputFile.openWrite();
  }

  Future<String> _readAsBase64() async {
    var tempDir = await getTemporaryDirectory();
    var inputFile = File('${tempDir.path}/sound.pcm');
    assert(inputFile.existsSync());
    final buffer = await inputFile.readAsBytes();
    return base64.encode(buffer);
  }

  Future<void> stop() async {
    await cleanUp();
    setState(() {
      isRecording = false;
    });
  }

  Future<void> record() async {
    // clean old resource
    await cleanUp();

    // new
    _sink = await _createFile();
    audioStream = await MicStream.microphone(
      audioSource: AudioSource.DEFAULT,
      sampleRate: sampleRate,
      channelConfig: ChannelConfig.CHANNEL_IN_MONO,
      audioFormat: AudioFormat.ENCODING_PCM_16BIT,
    );
    sampleRate = (await MicStream.sampleRate).ceil();
    final visualizer = AudioVisualizer(
      windowSize: await MicStream.bufferSize,
      bandType: BandType.EightBand,
      sampleRate: sampleRate,
      zeroHzScale: 0.0,
    );
    audioFFT = StreamController<List<double>>();
    _audioSubscription = audioStream.listen((buffer) {
      if (buffer != null) {
        final samples = buffer as List<int>;
        _sink.add(samples);
        audioFFT.add(visualizer.transform(samples.map((e) => e.toDouble()).toList()));
      }
    });

    setState(() {
      isRecording = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Audio Visualizer Demo'),
        ),
        body: Center(
          child: audioFFT != null
              ? StreamBuilder(
                  stream: audioFFT.stream,
                  builder: (context, snapshot) {
                    var temp = snapshot.data as List<double>;
                    var wave = List<double>.filled(temp.length, 0, growable: false);
                    if (temp != null) {
                      for (int i = 0; i < temp.length; i++) {
                        var value = temp[i];
                        value = 128 - (50 + (20 * math.log(value) / math.ln10));
                        wave[i] = value;
                      }
                    }
                    return Container(
                      child: CustomPaint(
                        painter: BarVisualizer(
                          waveData: wave.map((e) => e.round()).toList(),
                          width: MediaQuery.of(context).size.width,
                          height: MediaQuery.of(context).size.height,
                          color: Colors.pinkAccent,
                          density: wave.length,
                        ),
                        child: new Container(),
                      ),
                    );
                  },
                )
              : Container(),
        ),
        floatingActionButton: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton(
              // isExtended: true,
              child: Icon(isRecording ? Icons.stop_rounded : Icons.mic_rounded),
              backgroundColor: Colors.red,
              onPressed: () {
                if (isRecording) {
                  stop();
                } else {
                  record();
                }
              },
            ),
            // SizedBox(height: 10),
            // FloatingActionButton(
            //   // isExtended: true,
            //   child: Icon(isPlaying ? Icons.stop_rounded : Icons.play_arrow),
            //   backgroundColor: Colors.amber,
            //   onPressed: () {
            //     if (isPlaying) {
            //       stop();
            //     } else {
            //       play();
            //     }
            //   },
            // ),
          ],
        ),
      ),
    );
  }
}
