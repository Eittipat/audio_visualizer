// import 'package:flutter_test/flutter_test.dart';
// import 'package:audio_visualizer/audio_visualizer.dart';
// import 'package:audio_visualizer/audio_visualizer_platform_interface.dart';
// import 'package:audio_visualizer/audio_visualizer_method_channel.dart';
// import 'package:plugin_platform_interface/plugin_platform_interface.dart';
//
// class MockAudioVisualizerPlatform
//     with MockPlatformInterfaceMixin
//     implements AudioVisualizerPlatform {
//
//   @override
//   Future<String?> getPlatformVersion() => Future.value('42');
// }
//
// void main() {
//   final AudioVisualizerPlatform initialPlatform = AudioVisualizerPlatform.instance;
//
//   test('$MethodChannelAudioVisualizer is the default instance', () {
//     expect(initialPlatform, isInstanceOf<MethodChannelAudioVisualizer>());
//   });
//
//   test('getPlatformVersion', () async {
//     AudioVisualizer audioVisualizerPlugin = AudioVisualizer();
//     MockAudioVisualizerPlatform fakePlatform = MockAudioVisualizerPlatform();
//     AudioVisualizerPlatform.instance = fakePlatform;
//
//     expect(await audioVisualizerPlugin.getPlatformVersion(), '42');
//   });
// }
