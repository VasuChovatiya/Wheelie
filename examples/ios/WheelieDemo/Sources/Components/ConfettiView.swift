import SwiftUI

// MARK: - ConfettiView

/// A burst of falling confetti each time `trigger` changes. Draws nothing the rest of the time.
struct ConfettiView: View {
    let trigger: Int

    @State private var pieces: [ConfettiPiece] = []
    @State private var start: Date?

    private let lifetime: TimeInterval = 3.2

    var body: some View {
        TimelineView(.animation(paused: start == nil)) { timeline in
            Canvas { context, size in
                guard let start else { return }
                let elapsed = timeline.date.timeIntervalSince(start)

                for piece in pieces {
                    let y = piece.startY + piece.speed * elapsed + 140 * elapsed * elapsed
                    guard y < size.height + 30 else { continue }
                    let x = piece.startX * size.width + sin(elapsed * piece.wobble + piece.phase) * 18

                    var layer = context
                    layer.translateBy(x: x, y: y)
                    layer.rotate(by: .degrees(piece.spin * elapsed))
                    layer.scaleBy(x: 1, y: cos(elapsed * piece.wobble * 1.5))
                    let rect = CGRect(x: -piece.width / 2, y: -piece.height / 2, width: piece.width, height: piece.height)
                    let shape = piece.isRound ? Path(ellipseIn: rect) : Path(roundedRect: rect, cornerRadius: 1.5)
                    layer.fill(shape, with: .color(piece.color))
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onChange(of: trigger) {
            pieces = (0..<90).map { _ in ConfettiPiece.random() }
            let burst = Date()
            start = burst
            DispatchQueue.main.asyncAfter(deadline: .now() + lifetime) {
                if start == burst { start = nil }
            }
        }
    }
}

// MARK: - ConfettiPiece

private struct ConfettiPiece {
    let startX: Double
    let startY: Double
    let speed: Double
    let spin: Double
    let wobble: Double
    let phase: Double
    let width: Double
    let height: Double
    let isRound: Bool
    let color: Color

    static func random() -> ConfettiPiece {
        let isRound = Double.random(in: 0..<1) < 0.25
        let size = Double.random(in: 7...12)
        return ConfettiPiece(
            startX: .random(in: 0...1),
            startY: .random(in: -260 ... -20),
            speed: .random(in: 90...240),
            spin: .random(in: -360...360),
            wobble: .random(in: 2...5),
            phase: .random(in: 0...(2 * .pi)),
            width: isRound ? size * 0.8 : size * 0.6,
            height: isRound ? size * 0.8 : size,
            isRound: isRound,
            color: (Theme.candy + [.white, Color(hex: 0xFFE259)]).randomElement() ?? .white
        )
    }
}
