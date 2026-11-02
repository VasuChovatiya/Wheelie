import Foundation

// MARK: - WheelSegment

/// A single segment on the wheel.
public struct WheelSegment: Sendable, Hashable {
    /// Relative size of the wedge. Default is 1.
    public var size: Double
    /// Probability weight. 0 means this segment can never win. Default is 1.
    public var weight: Double
    /// When true the segment cannot be selected as a spin target. Default is false.
    public var isLocked: Bool

    public init(size: Double = 1, weight: Double = 1, isLocked: Bool = false) {
        self.size = size
        self.weight = weight
        self.isLocked = isLocked
    }
}

// MARK: - WheelMode

/// Determines whether the wheel or the pointer animates during a spin.
public enum WheelMode: Sendable, Hashable {
    /// The wheel rotates; the pointer stays fixed at the top.
    case wheel
    /// The wheel is fixed; the pointer rotates.
    case pointer
}
