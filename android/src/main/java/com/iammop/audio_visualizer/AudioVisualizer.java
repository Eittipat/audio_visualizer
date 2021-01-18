package com.iammop.audio_visualizer;

import android.media.audiofx.Visualizer;
import android.os.Build;

import java.util.HashMap;
import java.util.Map;

import io.flutter.plugin.common.MethodChannel;

public class AudioVisualizer implements Visualizer.OnDataCaptureListener {

    private MethodChannel channel;

    public AudioVisualizer(MethodChannel channel) {
        this.channel = channel;
    }

    private Visualizer visualizer;

    public boolean isActive() {
        return visualizer != null;
    }

    public void registerTap(int sessionId) {
        visualizer = new Visualizer(sessionId);
        visualizer.setCaptureSize(Visualizer.getCaptureSizeRange()[1]);
        visualizer.setDataCaptureListener(
                this,
                Visualizer.getMaxCaptureRate() / 2,
                true,
                true
        );
        visualizer.setEnabled(true);
    }

    public void deregisterTap() {
        if(visualizer!=null)
            visualizer.release();

        visualizer = null;
    }

    @Override
    public void onWaveFormDataCapture(Visualizer visualizer, byte[] waveform, int samplingRate) {
        Map<String, Object> args = new HashMap<>();
        args.put("waveform", waveform);
        args.put("samplingRate",samplingRate);
        channel.invokeMethod("onWaveFormDataCapture", args);
    }

    @Override
    public void onFftDataCapture(Visualizer visualizer, byte[] fft, int samplingRate) {
        Map<String, Object> args = new HashMap<>();
        args.put("fft", fft);
        args.put("samplingRate",samplingRate);
        channel.invokeMethod("onFftDataCapture", args);
    }
}
