package com.iammop.audio_visualizer

import android.content.Context
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.IOException


class AudioVisualizerPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private lateinit var assetManager: FlutterPlugin.FlutterAssets

    // Map to manage multiple MediaPlayer and Visualizer instances
    private val sessions = mutableMapOf<String, MiniAudioPlayer>()


    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "audio_visualizer")
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
        assetManager = flutterPluginBinding.flutterAssets
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        val playerId = call.argument<String>("playerId")
                ?: return result.error("INVALID_ARGUMENT", "playerId is required", null)

        when (call.method) {
            "initialize" -> {
                initialize(playerId, result)
            }

            "setDataSource" -> {
                val url = call.argument<String>("url") ?: ""
                setDataSource(playerId, url, result)
            }

            "play" -> {
                val loop = call.argument<Boolean>("loop") ?: false
                play(playerId, loop, result)
            }

            "pause" -> {
                pause(playerId, result)
            }

            "stop" -> {
                stop(playerId, result)
            }

            "reset" -> {
                reset(playerId, result)
            }

            "release" -> {
                release(playerId, result)
            }

            "getState" -> {
                getState(playerId, result)
            }

            else -> {
                result.notImplemented()
            }
        }
    }


    private fun initialize(playerId: String, result: Result) {
        if (!sessions.containsKey(playerId)) {
            sessions[playerId] = MiniAudioPlayer(playerId)
            sessions[playerId]?.setCallback(object : MiniAudioPlayerCallback {
                override fun onWaveformData(playerId: String, data: ByteArray) {
                    channel.invokeMethod("onWaveformChanged", mapOf("playerId" to playerId, "waveform" to data))
                }

                override fun onFFTData(playerId: String, data: ByteArray) {
                    channel.invokeMethod("onFFTChanged", mapOf("playerId" to playerId, "fft" to data))
                }

                override fun onStateChanged(playerId: String) {
                    channel.invokeMethod("onStateChanged", mapOf("playerId" to playerId))
                }

            })
            result.success(null)
        } else {
            result.error("PLAYER_ALREADY_INITIALIZED", "Player already initialized for ID: $playerId", null)
        }
    }

    private fun setDataSource(playerId: String, url: String, result: Result) {
        if (sessions.containsKey(playerId)) {
            try {
                var newUrl = url
                if (url.startsWith("asset://")) {
                    val assetPath = url.removePrefix("asset://")
                    val filePath: String = assetManager.getAssetFilePathByName(assetPath)
                    newUrl = "asset://$filePath"
                }
                val session = sessions[playerId]!!
                session.setDataSource(newUrl, context.assets)
                result.success(null)
            } catch (e: IOException) {
                result.error("AUDIO_LOAD_ERROR", "Failed to load audio", e.message)
            }
        } else {
            result.error("PLAYER_NOT_INITIALIZED", "Player not initialized for ID: $playerId", null)
        }
    }

    private fun play(playerId: String, loop: Boolean, result: Result) {
        if (sessions.containsKey(playerId)) {
            val session = sessions[playerId]!!
            session.play(loop)
            result.success(null)
        } else {
            result.error("PLAYER_NOT_INITIALIZED", "Player not initialized for ID: $playerId", null)
        }

    }

    private fun pause(playerId: String, result: Result) {
        if (sessions.containsKey(playerId)) {
            val session = sessions[playerId]!!
            session.pause()
            result.success(null)
        } else {
            result.error("PLAYER_NOT_INITIALIZED", "Player not initialized for ID: $playerId", null)
        }
    }

    private fun stop(playerId: String, result: Result) {
        if (sessions.containsKey(playerId)) {
            val session = sessions[playerId]!!
            session.stop()
            result.success(null)
        } else {
            result.error("PLAYER_NOT_INITIALIZED", "Player not initialized for ID: $playerId", null)
        }
    }

    private fun reset(playerId: String, result: Result) {
        if (sessions.containsKey(playerId)) {
            val session = sessions[playerId]!!
            session.reset()
            result.success(null)
        } else {
            result.error("PLAYER_NOT_INITIALIZED", "Player not initialized for ID: $playerId", null)
        }
    }

    private fun release(playerId: String, result: Result) {
        if (sessions.containsKey(playerId)) {
            val session = sessions[playerId]!!
            session.release()
            sessions.remove(playerId)
            result.success(null)
        } else {
            result.error("PLAYER_NOT_INITIALIZED", "Player not initialized for ID: $playerId", null)
        }
    }

    private fun getState(playerId: String, result: Result) {
        if (sessions.containsKey(playerId)) {
            val session = sessions[playerId]!!
            result.success(session.getState())
        } else {
            result.error("PLAYER_NOT_INITIALIZED", "Player not initialized for ID: $playerId", null)
        }
    }

}