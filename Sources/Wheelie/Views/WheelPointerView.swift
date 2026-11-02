import SwiftUI

// MARK: - WheelPointerView

/// The default triangle pointer that indicates the winning segment.
public struct WheelPointerView: View {
    public init() {}

    public var body: some View {
        Triangle()
            .fill(Color.red)
            .frame(width: 24, height: 36)
            .shadow(radius: 2)
    }
}

// MARK: - Triangle shape

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        // Points downward
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}
