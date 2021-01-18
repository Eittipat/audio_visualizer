#import "AudioVisualizerPlugin.h"
#if __has_include(<audio_visualizer/audio_visualizer-Swift.h>)
#import <audio_visualizer/audio_visualizer-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "audio_visualizer-Swift.h"
#endif

@implementation AudioVisualizerPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftAudioVisualizerPlugin registerWithRegistrar:registrar];
}
@end
