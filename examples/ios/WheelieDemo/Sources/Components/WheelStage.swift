import SwiftUI

// MARK: - WheelStage

/// Dresses a `WheelieView` up: drop shadow, a ring of bulbs that chase while spinning, a glossy pin
/// pointer at 12 o'clock and a centre cap that stays upright. The wheel itself goes in `wheel`,
/// which receives the diameter it should draw at.
struct WheelStage<Wheel: View>: View {
    var isSpinning: Bool
    var ringColors: [Color] = Theme.goldRing
    var showsPin = true
    var hubText: String?
    var showsHub = true
    @ViewBuilder var wheel: (CGFloat) -> Wheel

    var body: some View {
        GeometryReader { geo in
            let diameter = min(geo.size.width, geo.size.height)
            let ring = diameter * 0.075
            let inner = diameter - ring * 2 + 2

            ZStack {
                Circle()
                    .fill(.black.opacity(0.18))
                    .blur(radius: 14)
                    .offset(y: 12)

                BulbRing(diameter: diameter, thickness: ring, colors: ringColors, isSpinning: isSpinning)

                // White behind the wedges, so dimmed ones turn pastel instead of showing the background.
                Circle()
                    .fill(.white)
                    .frame(width: inner, height: inner)

                wheel(inner)
                    .frame(width: inner, height: inner)
                    .clipShape(Circle())

                if showsHub {
                    WheelCap(text: hubText, diameter: diameter * 0.2, ringColors: ringColors)
                }

                if showsPin {
                    PinPointer()
                        .frame(width: diameter * 0.11, height: diameter * 0.15)
                        .offset(y: -diameter / 2 + diameter * 0.15 / 2 - diameter * 0.02)
                }
            }
            .frame(width: diameter, height: diameter)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

// MARK: - BulbRing

/// A thick gradient ring studded with bulbs. Idle: every other bulb lit. Spinning: lights chase round.
struct BulbRing: View {
    let diameter: CGFloat
    let thickness: CGFloat
    let colors: [Color]
    let isSpinning: Bool

    private let bulbs = 20

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.09, paused: !isSpinning)) { timeline in
            let step = Int(timeline.date.timeIntervalSinceReferenceDate / 0.09)

            ZStack {
                Circle()
                    .strokeBorder(AngularGradient(colors: colors, center: .center), lineWidth: thickness)
                Circle()
                    .strokeBorder(.white.opacity(0.7), lineWidth: 2)
                Circle()
                    .strokeBorder(.white.opacity(0.5), lineWidth: 2)
                    .padding(thickness - 2)

                ForEach(0..<bulbs, id: \.self) { bulb in
                    let lit = isSpinning ? (bulb + step) % 3 == 0 : bulb % 2 == 0
                    let angle = Double(bulb) / Double(bulbs) * 2 * .pi
                    let radius = diameter / 2 - thickness / 2

                    Circle()
                        .fill(lit ? Color.white : Color(hex: 0xFFF3C4).opacity(0.55))
                        .frame(width: thickness * 0.42, height: thickness * 0.42)
                        .shadow(color: lit ? Color(hex: 0xFFF7AE) : .clear, radius: lit ? 6 : 0)
                        .offset(x: sin(angle) * radius, y: -cos(angle) * radius)
                }
            }
            .frame(width: diameter, height: diameter)
        }
        .accessibilityHidden(true)
    }
}

// MARK: - PinPointer

/// Glossy map-pin style pointer, tip pointing down into the wheel.
struct PinPointer: View {
    var body: some View {
        PinShape()
            .fill(LinearGradient(colors: [Color(hex: 0xFF5E7E), Color(hex: 0xE11D48)], startPoint: .top, endPoint: .bottom))
            .overlay(PinShape().stroke(.white, lineWidth: 3))
            .overlay(alignment: .top) {
                GeometryReader { geo in
                    Circle()
                        .fill(.white.opacity(0.9))
                        .frame(width: geo.size.width * 0.32, height: geo.size.width * 0.32)
                        .position(x: geo.size.width / 2, y: geo.size.width / 2)
                }
            }
            .shadow(color: .black.opacity(0.3), radius: 4, y: 3)
            .accessibilityHidden(true)
    }
}

/// A circle on top running into a point at the bottom.
private struct PinShape: Shape {
    func path(in rect: CGRect) -> Path {
        let radius = rect.width / 2
        let centre = CGPoint(x: rect.midX, y: rect.minY + radius)
        var path = Path()
        path.addArc(center: centre, radius: radius, startAngle: .degrees(150), endAngle: .degrees(30), clockwise: false)
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - WheelCap

/// White centre cap with a gradient border, showing a word or a star. Never rotates.
struct WheelCap: View {
    let text: String?
    let diameter: CGFloat
    let ringColors: [Color]

    var body: some View {
        Circle()
            .fill(RadialGradient(colors: [.white, Color(hex: 0xF3EEFF)], center: .topLeading, startRadius: 2, endRadius: diameter))
            .overlay(Circle().strokeBorder(AngularGradient(colors: ringColors, center: .center), lineWidth: diameter * 0.1))
            .overlay {
                if let text {
                    Text(text)
                        .font(Theme.rounded(diameter * 0.22))
                        .foregroundStyle(LinearGradient(colors: Theme.pinkButton, startPoint: .top, endPoint: .bottom))
                } else {
                    Image(systemName: "star.fill")
                        .font(.system(size: diameter * 0.36))
                        .foregroundStyle(LinearGradient(colors: Theme.sunnyButton, startPoint: .top, endPoint: .bottom))
                }
            }
            .frame(width: diameter, height: diameter)
            .shadow(color: .black.opacity(0.22), radius: 5, y: 3)
    }
}
