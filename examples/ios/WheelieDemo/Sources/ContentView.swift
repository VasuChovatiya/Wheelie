import SwiftUI
import Wheelie

// MARK: - ContentView

/// Menu of the three demos, with a little wheel you can tap to spin.
struct ContentView: View {
    @StateObject private var heroWheel = WheelController(options: SpinOptions(turns: 1...2, duration: .fixed(1.6)))

    var body: some View {
        NavigationStack {
            ZStack {
                ScreenBackground(colors: Theme.menuBackground)

                ScrollView {
                    VStack(spacing: 18) {
                        header
                        DemoCard(
                            emoji: "🎁",
                            title: "Prize Wheel",
                            subtitle: "Weighted odds, bulbs, confetti",
                            colors: [Color(hex: 0xFF6CAB), Color(hex: 0xFF9A44)]
                        ) { PrizeWheelScreen() }
                        DemoCard(
                            emoji: "🍾",
                            title: "Spin the Bottle",
                            subtitle: "Pointer mode with a custom bottle",
                            colors: [Color(hex: 0x00C6FF), Color(hex: 0x2BD9A0)]
                        ) { BottleScreen() }
                        DemoCard(
                            emoji: "🧪",
                            title: "Playground",
                            subtitle: "Every option and a live event log",
                            colors: [Color(hex: 0xA78BFA), Color(hex: 0x6D5DF6)]
                        ) { PlaygroundScreen() }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .tint(Theme.ink)
        .preferredColorScheme(.light)
    }

    private var header: some View {
        VStack(spacing: 6) {
            WheelStage(isSpinning: heroWheel.isSpinning, showsHub: false) { _ in
                WheelieView(count: 8, controller: heroWheel) { _ in EmptyView() }
                    .wheelStyle(WheelStyle(colors: Theme.candy, rimColor: .clear, rimWidth: 0, separatorWidth: 0))
                    .wheelPointer { EmptyView() }
                    .wheelHub { _ in EmptyView() }
                    .onSegmentPass { _ in Feedback.tick(sound: false) }
            }
            .frame(width: 150, height: 150)
            .contentShape(Circle())
            .onTapGesture { heroWheel.spin() }
            .accessibilityAddTraits(.isButton)
            .accessibilityLabel("Spin the little wheel")
            .padding(.top, 24)

            Text("Wheelie")
                .font(Theme.rounded(52, .black))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(hex: 0xFF4D8D), Color(hex: 0xFF8A00), Color(hex: 0x8B5CF6)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            Text("Spin-the-wheel for SwiftUI")
                .font(Theme.rounded(17, .semibold))
                .foregroundStyle(Theme.inkSoft)
                .padding(.bottom, 10)
        }
    }
}

// MARK: - DemoCard

private struct DemoCard<Destination: View>: View {
    let emoji: String
    let title: String
    let subtitle: String
    let colors: [Color]
    @ViewBuilder let destination: () -> Destination

    var body: some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 16) {
                Text(emoji)
                    .font(.system(size: 34))
                    .frame(width: 62, height: 62)
                    .background(Circle().fill(.white.opacity(0.3)))
                    .overlay(Circle().strokeBorder(.white.opacity(0.6), lineWidth: 2))
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(Theme.rounded(22))
                    Text(subtitle)
                        .font(Theme.rounded(15, .semibold))
                        .opacity(0.9)
                }
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.12), radius: 0, y: 1)
                Spacer(minLength: 0)
                Image(systemName: "chevron.right.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.white.opacity(0.9))
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .strokeBorder(.white.opacity(0.35), lineWidth: 1.5)
            )
            .shadow(color: (colors.last ?? .black).opacity(0.35), radius: 14, y: 8)
        }
        .buttonStyle(PressableStyle())
    }
}
