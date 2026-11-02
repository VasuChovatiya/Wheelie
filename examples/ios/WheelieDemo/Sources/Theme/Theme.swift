import SwiftUI

// MARK: - Theme

/// Bright "candy pop" palette shared by every demo screen.
enum Theme {

    // MARK: Wedge colours (white text reads on all of them)

    static let candy: [Color] = [
        Color(hex: 0xFF4D8D), // pink
        Color(hex: 0xFF8A00), // orange
        Color(hex: 0x8B5CF6), // violet
        Color(hex: 0x00B4D8), // cyan
        Color(hex: 0xFF5E5B), // coral
        Color(hex: 0xF5A300), // amber
        Color(hex: 0x3A86FF), // blue
        Color(hex: 0x06C995), // mint
    ]

    // MARK: Screen backgrounds

    static let menuBackground = [Color(hex: 0xFFF4D6), Color(hex: 0xFFD9E8), Color(hex: 0xD6ECFF)]
    static let prizeBackground = [Color(hex: 0xFF6CAB), Color(hex: 0x9B5CFF)]
    static let bottleBackground = [Color(hex: 0x00C6FF), Color(hex: 0x4BE6A8)]
    static let playgroundBackground = [Color(hex: 0xC9D9FF), Color(hex: 0xFDE2F3)]

    // MARK: Rings and buttons

    static let goldRing = [Color(hex: 0xFFE259), Color(hex: 0xFFA751), Color(hex: 0xFFE259), Color(hex: 0xFFA751), Color(hex: 0xFFE259)]
    static let pinkRing = [Color(hex: 0xFF5ACD), Color(hex: 0xFBDA61), Color(hex: 0xFF5ACD), Color(hex: 0xFBDA61), Color(hex: 0xFF5ACD)]
    static let violetRing = [Color(hex: 0x8B5CF6), Color(hex: 0x5ED4F3), Color(hex: 0x8B5CF6), Color(hex: 0x5ED4F3), Color(hex: 0x8B5CF6)]

    static let sunnyButton = [Color(hex: 0xFFB13B), Color(hex: 0xFF6A00)]
    static let pinkButton = [Color(hex: 0xFF7EB3), Color(hex: 0xFF3D7F)]
    static let violetButton = [Color(hex: 0xA78BFA), Color(hex: 0x7C3AED)]

    // MARK: Text

    static let ink = Color(hex: 0x2B2350)
    static let inkSoft = Color(hex: 0x6B6490)

    static func rounded(_ size: CGFloat, _ weight: Font.Weight = .heavy) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

// MARK: - Color+Hex

extension Color {
    /// `Color(hex: 0xFF4D8D)`
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}
