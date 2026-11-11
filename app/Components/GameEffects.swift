import SwiftUI
import AVFoundation

/// Short synthesized sound effects. No audio files needed.
/// Respects the silent switch (.ambient) and the "soundOn" setting.
final class Sound {
    static let shared = Sound()

    enum Effect: CaseIterable { case correct, wrong, tick, combo, levelUp }

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
    private var buffers: [Effect: AVAudioPCMBuffer] = [:]

    private init() {
        try? AVAudioSession.sharedInstance().setCategory(.ambient)
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
        buffers[.correct] = tone([(660, 0.08), (880, 0.14)])
        buffers[.wrong] = tone([(196, 0.22)])
        buffers[.tick] = tone([(1200, 0.04)])
        buffers[.combo] = tone([(660, 0.06), (880, 0.06), (1175, 0.14)])
        buffers[.levelUp] = tone([(523, 0.1), (659, 0.1), (784, 0.1), (1047, 0.25)])
    }

    func play(_ effect: Effect) {
        guard UserDefaults.standard.object(forKey: "soundOn") as? Bool ?? true,
              let buffer = buffers[effect] else { return }
        if !engine.isRunning {
            try? AVAudioSession.sharedInstance().setActive(true)
            guard (try? engine.start()) != nil else { return }
        }
        player.scheduleBuffer(buffer, at: nil, options: .interrupts)
        if !player.isPlaying { player.play() }
    }

    /// Sine notes back to back, each with a quick fade in/out to avoid clicks.
    private func tone(_ notes: [(freq: Double, dur: Double)]) -> AVAudioPCMBuffer? {
        let rate = format.sampleRate
        let total = AVAudioFrameCount(notes.reduce(0) { $0 + $1.dur } * rate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: total),
              let data = buffer.floatChannelData?[0] else { return nil }
        var i = 0
        for note in notes {
            let n = Int(note.dur * rate)
            for k in 0..<n {
                let t = Double(k) / rate
                let attack = min(1, Double(k) / (0.005 * rate))
                let release = 1 - Double(k) / Double(n)
                data[i] = Float(sin(2 * .pi * note.freq * t) * 0.25 * attack * release)
                i += 1
            }
        }
        buffer.frameLength = AVAudioFrameCount(i)
        return buffer
    }
}

/// Falling confetti overlay. Plays once (about 4 seconds), then disappears.
struct ConfettiView: View {
    private struct Piece {
        let x = Double.random(in: 0...1)
        let delay = Double.random(in: 0...0.6)
        let fall = Double.random(in: 120...260)
        let sway = Double.random(in: 1...4)
        let spin = Double.random(in: -8...8)
        let size = CGSize(width: .random(in: 6...10), height: .random(in: 10...16))
        let color: Color = [.red, .orange, .yellow, .green, .blue, .purple, .pink].randomElement()!
    }

    @State private var pieces = (0..<90).map { _ in Piece() }
    @State private var start = Date.now
    @State private var visible = true

    var body: some View {
        if visible {
            TimelineView(.animation) { context in
                Canvas { gc, size in
                    let t = context.date.timeIntervalSince(start)
                    for p in pieces {
                        let tt = t - p.delay
                        guard tt > 0 else { continue }
                        let y = -20 + p.fall * tt + 180 * tt * tt
                        guard y < size.height + 20 else { continue }
                        let x = p.x * size.width + sin(tt * p.sway) * 30
                        var g = gc
                        g.translateBy(x: x, y: y)
                        g.rotate(by: .radians(tt * p.spin))
                        g.fill(Path(CGRect(x: -p.size.width / 2, y: -p.size.height / 2,
                                           width: p.size.width, height: p.size.height)),
                               with: .color(p.color))
                    }
                }
            }
            .allowsHitTesting(false)
            .ignoresSafeArea()
            .task {
                try? await Task.sleep(for: .seconds(4))
                visible = false
            }
        }
    }
}

/// Lays out children left to right, wrapping to new rows like words in a paragraph.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0, widest: CGFloat = 0
        for view in subviews {
            let s = view.sizeThatFits(ProposedViewSize(width: maxWidth, height: nil))
            if x > 0, x + s.width > maxWidth {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += s.width + spacing
            widest = max(widest, x - spacing)
            rowHeight = max(rowHeight, s.height)
        }
        return CGSize(width: proposal.width ?? widest, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for view in subviews {
            let s = view.sizeThatFits(ProposedViewSize(width: bounds.width, height: nil))
            if x > bounds.minX, x + s.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(s))
            x += s.width + spacing
            rowHeight = max(rowHeight, s.height)
        }
    }
}
