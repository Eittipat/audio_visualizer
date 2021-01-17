import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:audio_visualizer/audio_visualizer.dart';
import 'package:audio_visualizer/visualizer/visualizer.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Audio Visualizer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Audio Visualizer Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  FlutterSoundRecorder _mRecorder = FlutterSoundRecorder();
  FlutterSoundPlayer _mPlayer = FlutterSoundPlayer();
  bool _mIsInitialized = false;

  String _mPath;
  StreamSubscription _mRecordingDataSubscription;
  StreamSubscription _mPlayingDurationSubscription;
  StreamController<List<double>> audioInput;
  StreamController<Food> rawInput;
  IOSink sink;

  final int sampleRate = 48000;
  bool isRecording = false;
  bool isPlaying = false;

  Future<void> initRecorder() async {
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw RecordingPermissionException('Microphone permission not granted');
    }
    await _mRecorder.openAudioSession();
    await _mPlayer.openAudioSession();
    setState(() {
      _mIsInitialized = true;
      isRecording = false;
      isPlaying = false;
    });
  }

  Future<void> play() async {
    assert(_mIsInitialized);
    await stop();
    var asset = await rootBundle.load(_mPath);
    final buffer = asset.buffer.asUint8List();

    await _mPlayer.startPlayer(
        numChannels: 1,
        codec: Codec.pcm16,
        sampleRate: 44100,
        fromDataBuffer: buffer,
        whenFinished: () {
          setState(() {
            isPlaying = false;
          });
        });

    await _mPlayer.setSubscriptionDuration(Duration(milliseconds: 10));
    _mPlayingDurationSubscription?.cancel();
    await audioInput?.close();
    audioInput = StreamController<List<double>>();
    final v = AudioVisualizer(sampleRate: sampleRate, bandType: BandType.TwentySixBand);
    v.reset();
    // get 1 channel

    print(buffer.length);
    _mPlayingDurationSubscription = _mPlayer.onProgress.listen((e) {
      if (e != null) {
        //print('tick ${e.position.inMilliseconds} ${buffer.length}');
        // feed
        int start = ((e.position.inMilliseconds - 100) * sampleRate / 1000).ceil().clamp(0, buffer.length);
        int end = ((e.position.inMilliseconds + 100) * sampleRate / 1000).ceil().clamp(0, buffer.length);
        //print('index ${start} ${end} ${end - start} ${buffer.length}');
        var data = buffer.sublist(start, end).map((e) => e.toDouble()).toList();
        data = v.transform(data);
        audioInput.add(data);
        setState(() {});
      }
    });

    setState(() {
      isPlaying = true;
    });
    //_mPlayer.foodSink.add(FoodData(buffer));
    //_mPlayer.feedFromStream(buffer);
    //await feedHim(buffer);
  }

  List<int> resampling(List<int> input, int length) {
    final scale = input.length ~/ length;
    final output = List<int>(length);
    for (int i = 0; i < length; i++) {
      int index = i * scale;
      output[i] = input[index];
    }
    return output;
  }

  Future<void> stop() async {
    await _mPlayer.stopPlayer();
    setState(() {
      isPlaying = false;
    });
  }

  Future<void> startRecord() async {
    assert(_mIsInitialized);

    sink?.close();
    sink = await _createFile();
    await rawInput?.close();
    rawInput = StreamController<Food>();
    await audioInput?.close();
    audioInput = StreamController<List<double>>();
    final v = AudioVisualizer(sampleRate: sampleRate, bandType: BandType.TwentySixBand);
    v.reset();
    _mRecordingDataSubscription?.cancel();
    _mRecordingDataSubscription = rawInput.stream.listen(
      (buffer) {
        if (buffer is FoodData) {
          sink.add(buffer.data);
          final data = v.transform(buffer.data.map((e) => e.toDouble()).toList());
          audioInput.add(data);
        }
      },
    );
    await _mRecorder.startRecorder(
      toStream: rawInput.sink,
      codec: Codec.pcm16,
      numChannels: 1,
      sampleRate: sampleRate,
    );
    setState(() {
      isRecording = true;
    });
  }

  Future<void> stopRecord() async {
    await _mRecorder.stopRecorder();
    if (_mRecordingDataSubscription != null) {
      await _mRecordingDataSubscription.cancel();
      _mRecordingDataSubscription = null;
    }
    if (!audioInput?.isClosed) audioInput?.add(List.filled(1024, 0));
    await audioInput?.close();
    await rawInput?.close();
    await sink?.close();
    sink = null;
    rawInput = null;
    audioInput = null;
    setState(() {
      isRecording = false;
    });
  }

  Future<IOSink> _createFile() async {
    _mPath = await _getFilePath();
    var outputFile = File(_mPath);
    if (outputFile.existsSync()) {
      await outputFile.delete();
    }
    return outputFile.openWrite();
  }

  Future<String> _getFilePath() async {
    var tempDir = await getTemporaryDirectory();
    return '${tempDir.path}/flutter_sound_example.pcm';
  }

  @override
  void initState() {
    super.initState();
    initRecorder();
  }

  @override
  void dispose() {
    stopRecord();
    _mRecorder.closeAudioSession();
    _mRecorder = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: 500,
        child: audioInput != null
            ? StreamBuilder(
                stream: audioInput.stream,
                builder: (context, snapshot) {
                  // convert double to int
                  final wave = snapshot.data as List<double> ?? List<double>();

                  return CustomPaint(
                    painter: LineBarVisualizer(
                      waveData: wave,
                      width: MediaQuery.of(context).size.width,
                      height: 500,
                      color: Colors.redAccent,
                      density: wave.length,
                      gap: 4,
                    ),
                    child: new Container(),
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
                stopRecord();
              } else {
                startRecord();
              }
            },
          ),
          SizedBox(height: 10),
          FloatingActionButton(
            // isExtended: true,
            child: Icon(isPlaying ? Icons.stop_rounded : Icons.play_arrow),
            backgroundColor: Colors.amber,
            onPressed: () {
              if (isPlaying) {
                stop();
              } else {
                play();
              }
            },
          ),
        ],
      ),
    );
  }
}
