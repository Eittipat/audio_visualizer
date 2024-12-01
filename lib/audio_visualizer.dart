import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:audio_visualizer/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'fft.dart';

const kUpdateInterval = Duration(milliseconds: 250);

enum PlayerStatus {
  unknown,
  ready,
  playing,
  paused,
  stopped,
  error,
}

class VisualizerPlayerValue extends AudioVisualizerValue {
  final PlayerStatus status;
  final bool initialized;
  final bool loaded;
  final Duration position;
  final Duration duration;
  final Exception? exception;

  VisualizerPlayerValue({
    super.waveform = const [],
    super.fft = const [],
    this.initialized = false,
    this.status = PlayerStatus.unknown,
    this.loaded = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.exception,
  });

  @override
  VisualizerPlayerValue copyWith({
    List<int>? waveform,
    List<int>? fft,
    PlayerStatus? status,
    bool? initialized,
    bool? loaded,
    Duration? position,
    Duration? duration,
    Exception? exception,
  }) {
    return VisualizerPlayerValue(
      waveform: waveform ?? this.waveform,
      fft: fft ?? this.fft,
      status: status ?? this.status,
      initialized: initialized ?? this.initialized,
      loaded: loaded ?? this.loaded,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      exception: exception ?? this.exception,
    );
  }
}

class VisualizerPlayer extends ChangeNotifier implements AudioVisualizer {
  static const MethodChannel _channel = MethodChannel('audio_visualizer');
  static int _idCounter = 0; // Static counter to generate unique player IDs

  final String playerId;
  Timer? _timer;

  VisualizerPlayerValue _value = VisualizerPlayerValue();

  VisualizerPlayer() : playerId = "player_${_idCounter++}" {
    _channel.setMethodCallHandler(
      _handleNativeCallback,
    );
  }

  @override
  VisualizerPlayerValue get value => _value;

  Future<void> initialize() async {
    await _channel.invokeMethod('initialize', {"playerId": playerId});
    _value = _value.copyWith(initialized: true);
    notifyListeners();
  }

  Future<void> setDataSource(String url) async {
    try {
      await _channel.invokeMethod('setDataSource', {
        "playerId": playerId,
        "url": url,
      });
    } catch (e) {
      throw Exception("Failed to set data source: $e");
    }
  }

  Future<void> play({bool looping = false}) async {
    try {
      await _channel.invokeMethod('play', {
        "playerId": playerId,
        "looping": looping,
      });
      _timer?.cancel();
      _timer = Timer.periodic(kUpdateInterval, (timer) {
        _updateState();
      });
    } catch (e) {
      throw Exception("Failed to play audio: $e");
    }
  }

  Future<void> pause() async {
    try {
      await _channel.invokeMethod('pause', {"playerId": playerId});
    } catch (e) {
      throw Exception("Failed to pause audio: $e");
    }
  }

  Future<void> stop() async {
    try {
      await _channel.invokeMethod('stop', {"playerId": playerId});
      _timer?.cancel();
    } catch (e) {
      throw Exception("Failed to stop audio: $e");
    }
  }

  Future<void> reset() async {
    try {
      await _channel.invokeMethod('reset', {"playerId": playerId});
      _timer?.cancel();
    } catch (e) {
      throw Exception("Failed to reset audio: $e");
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _channel.invokeMethod('release', {"playerId": playerId});
    super.dispose();
  }

  // Native callback handler
  Future<void> _handleNativeCallback(MethodCall call) async {
    var model = _value;
    var shouldUpdate = false;
    if (call.method == "onWaveformChanged") {
      final String receivedPlayerId = call.arguments["playerId"];
      if (receivedPlayerId == playerId) {
        // Filter by playerId
        final buffer = call.arguments["waveform"] as List<dynamic>;
        final waveform = List<int>.from(buffer.map((e) => e).toList());
        model = model.copyWith(waveform: waveform);
        shouldUpdate = true;
      }
    } else if (call.method == "onFFTChanged") {
      final String receivedPlayerId = call.arguments["playerId"];
      if (receivedPlayerId == playerId) {
        // Filter by playerId
        final buffer = call.arguments["fft"] as List<dynamic>;
        final data = List<int>.from(buffer.map((e) => int8(e as int))).toList();
        model = model.copyWith(fft: data);
        shouldUpdate = true;
      }
    } else if (call.method == "onStateChanged") {
      final String receivedPlayerId = call.arguments["playerId"];
      if (receivedPlayerId == playerId) {
        shouldUpdate = true;
      }
    }
    if (shouldUpdate) {
      _value = model;
      _updateState();
    }
  }

  Future<void> _updateState() async {
    try {
      final Map result = await _channel.invokeMethod(
        'getState',
        {"playerId": playerId},
      );
      final int duration = result["duration"];
      final int position = result["position"];
      final bool loaded = result["loaded"];
      late final PlayerStatus status;
      switch (result["status"].toLowerCase()) {
        case "ready":
          status = PlayerStatus.ready;
          break;
        case "playing":
          status = PlayerStatus.playing;
          break;
        case "paused":
          status = PlayerStatus.paused;
          break;
        case "stopped":
          status = PlayerStatus.stopped;
          break;
        case "error":
          status = PlayerStatus.error;
          break;
        default:
          status = PlayerStatus.unknown;
          break;
      }
      _value = _value.copyWith(
        status: status,
        duration: Duration(milliseconds: duration),
        position: Duration(milliseconds: position),
        loaded: loaded,
      );
      notifyListeners();
    } catch (e) {
      throw Exception("Failed to reset audio: $e");
    }
  }
}

class AudioVisualizerValue {
  /// A list of integers representing the waveform data.
  /// This list contains the amplitude values of the audio signal in the range [0, 255].
  final List<int> waveform;

  /// A list of integers representing the FFT (Fast Fourier Transform) data.
  /// This list contains the frequency domain representation of the audio signal in the range [-128, 127].
  final List<int> fft;

  AudioVisualizerValue({
    this.waveform = const [],
    this.fft = const [],
  });

  AudioVisualizerValue copyWith({
    List<int>? waveform,
    List<int>? fft,
  }) {
    return AudioVisualizerValue(
      waveform: waveform ?? this.waveform,
      fft: fft ?? this.fft,
    );
  }
}

class PCMVisualizer extends ChangeNotifier implements AudioVisualizer {
  AudioVisualizerValue _value = AudioVisualizerValue();

  @override
  AudioVisualizerValue get value => _value;

  void reset() {
    _value = _value.copyWith(
      fft: List<int>.filled(1024, 0),
      waveform: List<int>.filled(1024, 0),
    );
    notifyListeners();
  }

  void feed(Uint8List data) {
    final byteData = data.buffer.asByteData();
    final data16 = Int16List.view(
      byteData.buffer,
      byteData.offsetInBytes,
      data.length ~/ 2,
    );

    final input = List<int>.filled(1024, 0);
    final fft = List<int>.filled(min(1024, data.length), 0);
    for (int i = 0; i < min(1024, data.length); i++) {
      // int16 to uint8
      final u8 = scale(data16[i], -32768, 32767, 0, 255).round();
      input[i] = u8;
    }
    doFft(fft, input);
    final output = List<int>.from(fft.map((e) => int8(e)));
    _value = _value.copyWith(
      fft: output,
      waveform: input,
    );
    notifyListeners();
  }
}

abstract class AudioVisualizer implements ChangeNotifier {
  AudioVisualizerValue get value;
}
