package com.iammop.audio_visualizer;

import androidx.annotation.NonNull;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;


import java.util.Objects;

/**
 * AudioVisualizerPlugin
 */
public class AudioVisualizerPlugin implements FlutterPlugin, MethodCallHandler {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private MethodChannel channel;
    private AudioVisualizer audioVisualizer;

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "audio_visualizer");
        channel.setMethodCallHandler(this);
        audioVisualizer = new AudioVisualizer(channel);
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {

        switch (call.method) {
            case "getPlatformVersion":
                result.success("Android " + android.os.Build.VERSION.RELEASE);
                break;
            case "registerTap":
                int sessionID = (int) Objects.requireNonNull(call.argument("sessionId"));
                registerTap(sessionID);
                break;
            case "deregisterTap":
                deregisterTap();
                break;
            default:
                result.notImplemented();
        }
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
    }

    private void registerTap(int sessionId) {
        if (audioVisualizer.isActive()) return;
        audioVisualizer.registerTap(sessionId);
    }

    private void deregisterTap() {
        audioVisualizer.deregisterTap();
    }
}
