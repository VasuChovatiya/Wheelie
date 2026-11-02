import SwiftUI
import Wheelie

// MARK: - PlaygroundConfig

/// Everything the playground lets you change. Spin options are fixed per controller, so a change
/// rebuilds the wheel with a fresh controller.
struct PlaygroundConfig: Hashable {
    var count = 8
    var pointerMode = false
    var counterClockwise = false
    var shortSpins = false

    var options: SpinOptions {
        SpinOptions(
            turns: shortSpins ? 1...2 : 3...5,
            duration: shortSpins ? .fixed(1.5) : .byTurns(base: 3.2, perTurn: 0.35),
            direction: counterClockwise ? .counterClockwise : .clockwise
        )
    }
}

// MARK: - PlaygroundScreen

struct PlaygroundScreen: View {
    @State private var config = PlaygroundConfig()

    var body: some View {
        ZStack {
            ScreenBackground(colors: Theme.playgroundBackground)
            PlaygroundWheel(config: $config)
                .id(config)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}

// MARK: - LogEntry

private struct LogEntry: Identifiable {
    enum Kind { case start, land, async }

    let id = UUID()
    let kind: Kind
    let text: String

    var colors: [Color] {
        switch kind {
        case .start: return [Color(hex: 0xA78BFA), Color(hex: 0x7C3AED)]
        case .land: return [Color(hex: 0x34D399), Color(hex: 0x059669)]
        case .async: return [Color(hex: 0x5ED4F3), Color(hex: 0x3A86FF)]
        }
    }

    var symbol: String {
        switch kind {
        case .start: return "play.fill"
        case .land: return "flag.checkered"
        case .async: return "clock.arrow.circlepath"
        }
    }
}

// MARK: - PlaygroundWheel

private struct PlaygroundWheel: View {
    @Binding var config: PlaygroundConfig
    @StateObject private var wheel: WheelController
    @State private var target = 0
    @State private var log: [LogEntry] = []
    @State private var passes = 0

    init(config: Binding<PlaygroundConfig>) {
        _config = config
        _wheel = StateObject(wrappedValue: WheelController(options: config.wrappedValue.options))
    }

    private var mode: WheelMode { config.pointerMode ? .pointer : .wheel }

    /// The wedge under the pointer right now, worked out from the rotation alone (spec: "local angle").
    private var wedgeUnderPointer: Int {
        let segments = (0..<config.count).map { _ in WheelSegment() }
        let local = config.pointerMode ? norm(wheel.rotation) : norm(-wheel.rotation)
        return wedgeIndexAt(local, segments: segments)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                ScreenHeader(title: "Playground", subtitle: "Change anything, then spin")

                WheelStage(isSpinning: wheel.isSpinning, ringColors: Theme.violetRing, showsPin: !config.pointerMode) { diameter in
                    WheelieView(count: config.count, controller: wheel, mode: mode) { index in
                        Text("\(index)")
                            .font(Theme.rounded(22, .black))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.25), radius: 1, y: 1)
                            .rotationEffect(.degrees(-90))
                    }
                    .wheelStyle(WheelStyle(colors: Theme.candy, rimColor: .white, rimWidth: 3, separatorWidth: 2, labelRadius: 0.68))
                    .wheelPointer {
                        if config.pointerMode {
                            NeedleView().frame(width: diameter * 0.12, height: diameter)
                        } else {
                            EmptyView()
                        }
                    }
                    .wheelHub { _ in EmptyView() }
                    .wheelHighlight([.dimOthers(opacity: 0.45)])
                    .onSpinStart { start in
                        passes = 0
                        record(.start, "Winner is \(start.index), chosen before anything moves")
                    }
                    .onSegmentPass { _ in
                        passes += 1
                        Feedback.tick(sound: false)
                    }
                    .onLand { result in
                        let check = result.index == wedgeUnderPointer ? "✓ matches" : "✗ differs from"
                        record(.land, "Landed on \(result.index), \(check) the wedge under the pointer · \(passes) ticks")
                        Feedback.land()
                    }
                }
                .frame(maxWidth: 300)

                readout
                spinButtons
                controls
                eventLog
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
        .autoSpin(wheel)
    }

    // MARK: Sections

    private var readout: some View {
        HStack(spacing: 10) {
            StatChip(symbol: "arrow.clockwise", text: "\(Int(wheel.rotation.rounded()))°")
            StatChip(symbol: "scope", text: "Under pointer: \(wedgeUnderPointer)")
        }
    }

    private var spinButtons: some View {
        VStack(spacing: 14) {
            Button("SPIN") { wheel.spin() }
                .buttonStyle(CandyButtonStyle(colors: Theme.violetButton))

            HStack(spacing: 12) {
                Button("Spin to \(target)") {
                    Task {
                        // The async API returns once the wheel is at rest.
                        if let result = await wheel.spin(to: target) {
                            record(.async, "await spin(to: \(target)) returned \(result.index)")
                        }
                    }
                }
                .buttonStyle(CandyButtonStyle(colors: Theme.pinkButton))

                Stepper("Target", value: $target, in: 0...(config.count - 1))
                    .labelsHidden()
                    .padding(4)
                    .background(Capsule().fill(.white))
            }
        }
        .disabled(wheel.isSpinning)
    }

    private var controls: some View {
        VStack(spacing: 14) {
            Stepper(value: $config.count, in: 2...12) {
                Label("Wedges: \(config.count)", systemImage: "chart.pie.fill")
            }
            Picker("Mode", selection: $config.pointerMode) {
                Text("Wheel turns").tag(false)
                Text("Pointer turns").tag(true)
            }
            .pickerStyle(.segmented)
            Toggle(isOn: $config.counterClockwise) {
                Label("Counter-clockwise", systemImage: "arrow.counterclockwise")
            }
            Toggle(isOn: $config.shortSpins) {
                Label("Short spins (1–2 turns, 1.5 s)", systemImage: "hare.fill")
            }
        }
        .font(Theme.rounded(16, .semibold))
        .foregroundStyle(Theme.ink)
        .tint(Color(hex: 0xFF4D8D))
        .disabled(wheel.isSpinning)
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(.white.opacity(0.9)))
        .shadow(color: Color(hex: 0x8B5CF6).opacity(0.15), radius: 12, y: 6)
    }

    private var eventLog: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Events")
                .font(Theme.rounded(20))
                .foregroundStyle(Theme.ink)
            if log.isEmpty {
                Text("Spin to see events.")
                    .font(Theme.rounded(15, .medium))
                    .foregroundStyle(Theme.inkSoft)
            }
            ForEach(log) { entry in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: entry.symbol)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 26, height: 26)
                        .background(Circle().fill(LinearGradient(colors: entry.colors, startPoint: .top, endPoint: .bottom)))
                    Text(entry.text)
                        .font(Theme.rounded(14, .medium))
                        .foregroundStyle(Theme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(.white.opacity(0.9)))
        .shadow(color: Color(hex: 0x8B5CF6).opacity(0.15), radius: 12, y: 6)
    }

    private func record(_ kind: LogEntry.Kind, _ text: String) {
        log.insert(LogEntry(kind: kind, text: text), at: 0)
        log = Array(log.prefix(8))
    }
}

// MARK: - StatChip

private struct StatChip: View {
    let symbol: String
    let text: String

    var body: some View {
        Label(text, systemImage: symbol)
            .font(Theme.rounded(14, .bold).monospacedDigit())
            .foregroundStyle(Theme.ink)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .frame(maxWidth: .infinity)
            .background(Capsule().fill(.white.opacity(0.9)))
    }
}

// MARK: - NeedleView

/// A slim arrow for pointer mode, tip at the top, centred in its frame.
private struct NeedleView: View {
    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            // Short enough that the tip stops inside the wedge labels.
            let length = geo.size.height * 0.3

            VStack(spacing: 0) {
                Triangle()
                    .fill(LinearGradient(colors: [Color(hex: 0xFF5E7E), Color(hex: 0xE11D48)], startPoint: .top, endPoint: .bottom))
                    .frame(width: width, height: length * 0.3)
                Capsule()
                    .fill(LinearGradient(colors: [Color(hex: 0xE11D48), Color(hex: 0x9F1239)], startPoint: .top, endPoint: .bottom))
                    .frame(width: width * 0.32, height: length * 0.7)
            }
            .shadow(color: .black.opacity(0.3), radius: 4, y: 3)
            // Pivot in the middle of the frame: shift the arrow up so its tail tucks under the centre cap.
            .offset(y: -length * 0.4)
            .frame(width: width, height: geo.size.height)
        }
        .accessibilityHidden(true)
    }
}

/// Point at the top.
private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
