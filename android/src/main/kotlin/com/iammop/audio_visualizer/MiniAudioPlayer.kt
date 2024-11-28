package com.iammop.audio_visualizer

import android.content.res.AssetFileDescriptor
import android.content.res.AssetManager
import android.media.MediaPlayer
import android.media.audiofx.Visualizer
import android.os.Handler
import android.os.Looper
import java.io.IOException
import java.lang.Exception


enum class AudioStatus {
    UNKNOWN, READY, PLAYING, STOPPED, PAUSED, ERROR
}


interface MiniAudioPlayerCallback {
    fun onWaveformData(playerId: String, data: ByteArray)
    fun onFFTData(playerId: String, data: ByteArray)
    fun onStateChanged(playerId: String)
}

class MiniAudioPlayer(
        val playerId: String,
) {
    var mLoaded: Boolean = false
    var mPosition: Int = 0
    var mDuration: Int = 0
    var mError: Exception? = null
    var mStatus: AudioStatus = AudioStatus.UNKNOWN
    var mPlayer: MediaPlayer = MediaPlayer()
    var mVisualizer: Visualizer? = null
    var mCallback: MiniAudioPlayerCallback? = null

    private fun enableVisualizer() {
        if (mPlayer.audioSessionId < 0) {
            throw IllegalStateException("MediaPlayer not initialized for ID: $playerId")
        }
        mVisualizer = Visualizer(mPlayer.audioSessionId).apply {
            captureSize = Visualizer.getCaptureSizeRange()[1] // Maximum capture size
            setDataCaptureListener(object : Visualizer.OnDataCaptureListener {
                override fun onWaveFormDataCapture(
                        visualizer: Visualizer?,
                        waveform: ByteArray?,
                        samplingRate: Int,
                ) {
                    if (mPlayer.isPlaying) {
                        waveform?.let {
                            mCallback?.onWaveformData(playerId, waveform)
                        }
                    }
                }

                override fun onFftDataCapture(
                        visualizer: Visualizer?,
                        fft: ByteArray?,
                        samplingRate: Int,
                ) {
                    if (mPlayer.isPlaying) {
                        fft?.let {
                            mCallback?.onFFTData(playerId, fft)
                        }
                    }
                }
            }, Visualizer.getMaxCaptureRate() / 2, true, true)
            enabled = true
        }

    }

    private fun disableVisualizer() {
        mVisualizer?.let {
            it.enabled = false
            it.release()
        }
        mVisualizer = null
    }

    fun setCallback(callback: MiniAudioPlayerCallback) {
        mCallback = callback
    }

    fun setDataSource(url: String, assetManager: AssetManager) {
        try {
            reset()

            when {
                url.startsWith("asset://") -> {
                    val assetPath = url.removePrefix("asset://")
                    val afd: AssetFileDescriptor = assetManager.openFd(assetPath)
                    mPlayer.setDataSource(afd.fileDescriptor, afd.startOffset, afd.length)
                    afd.close()
                }

                url.startsWith("file://") -> {
                    mPlayer.setDataSource(url.removePrefix("file://"))
                }

                else -> {
                    mPlayer.setDataSource(url) // HTTP URL
                }
            }

            mPlayer.setOnPreparedListener {
                mLoaded = true
                mPosition = 0
                mDuration = mPlayer.duration
                mStatus = AudioStatus.READY
                notifyStateChange()
            }

            mPlayer.setOnCompletionListener {
                if (mStatus == AudioStatus.PLAYING) {
                    mStatus = AudioStatus.STOPPED
                    mPosition = mPlayer.duration
                    mPlayer.seekTo(0)
                    disableVisualizer()
                    notifyStateChange()
                }
            }

            mPlayer.setOnErrorListener { _, what, extra ->
                mStatus = AudioStatus.ERROR
                mError = IOException("Player error: what=$what, extra=$extra")
                notifyStateChange()
                true
            }

            mPlayer.prepareAsync()

        } catch (e: IOException) {
            Handler(Looper.getMainLooper()).post {
                mStatus = AudioStatus.ERROR
                mError = e
                notifyStateChange()
            }
        }
    }

    fun play(loop: Boolean) {
        if (mStatus == AudioStatus.READY || mStatus == AudioStatus.PAUSED || mStatus == AudioStatus.STOPPED) {
            if (!mPlayer.isPlaying) {
                mPlayer.isLooping = loop
                mPlayer.start()
                mStatus = AudioStatus.PLAYING
                enableVisualizer()
                notifyStateChange()
            }
        }
    }

    fun pause() {
        if (mStatus == AudioStatus.PLAYING) {
            mPlayer.pause()
            mPosition = mPlayer.currentPosition
            mStatus = AudioStatus.PAUSED
            disableVisualizer()
            notifyStateChange()
        }
    }

    fun stop() {
        if (mStatus == AudioStatus.PLAYING || mStatus == AudioStatus.PAUSED) {
            mPlayer.pause()
            mStatus = AudioStatus.STOPPED
            disableVisualizer()
            notifyStateChange()
            mPlayer.seekTo(0)
        }
    }

    fun reset() {
        mPlayer.reset()
        mLoaded = false
        mPosition = 0
        mDuration = 0
        mStatus = AudioStatus.UNKNOWN
        mError = null
        val zeros = ByteArray(1024) { 0 }
        mCallback?.onWaveformData(playerId, zeros)
        mCallback?.onFFTData(playerId, zeros)
        disableVisualizer()
        notifyStateChange()
    }

    fun release() {
        mVisualizer?.release()
        mPlayer.release()
    }

    fun getState(): Map<String, Any> {
        if (mPlayer.isPlaying) {
            mPosition = mPlayer.currentPosition
        }
        return mapOf<String, Any>(
                "playerId" to playerId,
                "status" to mStatus.toString(),
                "loaded" to mLoaded,
                "position" to mPosition,
                "duration" to mDuration,
        )
    }

    private fun notifyStateChange() {
        mCallback?.onStateChanged(playerId)
    }

}