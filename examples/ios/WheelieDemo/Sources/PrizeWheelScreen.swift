import SwiftUI
import Wheelie

// MARK: - Prize

struct Prize {
    let emoji: String
    let title: String
    /// Relative odds. Wedges stay the same size; only the chance of winning changes.
    let weight: Double
}

// MARK: - PrizeWheelScreen

/// Wheel mode: the wheel turns under a fixed pointer. The jackpot is rare even though its wedge is full size.
struct PrizeWheelScreen: View {
    @StateObject private var wheel = WheelController()
    @State private var won: Prize?
    @State private var soundOn = true
    @State private var confetti = 0

    private let prizes: [Prize] = [
        Prize(emoji: "🪙", title: "10 coins", weight: 30),
        Prize(emoji: "🎁", title: "Mystery", weight: 10),
        Prize(emoji: "🪙", title: "25 coins", weight: 20),
        Prize(emoji: "💎", title: "Jackpot", weight: 2),
        Prize(emoji: "🪙", title: "50 coins", weight: 12),
        Prize(emoji: "🔁", title: "Spin again", weight: 15),
        Prize(emoji: "⭐️", title: "Bonus XP", weight: 15),
        Prize(emoji: "😅", title: "Try again", weight: 25),
    ]

    var body: some View {
        ZStack {
            ScreenBackground(colors: Theme.prizeBackground)

            VStack(spacing: 20) {
                ScreenHeader(title: "Prize Wheel", subtitle: "Tap the wheel or the button", onDark: true)
                resultCard

                WheelStage(isSpinning: wheel.isSpinning, hubText: "SPIN") { _ in
                    WheelieView(
                        segments: prizes.map { WheelSegment(weight: $0.weight) },
                        controller: wheel
                    ) { index in
                        PrizeLabel(prize: prizes[index])
                    }
                    .wheelStyle(WheelStyle(colors: Theme.candy, rimColor: .white, rimWidth: 3, separatorWidth: 2, labelRadius: 0.64))
                    .wheelPointer { EmptyView() }
                    .wheelHub { _ in EmptyView() }
                    .wheelHighlight([.dimOthers(opacity: 0.45)])
                    .onSpinStart { _ in
                        won = nil
                        Feedback.prepare()
                    }
                    .onSegmentPass { _ in Feedback.tick(sound: soundOn) }
                    .onLand { result in
                        won = prizes[result.index]
                        confetti += 1
                        Feedback.land()
                    }
                }
                .contentShape(Circle())
                .onTapGesture { wheel.spin() }
                .accessibilityAddTraits(.isButton)
                .accessibilityLabel("Prize wheel. Tap to spin")
                .background {
                    Sunburst()
                        .frame(width: 620, height: 620)
                }
                .frame(maxWidth: 360, maxHeight: 360)
                .padding(.horizontal, 20)

                Button(wheel.isSpinning ? "Spinning…" : "SPIN!") { wheel.spin() }
                    .buttonStyle(CandyButtonStyle(colors: Theme.sunnyButton))
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
        .toolbar {
            Button {
                soundOn.toggle()
            } label: {
                Image(systemName: soundOn ? "speaker.wave.2.fill" : "speaker.slash.fill")
                    .foregroundStyle(.white)
            }
            .accessibilityLabel(soundOn ? "Mute ticks" : "Unmute ticks")
        }
    }

    @ViewBuilder private var resultCard: some View {
        if let won {
            ResultCard(
                emoji: won.emoji,
                title: "You won \(won.title)!",
                subtitle: won.weight <= 2 ? "Incredible luck 🎉" : "Spin again any time",
                token: "won-\(won.title)-\(confetti)"
            )
        } else if wheel.isSpinning {
            ResultCard(emoji: "🤞", title: "Good luck…", subtitle: "Round and round it goes", token: "spinning")
        } else {
            ResultCard(emoji: "🎡", title: "Ready to spin?", subtitle: "Jackpot odds: 2 in 129", token: "idle")
        }
    }
}

// MARK: - PrizeLabel

/// Emoji over a title, standing upright in its wedge with the top towards the rim.
private struct PrizeLabel: View {
    let prize: Prize

    var body: some View {
        VStack(spacing: 1) {
            Text(prize.emoji)
                .font(.system(size: 26))
                .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
            Text(prize.title)
                .font(Theme.rounded(11))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.25), radius: 1, y: 1)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(width: 58)
        // Wheelie turns content to read outward along the radius; turn it back a quarter to stand upright.
        .rotationEffect(.degrees(-90))
    }
}

// MARK: - ScreenHeader

/// Big rounded title with a one-line subtitle.
struct ScreenHeader: View {
    let title: String
    let subtitle: String
    var onDark = false

    var body: some View {
        VStack(spacing: 2) {
            Text(title)
                .font(Theme.rounded(34, .black))
            Text(subtitle)
                .font(Theme.rounded(15, .semibold))
                .opacity(0.85)
        }
        .foregroundStyle(onDark ? .white : Theme.ink)
        .shadow(color: .black.opacity(onDark ? 0.15 : 0), radius: 0, y: 2)
    }
}
