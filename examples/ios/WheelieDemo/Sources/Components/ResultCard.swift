import SwiftUI

// MARK: - ResultCard

/// White pill above the wheel: a prompt while idle or spinning, the result once it lands.
struct ResultCard: View {
    let emoji: String
    let title: String
    let subtitle: String
    /// Changes when a new result arrives, so the card pops in again.
    let token: String

    var body: some View {
        HStack(spacing: 14) {
            Text(emoji)
                .font(.system(size: 34))
                .frame(width: 52, height: 52)
                .background(Circle().fill(Color(hex: 0xFFF4D6)))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Theme.rounded(22))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(subtitle)
                    .font(Theme.rounded(14, .semibold))
                    .foregroundStyle(Theme.inkSoft)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 10)
        .padding(.leading, 10)
        .padding(.trailing, 18)
        .frame(maxWidth: 360)
        .background(Capsule().fill(.white))
        .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
        .id(token)
        .transition(.scale(scale: 0.85).combined(with: .opacity))
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: token)
        .accessibilityElement(children: .combine)
    }
}
