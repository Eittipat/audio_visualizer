import 'dart:typed_data';

import 'package:audio_visualizer/fft.dart';
import 'package:audio_visualizer/visualizers/visualizer.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:convert';
import 'package:audio_visualizer/audio_visualizer.dart';
import 'package:flutter/services.dart';
import 'package:mic_stream/mic_stream.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:raw_sound/raw_sound_player.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static const int bufferSize = 2048;
  static const int sampleRate = 44100;

  BandType bandType = BandType.EightBand;

  StreamSubscription _audioSubscription;
  Stream audioStream;

  IOSink _sink;
  StreamController<List<double>> audioFFT;
  bool isRecording = false;
  bool isPlaying = false;
  RawSoundPlayer _player;
  List<int> _sampleAudio;

  @override
  void initState() {
    super.initState();
    init();
  }

  @override
  void dispose() {
    cleanUp();
    _player.release();
    super.dispose();
  }

  Future<void> init() async {
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw Exception('Microphone permission not granted');
    }

    _sampleAudio = (await rootBundle.load('assets/sample.pcm')).buffer.asUint8List().toList();
    _player = RawSoundPlayer();
    await _player.initialize(
      bufferSize: bufferSize,
      nChannels: 1,
      sampleRate: sampleRate,
      pcmType: RawSoundPCMType.PCMI16,
    );
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
    await _player.stop();
    await cleanUp();
    setState(() {
      isRecording = false;
      isPlaying = false;
    });
  }

  Future<void> play() async {
    // clean old resource
    await cleanUp();

    await _player.play();

    setState(() {
      isPlaying = true;
    });

    final visualizer = AudioVisualizer(
      windowSize: bufferSize,
      bandType: bandType,
      sampleRate: sampleRate,
      zeroHzScale: 0.05,
      fallSpeed: 0.08,
      sensibility: 8.0,
    );

    audioFFT = StreamController<List<double>>();
    int offset = 0;
    int index = 0;
    while (_player.isPlaying) {
      final block = _sampleAudio.sublist(offset, offset + bufferSize);
      final promise = _player.feed(Uint8List.fromList(block));
      audioFFT.add(visualizer.transform(block));
      await promise;
      offset += bufferSize;
      index++;
    }
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
    final visualizer = AudioVisualizer(
      windowSize: bufferSize,
      bandType: bandType,
      sampleRate: sampleRate,
      zeroHzScale: 0.05,
      fallSpeed: 0.08,
      sensibility: 8.0,
    );
    audioFFT = StreamController<List<double>>();
    _audioSubscription = audioStream.listen((buffer) {
      if (buffer != null) {
        final samples = buffer as List<int>;
        _sink.add(samples);
        audioFFT.add(visualizer.transform(samples, minRange: 0, maxRange: 255));
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
        body: Container(
          child: Column(
            children: [
              Container(
                child: DropdownButton(
                  isExpanded: true,
                  value: bandType,
                  itemHeight: 75,
                  onChanged: (value) async {
                    bandType = value;
                    if (isPlaying) {
                      await stop();
                      await play();
                      return;
                    }

                    if (isRecording) {
                      await stop();
                      await record();
                    }
                  },
                  items: BandType.values
                      .map(
                        (e) => DropdownMenuItem(
                          value: e,
                          child: Container(
                            padding: const EdgeInsets.only(left: 25),
                            child: Text(e.toString()),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              Expanded(
                child: Center(
                  child: StreamBuilder(
                    stream: audioFFT?.stream ?? null,
                    builder: (context, snapshot) {
                      if (snapshot.data == null) return Container();

                      final buffer = snapshot.data as List<double>;
                      final wave = buffer.map((e) => e-0.25).toList();

                      return Container(
                        child: CustomPaint(
                          painter: BarVisualizer(
                            waveData: wave,
                            color: Colors.pinkAccent,
                            density: wave.length,
                            gap: 2,
                          ),
                          child: new Container(),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
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
            SizedBox(height: 10),
            FloatingActionButton(
              // isExtended: true,
              child: Icon(isPlaying ? Icons.stop_rounded : Icons.music_note),
              backgroundColor: Colors.blue,
              onPressed: () async {
                if (!isPlaying) {
                  await play();
                } else {
                  await stop();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
