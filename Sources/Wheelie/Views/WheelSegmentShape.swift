import SwiftUI

// MARK: - WheelSegmentShape

/// A SwiftUI `Shape` that draws a single pie-slice wedge.
///
/// Angles are specified in degrees, clockwise, with 0° at 12 o'clock.
/// Internally converts to SwiftUI's convention (0° = 3 o'clock, anti-clockwise positive)
/// by subtracting 90°.
public struct WheelSegmentShape: Shape {
    /// Start angle in degrees (clockwise, 0° = 12 o'clock).
    public var startDegrees: Double
    /// End angle in degrees (clockwise, 0° = 12 o'clock).
    public var endDegrees: Double

    public init(startAngle: Double, endAngle: Double) {
        self.startDegrees = startAngle
        self.endDegrees = endAngle
    }

    public func path(in rect: CGRect) -> Path {
        let centre = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2

        // Convert from "clockwise, 0° = 12 o'clock" to SwiftUI's Angle
        // SwiftUI uses 0° = 3 o'clock, positive = clockwise when drawn on screen
        let swiftUIStart = Angle.degrees(startDegrees - 90)
        let swiftUIEnd   = Angle.degrees(endDegrees   - 90)

        var path = Path()
        path.move(to: centre)
        path.addArc(
            center: centre,
            radius: radius,
            startAngle: swiftUIStart,
            endAngle: swiftUIEnd,
            clockwise: false
        )
        path.closeSubpath()
        return path
    }
}
