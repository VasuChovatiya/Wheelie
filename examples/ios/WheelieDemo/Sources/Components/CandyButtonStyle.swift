import SwiftUI

// MARK: - CandyButtonStyle

/// Chunky glossy pill with a 3D base. Scales down on press and springs back with a light haptic.
struct CandyButtonStyle: ButtonStyle {
    let colors: [Color]

    func makeBody(configuration: Configuration) -> some View {
        CandyButton(configuration: configuration, colors: colors)
    }
}

// MARK: - CandyButton

private struct CandyButton: View {
    let configuration: ButtonStyleConfiguration
    let colors: [Color]

    @Environment(\.isEnabled) private var isEnabled

    private var fill: [Color] { isEnabled ? colors : [Color(hex: 0xD9D6E8), Color(hex: 0xB9B4D0)] }

    var body: some View {
        configuration.label
            .font(Theme.rounded(22))
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.18), radius: 0, y: 2)
            .frame(maxWidth: 300)
            .padding(.vertical, 16)
            .background {
                ZStack {
                    // 3D base: the bottom colour, darkened
                    Capsule()
                        .fill(fill.last ?? .gray)
                        .overlay(Capsule().fill(.black.opacity(0.22)))
                        .offset(y: configuration.isPressed ? 2 : 6)
                    Capsule()
                        .fill(LinearGradient(colors: fill, startPoint: .top, endPoint: .bottom))
                    // Gloss
                    Capsule()
                        .fill(.white.opacity(0.35))
                        .frame(height: 10)
                        .padding(.horizontal, 22)
                        .frame(maxHeight: .infinity, alignment: .top)
                        .padding(.top, 6)
                }
            }
            .offset(y: configuration.isPressed ? 4 : 0)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.55), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, pressed in
                if pressed { Feedback.tap() }
            }
    }
}

// MARK: - PressableStyle

/// For cards and links: scale down on press, spring back. No opacity change.
struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, pressed in
                if pressed { Feedback.tap() }
            }
    }
}
