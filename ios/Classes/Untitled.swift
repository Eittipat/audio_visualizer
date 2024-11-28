////
////  Untitled.swift
////  Pods
////
////  Created by Eittipat Kraichingrith on 9/11/2567 BE.
////
//
//import AVFoundation
//import Flutter
//
//
//private enum AudioStatus: String {
//    case unknown
//    case playing
//    case stopped
//    case paused
//    case error
//}
//
//enum AudioError: Error {
//    case runtimeError(code:String,message: String, detail:String)
//}
//
//private class AudioSession {
//    
//    private var playerId: String
//    private var channel: FlutterMethodChannel
//    private var registrar: FlutterPluginRegistrar
//    private var mAudioEngine: AVAudioEngine
//    private var mPlayerNode: AVAudioPlayerNode
//    private var mStatus: AudioStatus
//    private var mLoaded: Bool
//    private var mPosition: Int
//    private var mDuration: Int
//    
//    init(playerId:String, channel: FlutterMethodChannel, registrar: FlutterPluginRegistrar) {
//        self.playerId = playerId
//        self.channel = channel
//        self.registrar = registrar
//        
//        let engine = AVAudioEngine()
//        let playerNode = AVAudioPlayerNode()
//        self.mAudioEngine = engine
//        self.mPlayerNode = playerNode
//        self.mStatus = .unknown
//        self.mLoaded = false
//        self.mPosition = 0
//        self.mDuration = 0
//        
//        engine.attach(playerNode)
//        engine.connect(playerNode, to: engine.mainMixerNode, format: nil)
//    }
//    
//    func enableVisualizer() {
//        self.mAudioEngine.mainMixerNode.removeTap(onBus: 0)
//        self.mAudioEngine.inputNode.installTap(onBus: 0, bufferSize: 1024, format: nil, block: { buffer, _ in
//            guard let channelData = buffer.floatChannelData else { return }
//            
//            let frameLength = min(1024, buffer.frameLength)
//            let channelCount = Int(buffer.format.channelCount)
//            var combinedWaveform = [Float](repeating: 0.0, count: Int(frameLength))
//            
//            for channel in 0..<channelCount {
//                let channelSamples = channelData[channel]
//                for frame in 0..<Int(frameLength) {
//                    combinedWaveform[frame] += abs(channelSamples[frame])
//                }
//            }
//            
//            combinedWaveform = combinedWaveform.map { $0 / Float(channelCount) }
//            var input = _toUInt8(combinedWaveform)
//            var output = [UInt8](repeating: 0, count: combinedWaveform.count)
//            doFft(fft:&output, waveform: &input)
//            DispatchQueue.main.async {
//                self.channel.invokeMethod(
//                    "onWaveformChanged",
//                    arguments:[
//                        "playerId": self.playerId,
//                        "waveform": input,
//                    ]
//                )
//                self.channel.invokeMethod(
//                    "onFFTChanged",
//                    arguments:[
//                        "playerId": self.playerId,
//                        "fft": output,
//                    ]
//                )
//            }
//        })
//    }
//    
//    func disableVisualizer() {
//        self.mAudioEngine.mainMixerNode.removeTap(onBus: 0)
//    }
//    
//    func setDataSource(url: String) {
//        
//    }
//    
//    func play(loop: Bool) throws {
//        enableVisualizer()
//        try self.mAudioEngine.start()
//        self.mPlayerNode.play()
//        self.mStatus = .playing
//    }
//    
//    func pause() {
//        self.mPlayerNode.pause()
//        self.mStatus = .paused
//        disableVisualizer()
//        notifyStateChanged()
//    }
//    
//    func stop() {
//        self.mPlayerNode.stop()
//        self.mAudioEngine.stop()
//        self.mStatus = .stopped
//    }
//    
//    func reset() {
//        self.mAudioEngine.reset()
//        self.mPlayerNode.reset()
//        self.mLoaded = false
//        self.mPosition = 0
//        self.mDuration = 0
//        self.mStatus = .stopped
//        disableVisualizer()
//        notifyStateChanged()
//    }
//    
//    func release() {
//
//    }
//    
//    func getState() {
//        
//    }
//    
//    func notifyStateChanged() {
//        
//    }
//}
//
//public class AudioVisualizerPlugin: NSObject, FlutterPlugin {
//    
//    private var sessions = [String:AudioSession]()
//    private var channel: FlutterMethodChannel?
//    private static var registrar: FlutterPluginRegistrar?
//
//    public static func register(with registrar: FlutterPluginRegistrar) {
//        let channel = FlutterMethodChannel(name: "audio_visualizer", binaryMessenger: registrar.messenger())
//        let instance = AudioVisualizerPlugin()
//        instance.channel = channel
//        AudioVisualizerPlugin.registrar = registrar
//        registrar.addMethodCallDelegate(instance, channel: channel)
//    }
//
//    func initializePlayer(playerId: String) {
//        sessions[playerId] = AudioSession(playerId:playerId,
//                                          channel: channel!,
//                                          registrar: AudioVisualizerPlugin.registrar!
//        )
//    }
//
//    func setDataSource(playerId: String, url: String, result: @escaping FlutterResult) {
//        guard let engine = audioEngines[playerId], let playerNode = playerNodes[playerId] else {
//            result(FlutterError(code: "PLAYER_NOT_INITIALIZED", message: "Player not initialized for player ID: \(playerId)", details: nil))
//            return
//        }
//
//        if url.hasPrefix("asset://") {
//            let assetPath = String(url.dropFirst("asset://".count))
//            loadAssetFile(playerId: playerId, assetPath: assetPath, result: result)
//        } else if url.hasPrefix("file://") {
//            let localPath = String(url.dropFirst("file://".count))
//            loadLocalFile(playerId: playerId, localPath: localPath, result: result)
//        } else {
//            loadRemoteFile(playerId: playerId, remoteUrl: url, result: result)
//        }
//    }
//
//    private func loadAssetFile(playerId: String, assetPath: String, result: @escaping FlutterResult) {
//        guard let registrar = AudioVisualizerPlugin.registrar else {
//            result(FlutterError(code: "REGISTRAR_NOT_FOUND", message: "FlutterPluginRegistrar not found", details: nil))
//            return
//        }
//
//        let key = registrar.lookupKey(forAsset: assetPath)
//        if let assetUrl = Bundle.main.path(forResource: key, ofType: nil) {
//            do {
//                let audioFile = try AVAudioFile(forReading: URL(fileURLWithPath: assetUrl))
//                prepareAndScheduleAudio(playerId: playerId, audioFile: audioFile, result: result)
//            } catch {
//                result(FlutterError(code: "ASSET_LOAD_ERROR", message: "Failed to load asset file", details: error.localizedDescription))
//            }
//        } else {
//            result(FlutterError(code: "ASSET_NOT_FOUND", message: "Asset not found at path \(assetPath)", details: nil))
//        }
//    }
//
//    private func loadLocalFile(playerId: String, localPath: String, result: @escaping FlutterResult) {
//        let localUrl = URL(fileURLWithPath: localPath)
//        do {
//            let audioFile = try AVAudioFile(forReading: localUrl)
//            prepareAndScheduleAudio(playerId: playerId, audioFile: audioFile, result: result)
//        } catch {
//            result(FlutterError(code: "AUDIO_LOAD_ERROR", message: "Failed to load local audio file", details: error.localizedDescription))
//        }
//    }
//
//    private func loadRemoteFile(playerId: String, remoteUrl: String, result: @escaping FlutterResult) {
//        guard let audioUrl = URL(string: remoteUrl) else {
//            result(FlutterError(code: "INVALID_URL", message: "The provided URL is invalid", details: remoteUrl))
//            return
//        }
//
//        let session = URLSession.shared
//        let task = session.dataTask(with: audioUrl) { data, response, error in
//            if let error = error {
//                result(FlutterError(code: "AUDIO_LOAD_ERROR", message: "Failed to load audio from URL", details: error.localizedDescription))
//                return
//            }
//
//            guard let data = data else {
//                result(FlutterError(code: "AUDIO_LOAD_ERROR", message: "No audio data found at URL", details: nil))
//                return
//            }
//
//            do {
//                let audioFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)
//                let audioBuffer = try self.createAudioBuffer(from: data, format: audioFormat!, playerId: playerId, url: audioUrl)
//                self.prepareAndScheduleBuffer(playerId: playerId, audioBuffer: audioBuffer, result: result)
//            } catch {
//                result(FlutterError(code: "AUDIO_BUFFER_ERROR", message: "Failed to create audio buffer", details: error.localizedDescription))
//            }
//        }
//        
//        task.resume()
//    }
//
//    private func createAudioBuffer(from data: Data, format: AVAudioFormat, playerId: String, url: URL) throws -> AVAudioPCMBuffer {
//        let fileExtension = url.pathExtension.isEmpty ? "m4a" : url.pathExtension
//        let tempUrl = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("temp_\(playerId).\(fileExtension)")
//        
//        try data.write(to: tempUrl)
//
//        let audioFile = try AVAudioFile(forReading: tempUrl)
//        let frameCount = AVAudioFrameCount(audioFile.length)
//        guard let buffer = AVAudioPCMBuffer(pcmFormat: audioFile.processingFormat, frameCapacity: frameCount) else {
//            throw NSError(domain: "AudioVisualizerPlugin", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to create audio buffer."])
//        }
//        
//        try audioFile.read(into: buffer)
//        return buffer
//    }
//
//    private func prepareAndScheduleAudio(playerId: String, audioFile: AVAudioFile, result: @escaping FlutterResult) {
//        guard let engine = audioEngines[playerId], let playerNode = playerNodes[playerId] else { return }
//        
//        engine.prepare()
//        playerNode.scheduleFile(audioFile, at: nil) {
//            self.status[playerId] = .stopped
//            DispatchQueue.main.async {
//                self.channel?.invokeMethod("onPlaybackComplete", arguments: ["playerId": playerId])
//            }
//        }
//        isAudioSourceSet[playerId] = true
//        result(nil)
//    }
//
//    private func prepareAndScheduleBuffer(playerId: String, audioBuffer: AVAudioPCMBuffer, result: @escaping FlutterResult) {
//        guard let engine = audioEngines[playerId], let playerNode = playerNodes[playerId] else { return }
//
//        engine.prepare()
//        playerNode.scheduleBuffer(audioBuffer, at: nil, options: .loops) {
//            self.status[playerId] = .stopped
//            DispatchQueue.main.async {
//                self.channel?.invokeMethod("onPlaybackComplete", arguments: ["playerId": playerId])
//            }
//        }
//        isAudioSourceSet[playerId] = true
//        result(nil)
//    }
//
//    func play(playerId: String, result: @escaping FlutterResult) {
//        guard let engine = audioEngines[playerId], let playerNode = playerNodes[playerId] else {
//            result(FlutterError(code: "PLAYER_NOT_INITIALIZED", message: "Player or audio engine not initialized for player ID: \(playerId)", details: nil))
//            return
//        }
//
//        guard isAudioSourceSet[playerId] == true else {
//            result(FlutterError(code: "AUDIO_SOURCE_NOT_SET", message: "Audio source not set for player ID: \(playerId)", details: nil))
//            return
//        }
//
//        engine.mainMixerNode.removeTap(onBus: 0)
//        
//        engine.mainMixerNode.installTap(onBus: 0, bufferSize: 1024, format: nil) { buffer, _ in
//            guard let channelData = buffer.floatChannelData else { return }
//            
//            let frameLength = min(1024, buffer.frameLength)
//            let channelCount = Int(buffer.format.channelCount)
//            var combinedWaveform = [Float](repeating: 0.0, count: Int(frameLength))
//            
//            for channel in 0..<channelCount {
//                let channelSamples = channelData[channel]
//                for frame in 0..<Int(frameLength) {
//                    combinedWaveform[frame] += abs(channelSamples[frame])
//                }
//            }
//            
//            combinedWaveform = combinedWaveform.map { $0 / Float(channelCount) }
//            var input = _toUInt8(combinedWaveform)
//            var output = [UInt8](repeating: 0, count: combinedWaveform.count)
//            doFft(fft:&output, waveform: &input)
//            DispatchQueue.main.async {
//                self.channel?.invokeMethod(
//                    "onWaveformChanged",
//                    arguments:[
//                        "playerId": playerId,
//                        "waveform": input,
//                    ]
//                )
//                self.channel?.invokeMethod(
//                    "onFFTChanged",
//                    arguments:[
//                        "playerId": playerId,
//                        "fft": output,
//                    ]
//                )
//            }
//        }
//
//        do {
//            try engine.start()
//            playerNode.play()
//            status[playerId] = .playing
//            result(nil)
//        } catch {
//            result(FlutterError(code: "ENGINE_START_ERROR", message: "Failed to start AVAudioEngine", details: error.localizedDescription))
//        }
//    }
//    
//    func pause(playerId: String, result: @escaping FlutterResult) {
//        guard let playerNode = playerNodes[playerId] else {
//            result(FlutterError(code: "PLAYER_NOT_INITIALIZED", message: "Player not initialized for player ID: \(playerId)", details: nil))
//            return
//        }
//
//        playerNode.pause()
//        status[playerId] = .paused
//        result(nil)
//    }
//
//    func stop(playerId: String, result: @escaping FlutterResult) {
//        guard let engine = audioEngines[playerId], let playerNode = playerNodes[playerId] else {
//            result(FlutterError(code: "PLAYER_NOT_INITIALIZED", message: "Player not initialized for player ID: \(playerId)", details: nil))
//            return
//        }
//
//        playerNode.stop()
//        engine.mainMixerNode.removeTap(onBus: 0)
//        engine.stop()
//        status[playerId] = .stopped
//        result(nil)
//    }
//
//    func reset(playerId: String, result: @escaping FlutterResult) {
//        guard let playerNode = playerNodes[playerId] else {
//            result(FlutterError(code: "PLAYER_NOT_INITIALIZED", message: "Player not initialized for player ID: \(playerId)", details: nil))
//            return
//        }
//        
//        playerNode.stop()
//        status[playerId] = .stopped
//        isAudioSourceSet[playerId] = false
//        result(nil)
//    }
//
//    func release(playerId: String) {
//        stop(playerId: playerId) { _ in }
//
//        audioEngines.removeValue(forKey: playerId)
//        playerNodes.removeValue(forKey: playerId)
//        isAudioSourceSet.removeValue(forKey: playerId)
//        status.removeValue(forKey: playerId)
//    }
//
//    func getStatus(playerId: String, result: @escaping FlutterResult) {
//        if let playerStatus = status[playerId] {
//            result(playerStatus.rawValue)
//        } else {
//            result(AudioStatus.unknown.rawValue)
//        }
//    }
//
//    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
//        let args = call.arguments as? [String: Any]
//        let playerId = args?["playerId"] as? String ?? ""
//
//        switch call.method {
//        case "initialize":
//            initializePlayer(playerId: playerId)
//            result(nil)
//        case "setDataSource":
//            let url = args?["url"] as? String ?? ""
//            setDataSource(playerId: playerId, url: url, result: result)
//        case "play":
//            play(playerId: playerId, result: result)
//        case "pause":
//            pause(playerId: playerId, result: result)
//        case "stop":
//            stop(playerId: playerId, result: result)
//        case "reset":
//            reset(playerId: playerId, result: result)
//        case "release":
//            release(playerId: playerId)
//            result(nil)
//        case "getStatus":
//            getStatus(playerId: playerId, result: result)
//        default:
//            result(FlutterMethodNotImplemented)
//        }
//    }
//}
//
//func _toUInt8(_ input: [Float]) -> [UInt8] {
//    return input.map { value in
//        // Scale the double value to the UInt8 range (0 to 255)
//        return UInt8(max(0, min(value * 255, 255)))
//    }
//}
//
//func _toFloat32(_ input: [UInt8]) -> [Float] {
//    return input.map { value in
//        return Float(value) / 255
//    }
//}
//
//func doFft(fft:inout[UInt8], waveform:inout [UInt8]) {
//    let input = _toCArray(&waveform)
//    let output = _toCArray(&fft)
//    AndroidFFT.do(output, input, UInt32(truncatingIfNeeded: waveform.count))
//}
//
//func _toCArray(_ input: inout[UInt8]) -> UnsafeMutablePointer<UInt8> {
//    return input.withUnsafeMutableBytes { bufferPointer in
//        return bufferPointer.baseAddress!.assumingMemoryBound(to: UInt8.self)
//    }
//}
