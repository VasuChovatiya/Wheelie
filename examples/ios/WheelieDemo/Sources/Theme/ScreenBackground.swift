import SwiftUI

// MARK: - ScreenBackground

/// Full-screen gradient with a few soft light blobs for depth.
struct ScreenBackground: View {
    let colors: [Color]

    var body: some View {
        ZStack {
            LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)

            GeometryReader { geo in
                let width = geo.size.width
                Circle()
                    .fill(.white.opacity(0.28))
                    .frame(width: width * 0.9)
                    .blur(radius: 60)
                    .offset(x: -width * 0.35, y: -width * 0.25)
                Circle()
                    .fill(.white.opacity(0.22))
                    .frame(width: width * 0.7)
                    .blur(radius: 50)
                    .offset(x: width * 0.55, y: geo.size.height * 0.62)
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Sunburst

/// Static light rays fanning out from the centre, drawn behind a wheel.
struct Sunburst: View {
    var rays = 18
    var opacity = 0.16

    var body: some View {
        Canvas { context, size in
            let centre = CGPoint(x: size.width / 2, y: size.height / 2)
            let reach = max(size.width, size.height)
            let step = 2 * Double.pi / Double(rays)
            for ray in 0..<rays {
                let start = Double(ray) * step
                var path = Path()
                path.move(to: centre)
                path.addLine(to: CGPoint(x: centre.x + cos(start) * reach, y: centre.y + sin(start) * reach))
                path.addLine(to: CGPoint(x: centre.x + cos(start + step / 2) * reach, y: centre.y + sin(start + step / 2) * reach))
                path.closeSubpath()
                context.fill(path, with: .color(.white.opacity(opacity)))
            }
        }
        .mask(RadialGradient(colors: [.white, .clear], center: .center, startRadius: 40, endRadius: 320))
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
