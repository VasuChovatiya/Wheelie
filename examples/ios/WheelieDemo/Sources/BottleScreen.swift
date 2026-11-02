import SwiftUI
import Wheelie

// MARK: - BottleScreen

/// Pointer mode: the wheel of names stays still and the bottle spins over it.
struct BottleScreen: View {
    @StateObject private var wheel = WheelController()
    @State private var playerCount = 6
    @State private var picked: String?
    @State private var confetti = 0

    private let names = ["Aarav", "Diya", "Kabir", "Meera", "Rohan", "Sara", "Ishaan", "Anaya", "Vivaan", "Tara"]

    private var players: [String] { Array(names.prefix(playerCount)) }

    var body: some View {
        ZStack {
            ScreenBackground(colors: Theme.bottleBackground)

            VStack(spacing: 20) {
                ScreenHeader(title: "Spin the Bottle", subtitle: "Who's next? Let the bottle decide", onDark: true)
                resultCard

                WheelStage(isSpinning: wheel.isSpinning, ringColors: Theme.pinkRing, showsPin: false, showsHub: false) { diameter in
                    WheelieView(count: players.count, controller: wheel, mode: .pointer) { index in
                        Text(players[index])
                            .font(Theme.rounded(16))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.25), radius: 1, y: 1)
                            // This wheel never turns, so flip names on the right half to keep them readable.
                            .rotationEffect(.degrees(isOnRightHalf(index) ? 180 : 0))
                    }
                    .wheelStyle(WheelStyle(colors: Theme.candy, rimColor: .white, rimWidth: 3, separatorWidth: 2, labelRadius: 0.7))
                    // In pointer mode the pointer view is pinned to the top of the wheel's square, so a
                    // full-height frame keeps the bottle centred while it spins.
                    .wheelPointer { BottleView().frame(width: diameter * 0.2, height: diameter) }
                    .wheelHub { _ in EmptyView() }
                    .wheelHighlight([.dimOthers(opacity: 0.45)])
                    .onSpinStart { _ in
                        picked = nil
                        Feedback.prepare()
                    }
                    .onSegmentPass { _ in Feedback.tick(sound: true) }
                    .onLand { result in
                        picked = players[result.index]
                        confetti += 1
                        Feedback.land()
                    }
                    // Rebuild when the player count changes so the controller picks up the new wedges.
                    .id(playerCount)
                }
                .contentShape(Circle())
                .onTapGesture { wheel.spin() }
                .accessibilityAddTraits(.isButton)
                .accessibilityLabel("Bottle. Tap to spin")
                .background {
                    Sunburst(opacity: 0.2)
                        .frame(width: 620, height: 620)
                }
                .frame(maxWidth: 360, maxHeight: 360)
                .padding(.horizontal, 20)

                PlayerStepper(count: $playerCount, range: 2...names.count)
                    .disabled(wheel.isSpinning)
                    .onChange(of: playerCount) {
                        picked = nil
                        wheel.reset()
                    }

                Button(wheel.isSpinning ? "Spinning…" : "SPIN THE BOTTLE") { wheel.spin() }
                    .buttonStyle(CandyButtonStyle(colors: Theme.pinkButton))
                    .disabled(wheel.isSpinning)
                    .padding(.horizontal, 40)

                Spacer(minLength: 0)
            }

            ConfettiView(trigger: confetti)
                .ignoresSafeArea()
        }
        .autoSpin(wheel)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    @ViewBuilder private var resultCard: some View {
        if let picked {
            ResultCard(emoji: "🍾", title: "\(picked)'s turn!", subtitle: "Truth or dare?", token: "picked-\(picked)-\(confetti)")
        } else if wheel.isSpinning {
            ResultCard(emoji: "🌀", title: "Round and round…", subtitle: "Where will it stop?", token: "spinning")
        } else {
            ResultCard(emoji: "🎉", title: "\(playerCount) players", subtitle: "Tap the bottle to spin", token: "idle")
        }
    }

    /// Wedge `index` is centred at `index * 360 / count` degrees; the right half is 0° to 180°.
    private func isOnRightHalf(_ index: Int) -> Bool {
        let centre = Double(index) * 360 / Double(players.count)
        return centre > 0 && centre < 180
    }
}

// MARK: - PlayerStepper

/// White pill with round minus and plus buttons.
private struct PlayerStepper: View {
    @Binding var count: Int
    let range: ClosedRange<Int>

    var body: some View {
        HStack(spacing: 18) {
            stepButton("minus", enabled: count > range.lowerBound) { count -= 1 }
            Text("\(count) players")
                .font(Theme.rounded(18))
                .foregroundStyle(Theme.ink)
                .monospacedDigit()
                .frame(minWidth: 110)
            stepButton("plus", enabled: count < range.upperBound) { count += 1 }
        }
        .padding(6)
        .background(Capsule().fill(.white))
        .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
    }

    private func stepButton(_ symbol: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .black))
                .foregroundStyle(.white)
                .frame(width: 38, height: 38)
                .background(
                    Circle().fill(
                        enabled
                            ? LinearGradient(colors: Theme.pinkButton, startPoint: .top, endPoint: .bottom)
                            : LinearGradient(colors: [Color(hex: 0xD9D6E8)], startPoint: .top, endPoint: .bottom)
                    )
                )
        }
        .buttonStyle(PressableStyle())
        .disabled(!enabled)
        .accessibilityLabel(symbol == "plus" ? "Add player" : "Remove player")
    }
}

// MARK: - BottleView

/// A green glass bottle drawn with shapes, neck pointing up. Fills its frame's width; about 76% of its height.
struct BottleView: View {
    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let length = geo.size.height * 0.76

            VStack(spacing: 0) {
                // Cap
                RoundedRectangle(cornerRadius: width * 0.08)
                    .fill(LinearGradient(colors: [Color(hex: 0xFFE259), Color(hex: 0xFFA751)], startPoint: .leading, endPoint: .trailing))
                    .frame(width: width * 0.36, height: length * 0.05)
                // Neck
                Rectangle()
                    .fill(glass)
                    .frame(width: width * 0.3, height: length * 0.3)
                // Shoulder
                Trapezoid()
                    .fill(glass)
                    .frame(width: width, height: length * 0.12)
                // Body
                RoundedRectangle(cornerRadius: width * 0.22)
                    .fill(glass)
                    .frame(width: width, height: length * 0.53)
                    .overlay(alignment: .leading) {
                        Capsule()
                            .fill(.white.opacity(0.4))
                            .frame(width: width * 0.12, height: length * 0.36)
                            .padding(.leading, width * 0.16)
                    }
                    .overlay {
                        // Label
                        RoundedRectangle(cornerRadius: width * 0.06)
                            .fill(Color(hex: 0xFFF4D6))
                            .frame(width: width * 0.62, height: length * 0.14)
                            .overlay(Image(systemName: "star.fill").font(.system(size: width * 0.22)).foregroundStyle(Color(hex: 0xFF4D8D)))
                            .offset(x: width * 0.08)
                    }
            }
            .shadow(color: .black.opacity(0.35), radius: 6, y: 4)
            .frame(width: width, height: geo.size.height)
        }
        .accessibilityHidden(true)
    }

    private var glass: LinearGradient {
        LinearGradient(
            colors: [Color(hex: 0x34D399), Color(hex: 0x059669), Color(hex: 0x065F46)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

// MARK: - Trapezoid

/// Narrow at the top, full width at the bottom: the bottle's shoulder.
private struct Trapezoid: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let inset = rect.width * 0.35
        path.move(to: CGPoint(x: rect.minX + inset, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - inset, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
