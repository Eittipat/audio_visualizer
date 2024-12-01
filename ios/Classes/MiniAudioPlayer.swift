//
//  MiniAudioPlayer.swift
//  Pods
//
//  Created by Eittipat K on 14/11/2567 BE.
//
import AVFoundation

class MiniAudioPlayer {
    
    private var mPlayerId: String
    private var mAudioEngine: AVAudioEngine
    private var mPlayerNode: AVAudioPlayerNode
    private var mStatus: AudioStatus
    private var mLoaded: Bool
    private var mLooping: Bool
    private var mPosition: Int
    private var mDuration: Int
    private var mError: Error?
    private var mSamplingRate: Double
    private var mAVAudioFile: AVAudioFile?
    
    var onWaveformData: ((String,[UInt8]) -> Void)?
    
    var onFFTData: ((String,[UInt8]) -> Void)?
    
    var onStateChanged: (() -> Void)?
    
    init(playerId: String) {
        self.mPlayerId = playerId
        self.mAudioEngine = AVAudioEngine()
        self.mPlayerNode = AVAudioPlayerNode()
        self.mStatus = .unknown
        self.mLoaded = false
        self.mLooping = false
        self.mPosition = 0
        self.mDuration = 0
        self.mError = nil
        self.mSamplingRate = 44100.0
        self.mAVAudioFile = nil
        
        self.mAudioEngine.attach(self.mPlayerNode)
        self.mAudioEngine.connect(self.mPlayerNode, to: self.mAudioEngine.mainMixerNode, format: nil)
    }
    
    
    private func loadAssetFile(assetPath: String, completion:@escaping (Result<AVAudioFile, Error>) -> Void) {
        if let assetUrl = Bundle.main.path(forResource: assetPath, ofType: nil) {
            do {
                let audioFile = try AVAudioFile(forReading: URL(fileURLWithPath: assetUrl))
                completion(.success(audioFile))
            } catch {
                completion(.failure(error))
            }
        } else {
            let error = AudioError.runtimeError(code: "ASSET_NOT_FOUND", message: "Asset not found at path \(assetPath)", details: nil)
            completion(.failure(error))
        }
    }

    private func loadLocalFile(localPath: String,completion: @escaping (Result<AVAudioFile, Error>) -> Void) {
        let localUrl = URL(fileURLWithPath: localPath)
        do {
            let audioFile = try AVAudioFile(forReading: localUrl)
            completion(.success(audioFile))
        } catch {
            completion(.failure(error))
        }
    }
    
    private func loadRemoteFile(url: String, completion: @escaping (Result<AVAudioFile, Error>) -> Void)  {
        guard let audioUrl = URL(string: url) else {
            let error = AudioError.runtimeError(code: "INVALID_URL", message: "Invalid URL", details: nil)
            completion(.failure(error))
            return
        }
        let session = URLSession.shared
        let task = session.dataTask(with: audioUrl) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                let audioError =  AudioError.runtimeError(
                    code: "AUDIO_LOAD_ERROR",
                    message: "Failed to load audio from URL",
                    details: error.localizedDescription
                )
                completion(.failure(audioError))
                return
            }
            
            guard let data = data else {
                let audioError =  AudioError.runtimeError(
                    code: "AUDIO_LOAD_ERROR",
                    message: "No audio data found at URL",
                    details: nil
                )
                completion(.failure(audioError))
                return
            }
            
            do {
                let fileExtension = audioUrl.pathExtension.isEmpty ? "m4a" : audioUrl.pathExtension
                let tempUrl = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("temp_\(self.mPlayerId).\(fileExtension)")
                try data.write(to: tempUrl)
                let audioFile = try AVAudioFile(forReading: tempUrl)
                completion(.success(audioFile))
            } catch {
                let audioError = AudioError.runtimeError(
                    code: "AUDIO_PROCESSING_ERROR",
                    message: "Failed to process audio data",
                    details: error.localizedDescription
                )
                completion(.failure(audioError))
            }
        }
        
        task.resume()
    }
    
    func setDataSource(url:String) {
        // reset
        self.reset()
    
        let onAssetCallback: (Result<AVAudioFile, Error>) -> Void = { result in
            switch result {
            case .success(let data):
                self.mLoaded = true
                self.mStatus = .ready
                self.mAVAudioFile = data
                self.prepareAndScheduleAudio()
                self.notifyStateChanged()
            case .failure(let error):
                self.mError = error
                self.mStatus = .error
                self.notifyStateChanged()
            }
        }
        
        if url.hasPrefix("asset://") {
            let assetPath = String(url.dropFirst("asset://".count))
            self.loadAssetFile(assetPath: assetPath, completion: onAssetCallback)
        } else if url.hasPrefix("file://") {
            let localPath = String(url.dropFirst("file://".count))
            self.loadLocalFile(localPath: localPath, completion: onAssetCallback)
        } else {
            self.loadRemoteFile(url:url, completion: onAssetCallback)
        }
        
        // start audio engine
        if(self.mAudioEngine.isRunning==false) {
            do {
                try self.mAudioEngine.start()
            } catch {
                self.mStatus = .error
                self.mError = error
                self.notifyStateChanged()
            }
        }
    }
    
    func play(looping: Bool) {
        if(self.mStatus == .ready || self.mStatus == .paused || self.mStatus == .stopped) {
            if(self.mStatus == .stopped) {
                self.prepareAndScheduleAudio()
            }
            self.enableVisualizer()
            self.mLooping = looping
            self.mPlayerNode.play()
            self.mStatus = .playing
            self.notifyStateChanged()
        }
    }
    
    func pause() {
        if(self.mStatus == .playing) {
            self.mPlayerNode.pause()
            self.mStatus = .paused
            self.disableVisualizer()
            self.notifyStateChanged()
        }
    }
    
    func stop() {
        if(self.mStatus == .playing || self.mStatus == .paused) {
            self.mPlayerNode.stop()
            self.mStatus = .stopped
            self.disableVisualizer()
            self.notifyStateChanged()
        }
    }
    
    func reset() {
        self.mPlayerNode.stop()
        self.mPlayerNode.reset()
        self.disableVisualizer()
        self.mStatus = .unknown
        self.mLoaded = false
        self.mLooping = false
        self.mPosition = 0
        self.mDuration = 0
        self.mError = nil
        self.mSamplingRate = 44100.0
        
        let zeros = [UInt8](repeating: 0, count: 1024)
        self.onWaveformData?(self.mPlayerId, zeros)
        self.onFFTData?(self.mPlayerId, zeros)
        self.notifyStateChanged()
    }
    
    func release() {
        self.mAudioEngine.stop()
    }
    
    func getState() -> [String:Any] {
        if self.mPlayerNode.isPlaying {
            self.mPosition = timeInMilliseconds
        }
        let stats: [String:Any] = [
            "playerId":self.mPlayerId,
            "status": self.mStatus.rawValue,
            "loaded": self.mLoaded,
            "position":self.mPosition,
            "duration":self.mDuration,
        ]
        return stats
    }
    
    private var timeInMilliseconds: Int {
        guard
            let nodeTime = self.mPlayerNode.lastRenderTime,
            let playerTime = self.mPlayerNode.playerTime(forNodeTime: nodeTime)
        else {
            return 0
        }
        
        return Int((Double(playerTime.sampleTime) / self.mSamplingRate) * 1000.0)
    }
    
    
    private func enableVisualizer() {
       self.mAudioEngine.mainMixerNode.removeTap(onBus: 0)
       self.mAudioEngine.mainMixerNode.installTap(onBus: 0, bufferSize: 1024, format: nil, block: { buffer, when in
           guard let channelData = buffer.floatChannelData else { return }
        
           let frameLength = min(1024,buffer.frameLength)
           let channelCount = Int(buffer.format.channelCount)
           let stride = buffer.stride
           
           var rawAmplitudes = [Float](repeating: 0, count: Int(frameLength))
           var amplitudes = [Float](repeating: 0, count: Int(frameLength))
           for channel in 0..<channelCount {
               for frame in 0..<Int(frameLength) {
                   let value = channelData[channel][frame * stride]
                   rawAmplitudes[frame] += value
                   amplitudes[frame] += abs(value)
               }
           }
           rawAmplitudes = rawAmplitudes.map { $0 / Float(channelCount) }
           amplitudes = amplitudes.map { $0 / Float(channelCount) }
           let waveform = _toUInt8(amplitudes)
           var input = _toUInt8(rawAmplitudes)
           var fft = [UInt8](repeating: 0, count: rawAmplitudes.count)
           doFft(fft:&fft, waveform: &input)
           self.onWaveformData?(self.mPlayerId, waveform)
           self.onFFTData?(self.mPlayerId, fft)
       })
    }
    
    private func disableVisualizer() {
        self.mAudioEngine.mainMixerNode.removeTap(onBus: 0)
    }
    
    private func prepareAndScheduleAudio() {
        guard self.mAVAudioFile != nil else { return }
        self.mAudioEngine.prepare()
        self.mPosition = 0
        self.mSamplingRate = self.mAVAudioFile!.processingFormat.sampleRate
        self.mDuration = Int((Double(self.mAVAudioFile!.length) / self.mSamplingRate) * 1000.0)
        self.mPlayerNode.scheduleFile(self.mAVAudioFile!, at: nil) {
            DispatchQueue.main.async {
                if(self.mStatus == .playing) {
                    if(self.mLooping == true) {
                        self.mPosition = self.mDuration
                        self.mPlayerNode.stop()
                        self.mPlayerNode.reset()
                        self.notifyStateChanged()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
                            self?.prepareAndScheduleAudio()
                            self?.mPlayerNode.play()
                        }
                    } else {
                        self.onPlaybackComplete()
                    }
                }
            }
        }
    }
    
    private func onPlaybackComplete() {
        self.mStatus = .stopped
        self.mPosition = self.mDuration
        self.mPlayerNode.stop()
        self.mPlayerNode.reset()
        self.disableVisualizer()
        self.notifyStateChanged()
    }
    
    private func notifyStateChanged() {
        self.onStateChanged?()
    }
}

enum AudioStatus: String {
    case unknown
    case ready
    case playing
    case stopped
    case paused
    case error
}


enum AudioError: Error {
    case runtimeError(code:String,message: String, details:String?)
}


func _toUInt8(_ input: [Float]) -> [UInt8] {
    return input.map { value in
        // convert to int8
        var normalized = round(value * 127)
        // convert to uint8
        if normalized < 0 {
            normalized = normalized + 256
        }
        let clamped = max(0, min(255, normalized))
        return UInt8(clamped)
    }
}

func doFft(fft:inout[UInt8], waveform:inout [UInt8]) {
    let input = _toCArray(&waveform)
    let output = _toCArray(&fft)
    AndroidFFT.do(output, input, UInt32(truncatingIfNeeded: waveform.count))
}

func _toCArray(_ input: inout[UInt8]) -> UnsafeMutablePointer<UInt8> {
    return input.withUnsafeMutableBytes { bufferPointer in
        return bufferPointer.baseAddress!.assumingMemoryBound(to: UInt8.self)
    }
}
