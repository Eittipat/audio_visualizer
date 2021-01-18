import 'dart:async';

import 'package:flutter/services.dart';

class AudioVisualizer  {
  static const MethodChannel _channel = const MethodChannel('audio_visualizer');

  StreamController<AudioData> waveform;
  StreamController<AudioData> fft;

  AudioVisualizer(){
    _channel.setMethodCallHandler((call) {
      switch(call.method) {
        case 'onWaveFormDataCapture':
          final data = AudioData(buffer:call.arguments['waveform'],samplingRate: call.arguments['samplingRate']);
          waveform?.sink?.add(data);
          break;
        case 'onFftDataCapture':
          final data = AudioData(buffer:call.arguments['fft'],samplingRate: call.arguments['samplingRate']);
          fft?.sink?.add(data);
          break;
        default:
          throw UnimplementedError('${call.method} is not implemented!');
      }
      return;
    });
  }

  Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  void registerTap(int sessionId) {
    // renew stream
    waveform?.close();
    fft?.close();
    waveform = StreamController<AudioData>();
    fft = StreamController<AudioData>();

    _channel.invokeMethod("registerTap", {"sessionId": sessionId});
  }

  void deregisterTap() {
    _channel.invokeMethod("deregisterTap");
  }

  void dispose() {
    waveform?.close();
    fft?.close();
    deregisterTap();
  }

}

class AudioData {
  final List<int> buffer;
  final int samplingRate;

  const AudioData({this.buffer,this.samplingRate});
}