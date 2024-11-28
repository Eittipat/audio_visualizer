//
//  AndroidFFT.swift
//  Pods
//
//  Created by Eittipat Kraichingrith on 1/11/2567 BE.
//

import Foundation


mult(_ a: Int32, _ b: Int32) -> Int32 {
    let highA = a >> 16
    let lowA = Int16(truncatingIfNeeded: a)
    let highB = b >> 16
    let lowB = Int16(truncatingIfNeeded: b)
    
    let high = ((highA * highB + Int32(lowA) * Int32(lowB)) & ~0xFFFF)
    let low = (((highA * Int32(lowB) - Int32(lowA) * highB) >> 16) & 0xFFFF)
    
    return high | low
}

class AndroidFFT {
    private static let LOG_FFT_SIZE = 10
    private static let MAX_FFT_SIZE = 1 << LOG_FFT_SIZE
    
    // Twiddle factors table - converted from original C++ code
    private static let twiddle: [UInt32] = [
        0x00008000, 0xff378001, 0xfe6e8002, 0xfda58006, 0xfcdc800a, 0xfc13800f,
        0xfb4a8016, 0xfa81801e, 0xf9b88027, 0xf8ef8032, 0xf827803e, 0xf75e804b,
        // ... rest of the twiddle factors array (truncated for brevity)
        0x8016fb4a, 0x800ffc13, 0x800afcdc, 0x8006fda5, 0x8002fe6e, 0x8001ff37
    ]
    
    // Multiplication of conjugate(a) and b
    private static func mult(_ a: Int32, _ b: Int32) -> Int32 {
        let highA = a >> 16
        let lowA = Int16(truncatingIfNeeded: a)
        let highB = b >> 16
        let lowB = Int16(truncatingIfNeeded: b)
        
        let high = ((highA * highB + Int32(lowA) * Int32(lowB)) & ~0xFFFF)
        let low = (((highA * Int32(lowB) - Int32(lowA) * highB) >> 16) & 0xFFFF)
        
        return high | low
    }
    
    // Half value computation
    private static func half(_ a: Int32) -> Int32 {
        return ((a >> 1) & ~0x8000) | (a & 0x8000)
    }
    
    // Fixed-point FFT implementation
    private static func fixedFFT(_ n: Int, _ v: inout [Int32]) {
        var scale = LOG_FFT_SIZE
        
        // Bit reversal
        var r = 0
        for i in 1..<n {
            var p = n
            while ((p & r) == 0) {
                p >>= 1
                r ^= p
            }
            if i < r {
                let t = v[i]
                v[i] = v[r]
                v[r] = t
            }
        }
        
        // FFT computation
        var p = 1
        while p < n {
            scale -= 1
            
            // First phase
            for i in stride(from: 0, to: n, by: p << 1) {
                let x = half(v[i])
                let y = half(v[i + p])
                v[i] = x + y
                v[i + p] = x - y
            }
            
            // Second phase
            for r in 1..<p {
                var w = MAX_FFT_SIZE / 4 - (r << scale)
                let i = w >> 31
                w = Int32(twiddle[(w ^ i) - i]) ^ (i << 16)
                
                for i in stride(from: r, to: n, by: p << 1) {
                    let x = half(v[i])
                    let y = mult(w, v[i + p])
                    v[i] = x - y
                    v[i + p] = x + y
                }
            }
            
            p <<= 1
        }
    }
    
    // Real FFT implementation
    private static func fixedFFTReal(_ n: Int, _ v: inout [Int32]) {
        var scale = LOG_FFT_SIZE
        let m = n >> 1
        
        fixedFFT(n, &v)
        
        var i = 1
        while i <= n {
            scale -= 1
            i <<= 1
        }
        
        v[0] = mult(~v[0], 0x80008000)
        v[m] = half(v[m])
        
        for i in 1..<(n >> 1) {
            let x = half(v[i])
            let z = half(v[n - i])
            let y = z - (x ^ 0xFFFF)
            let newX = half(x + (z ^ 0xFFFF))
            let newY = mult(y, Int32(twiddle[i << scale]))
            v[i] = newX - newY
            v[n - i] = (newX + newY) ^ 0xFFFF
        }
    }
    
    // Main FFT processing function
    public static func doFft(fft: inout [UInt8], waveform: [UInt8], captureSize: Int) {
        var workspace = [Int32](repeating: 0, count: captureSize >> 1)
        var nonzero: Int32 = 0
        
        // Prepare workspace
        for i in stride(from: 0, to: captureSize, by: 2) {
            workspace[i >> 1] = ((Int32(waveform[i]) ^ 0x80) << 24) | ((Int32(waveform[i + 1]) ^ 0x80) << 8)
            nonzero |= workspace[i >> 1]
        }
        
        // Perform FFT if signal is not zero
        if nonzero != 0 {
            fixedFFTReal(captureSize >> 1, &workspace)
        }
        
        // Convert results back
        for i in stride(from: 0, to: captureSize, by: 2) {
            var tmp = workspace[i >> 1] >> 21
            while tmp > 127 || tmp < -128 { tmp >>= 1 }
            fft[i] = UInt8(truncatingIfNeeded: tmp)
            
            tmp = workspace[i >> 1]
            tmp >>= 5
            while tmp > 127 || tmp < -128 { tmp >>= 1 }
            fft[i + 1] = UInt8(truncatingIfNeeded: tmp)
        }
    }
}
