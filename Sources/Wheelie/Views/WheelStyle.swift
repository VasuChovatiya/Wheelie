import SwiftUI

// MARK: - WheelStyle

/// Visual styling applied to the wheel.
public struct WheelStyle: Sendable, Equatable {
    /// Segment fill colours, cycled through for each wedge.
    public var colors: [Color]
    /// Colour of the outer rim ring.
    public var rimColor: Color
    /// Width of the outer rim ring in points.
    public var rimWidth: Double
    /// Width of the lines drawn at segment boundaries in points.
    public var separatorWidth: Double
    /// Distance from the centre at which segment content is placed, as a fraction of the wheel radius.
    public var labelRadius: Double

    public init(
        colors: [Color] = [
            Color(red: 0.98, green: 0.36, blue: 0.35),
            Color(red: 0.20, green: 0.60, blue: 0.86),
            Color(red: 0.30, green: 0.69, blue: 0.31),
            Color(red: 0.99, green: 0.73, blue: 0.02),
            Color(red: 0.61, green: 0.35, blue: 0.71),
            Color(red: 1.00, green: 0.60, blue: 0.00),
            Color(red: 0.01, green: 0.74, blue: 0.67),
            Color(red: 0.91, green: 0.12, blue: 0.39),
        ],
        rimColor: Color = .white,
        rimWidth: Double = 4,
        separatorWidth: Double = 1,
        labelRadius: Double = 0.65
    ) {
        self.colors = colors
        self.rimColor = rimColor
        self.rimWidth = rimWidth
        self.separatorWidth = separatorWidth
        self.labelRadius = labelRadius
    }
}

// MARK: - WheelHighlight

/// Visual highlight applied to the currently winning (landed) segment.
public enum WheelHighlight: Sendable, Equatable {
    /// No highlight.
    case none
    /// All other segments are dimmed.
    case dimOthers(opacity: Double)
    /// An outline is drawn around the winning segment.
    case outline(color: Color, width: Double)
    /// The winning segment is scaled up.
    case pulse(scale: Double)
}
