import Foundation

// MARK: - WheelSpinStart

/// Emitted when a spin animation begins.
public struct WheelSpinStart: Sendable, Equatable {
    /// The index of the segment the wheel is spinning towards.
    public let index: Int

    public init(index: Int) {
        self.index = index
    }
}

// MARK: - WheelResult

/// Emitted when a spin animation finishes and the wheel has landed.
public struct WheelResult: Sendable, Equatable {
    /// The index of the segment the wheel landed on.
    public let index: Int
    /// The final accumulated rotation in degrees (not normalised).
    public let rotation: Double

    public init(index: Int, rotation: Double) {
        self.index = index
        self.rotation = rotation
    }
}
