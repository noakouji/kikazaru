#!/usr/bin/env swift
import Foundation

// 紹介動画のBGMを合成する。
//
// 既製の音源を持ってくるとライセンスの確認が要るし、公開物に使えるか毎回調べ直すことになる。
// 自分で鳴らせば、その問題が最初から存在しない。
//
//   swift scripts/video/music.swift build/video/bgm.wav [長さ秒]

let outPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "build/video/bgm.wav"
let seconds = CommandLine.arguments.count > 2 ? (Double(CommandLine.arguments[2]) ?? 34) : 34
let rate = 44100.0
let count = Int(seconds * rate)

var left = [Double](repeating: 0, count: count)
var right = [Double](repeating: 0, count: count)

/// 音を1つ足す。pan は -1（左）〜 1（右）。
func note(freq: Double, start: Double, dur: Double, amp: Double,
          attack: Double, release: Double, pan: Double = 0, harmonics: [Double] = [1, 0.32, 0.12]) {
    let from = max(Int(start * rate), 0)
    let to = min(Int((start + dur) * rate), count)
    guard to > from else { return }
    let lg = min(max((1 - pan) / 2, 0), 1)
    let rg = min(max((1 + pan) / 2, 0), 1)
    for i in from..<to {
        let t = Double(i - from) / rate
        // 立ち上がりと減衰。角を丸めて、耳に刺さらないようにする。
        var env: Double
        if t < attack { env = t / attack }
        else if t > dur - release { env = max((dur - t) / release, 0) }
        else { env = 1 }
        env *= env
        var v = 0.0
        for (h, level) in harmonics.enumerated() {
            v += sin(2 * .pi * freq * Double(h + 1) * t) * level
        }
        let s = v * env * amp
        left[i] += s * lg
        right[i] += s * rg
    }
}

/// 弾いて減衰する音。和音の上に散らして、間を持たせる。
func pluck(freq: Double, start: Double, amp: Double, pan: Double) {
    let dur = 1.6
    let from = max(Int(start * rate), 0)
    let to = min(Int((start + dur) * rate), count)
    guard to > from else { return }
    let lg = (1 - pan) / 2, rg = (1 + pan) / 2
    for i in from..<to {
        let t = Double(i - from) / rate
        let env = exp(-t * 3.4) * (1 - exp(-t * 260))
        let v = sin(2 * .pi * freq * t) + 0.28 * sin(2 * .pi * freq * 2 * t)
        let s = v * env * amp
        left[i] += s * lg
        right[i] += s * rg
    }
}

// 進行：Fmaj7 → Cadd9 → Dm7 → B♭6/9 を2周。落ち着いていて、繰り返しても飽きにくい。
let bars: [[Double]] = [
    [174.61, 220.00, 261.63, 329.63],   // Fmaj7
    [130.81, 164.81, 196.00, 261.63],   // Cadd9
    [146.83, 174.61, 220.00, 261.63],   // Dm7
    [116.54, 146.83, 174.61, 196.00],   // B♭6/9
]
let barLen = seconds / 8

for b in 0..<8 {
    let chord = bars[b % bars.count]
    let start = Double(b) * barLen

    // 低音。土台だけ置いて、上を邪魔しない。
    note(freq: chord[0] / 2, start: start, dur: barLen + 0.5, amp: 0.085,
         attack: 0.5, release: 1.0, pan: 0, harmonics: [1, 0.18])

    // パッド。左右に少し散らして厚みを出す。
    for (k, f) in chord.enumerated() {
        note(freq: f, start: start, dur: barLen + 0.6, amp: 0.052,
             attack: 0.9, release: 1.2, pan: Double(k % 2 == 0 ? -0.35 : 0.35))
    }

    // 上物。8分で1オクターブ上をなぞる。
    for step in 0..<8 {
        let f = chord[step % chord.count] * 2
        let at = start + Double(step) * (barLen / 8)
        let accent = (step % 4 == 0) ? 1.0 : 0.62
        pluck(freq: f, start: at, amp: 0.085 * accent, pan: step % 2 == 0 ? -0.25 : 0.25)
    }
}

// 簡単な残響。少し遅らせた自分を薄く足すだけで、部屋鳴りらしくなる。
func reverb(_ buf: inout [Double], delays: [(Double, Double)]) {
    let original = buf
    for (sec, gain) in delays {
        let d = Int(sec * rate)
        guard d < buf.count else { continue }
        for i in d..<buf.count { buf[i] += original[i - d] * gain }
    }
}
reverb(&left, delays: [(0.089, 0.24), (0.137, 0.15), (0.211, 0.09)])
reverb(&right, delays: [(0.097, 0.24), (0.149, 0.15), (0.223, 0.09)])

// 出だしと終わりを整える。頭切れ・尻切れは素人くさく聞こえる。
let fadeIn = Int(1.2 * rate)
let fadeOut = Int(3.0 * rate)
for i in 0..<min(fadeIn, count) {
    let g = Double(i) / Double(fadeIn)
    left[i] *= g; right[i] *= g
}
for i in 0..<min(fadeOut, count) {
    let idx = count - 1 - i
    let g = Double(i) / Double(fadeOut)
    left[idx] *= g; right[idx] *= g
}

// 音割れを防ぐ。最大が 0.9 に収まるよう全体を揃える。
let peak = max(left.map(abs).max() ?? 1, right.map(abs).max() ?? 1)
let norm = peak > 0 ? 0.9 / peak : 1
for i in 0..<count { left[i] *= norm; right[i] *= norm }

// WAV（16bit ステレオ）として書き出す
var data = Data()
func put(_ s: String) { data.append(contentsOf: Array(s.utf8)) }
func put32(_ v: UInt32) { withUnsafeBytes(of: v.littleEndian) { data.append(contentsOf: $0) } }
func put16(_ v: UInt16) { withUnsafeBytes(of: v.littleEndian) { data.append(contentsOf: $0) } }

let bytes = UInt32(count * 4)
put("RIFF"); put32(36 + bytes); put("WAVE")
put("fmt "); put32(16); put16(1); put16(2)
put32(UInt32(rate)); put32(UInt32(rate) * 4); put16(4); put16(16)
put("data"); put32(bytes)
for i in 0..<count {
    put16(UInt16(bitPattern: Int16(max(-1, min(1, left[i])) * 32767)))
    put16(UInt16(bitPattern: Int16(max(-1, min(1, right[i])) * 32767)))
}
try! data.write(to: URL(fileURLWithPath: outPath))
print("✅ \(outPath)  \(String(format: "%.1f", seconds))秒")
