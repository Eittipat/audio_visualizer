import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:audio_visualizer/audio_visualizer.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  final AudioVisualizer audioVisualizer = AudioVisualizer();
  final player = AudioPlayer();

  bool isRecording = false;
  bool isPlaying = false;
  StreamSubscription waveformSubscription;
  StreamSubscription fftSubscription;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  @override
  void dispose() {
    audioVisualizer.dispose();
    player.dispose();
    super.dispose();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {

    // permission
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw Exception('Microphone permission not granted');
    }


    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      platformVersion = await audioVisualizer.platformVersion;
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }


  Future<void> play() async {
    var duration = await player.setUrl('https://file-examples-com.github.io/uploads/2017/11/file_example_MP3_700KB.mp3');
    player.play();
    await Future.doWhile(() => player.androidAudioSessionId==null);
    assert(player.androidAudioSessionId!=null);

    audioVisualizer.deregisterTap();
    audioVisualizer.registerTap(player.androidAudioSessionId);
    waveformSubscription?.cancel();
    waveformSubscription = audioVisualizer.waveform.stream.listen((event) {
      print('[WAVE] sampling rate ${event.samplingRate} buffer ${event.buffer?.length ?? 'null'}');
    });

    fftSubscription?.cancel();
    fftSubscription = audioVisualizer.fft.stream.listen((event) {
      print('[FFT] sampling rate ${event.samplingRate} buffer ${event.buffer?.length ?? 'null'}');
    });

    setState(() {
      isPlaying = true;
    });
  }

  Future<void> stop() async {
    await player.stop();
    waveformSubscription?.cancel();
    fftSubscription?.cancel();
    audioVisualizer.deregisterTap();
    setState(() {
      isPlaying = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Text('Running on: $_platformVersion\n'),
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
                  //stopRecord();
                } else {
                  //startRecord();
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
      ),
    );
  }
}
