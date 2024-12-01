import AVFoundation
import Flutter


public class AudioVisualizerPlugin: NSObject, FlutterPlugin {
    
    private var sessions = [String:MiniAudioPlayer]()
    private var channel: FlutterMethodChannel?
    private static var registrar: FlutterPluginRegistrar?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "audio_visualizer", binaryMessenger: registrar.messenger())
        let instance = AudioVisualizerPlugin()
        instance.channel = channel
        AudioVisualizerPlugin.registrar = registrar
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    func initializePlayer(playerId: String,result: @escaping FlutterResult) {
        if sessions[playerId] != nil {
            result(FlutterError(
                code: "PLAYER_ALREADY_INITIALIZED",
                message: "Player already initialized for \(playerId)",
                details: nil
            ))
            return
        }
        sessions[playerId] = MiniAudioPlayer(playerId:playerId)
        sessions[playerId]?.onFFTData = { [weak self] id, fftData in
            DispatchQueue.main.async {
                self?.channel?.invokeMethod(
                    "onFFTChanged",
                    arguments:[
                        "playerId": id,
                        "fft": fftData,
                    ]
                )
            }
        }
        sessions[playerId]?.onWaveformData = { [weak self] id, waveData in
            DispatchQueue.main.async {
                self?.channel?.invokeMethod(
                    "onWaveformChanged",
                    arguments:[
                        "playerId": id,
                        "waveform": waveData,
                    ]
                )
            }
        }
        sessions[playerId]?.onStateChanged = { [weak self] in
            DispatchQueue.main.async {
                self?.channel?.invokeMethod("onStateChanged", arguments:[
                    "playerId": playerId
                ])
            }
        }
        result(nil)
    }

    func setDataSource(playerId: String, url: String, result: @escaping FlutterResult) {
        guard let session = sessions[playerId] else {
            result(FlutterError(
                code: "PLAYER_NOT_INITIALIZED",
                message: "Player or audio engine not initialized for player ID: \(playerId)",
                details: nil
            ))
            return
        }
        
        var inputUrl = url
        if url.hasPrefix("asset://") {
            let assetPath = String(url.dropFirst("asset://".count))
            let key = AudioVisualizerPlugin.registrar!.lookupKey(forAsset: assetPath)
            inputUrl = "asset://\(key)"
        }
        session.setDataSource(url: inputUrl)
        result(nil)
    }

    func play(playerId: String, looping:Bool,result: @escaping FlutterResult) {
        guard let session = sessions[playerId] else {
            result(FlutterError(
                code: "PLAYER_NOT_INITIALIZED",
                message: "Player or audio engine not initialized for player ID: \(playerId)",
                details: nil
            ))
            return
        }
        session.play(looping: looping)
        result(nil)
    }
    
    func pause(playerId: String, result: @escaping FlutterResult) {
        guard let session = sessions[playerId] else {
            result(FlutterError(
                code: "PLAYER_NOT_INITIALIZED",
                message: "Player or audio engine not initialized for player ID: \(playerId)",
                details: nil
            ))
            return
        }
        session.pause()
        result(nil)
    }

    func stop(playerId: String, result: @escaping FlutterResult) {
        guard let session = sessions[playerId] else {
            result(FlutterError(
                code: "PLAYER_NOT_INITIALIZED",
                message: "Player or audio engine not initialized for player ID: \(playerId)",
                details: nil
            ))
            return
        }
        session.stop()
        result(nil)
    }

    func reset(playerId: String, result: @escaping FlutterResult) {
        guard let session = sessions[playerId] else {
            result(FlutterError(
                code: "PLAYER_NOT_INITIALIZED",
                message: "Player or audio engine not initialized for player ID: \(playerId)",
                details: nil
            ))
            return
        }
        session.reset()
        result(nil)
    }

    func release(playerId: String, result: @escaping FlutterResult) {
        if let session = sessions[playerId] {
            session.release()
            sessions.removeValue(forKey: playerId)
        }
        result(nil)
    }

    func getState(playerId: String, result: @escaping FlutterResult) {
        guard let session = sessions[playerId] else {
            result(FlutterError(
                code: "PLAYER_NOT_INITIALIZED",
                message: "Player or audio engine not initialized for player ID: \(playerId)",
                details: nil
            ))
            return
        }
    
        result(session.getState())
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any]
        let playerId = args?["playerId"] as? String ?? ""

        switch call.method {
        case "initialize":
            initializePlayer(playerId: playerId, result: result)
        case "setDataSource":
            let url = args?["url"] as? String ?? ""
            setDataSource(playerId: playerId, url: url, result: result)
        case "play":
            let looping = args?["looping"] as? Bool ?? false
            play(playerId: playerId, looping:looping, result: result)
        case "pause":
            pause(playerId: playerId, result: result)
        case "stop":
            stop(playerId: playerId, result: result)
        case "reset":
            reset(playerId: playerId, result: result)
        case "release":
            release(playerId: playerId, result: result)
        case "getState":
            getState(playerId: playerId, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
