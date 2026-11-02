import Foundation

// MARK: - SpinDirection

/// The rotational direction of a spin.
public enum SpinDirection: Sendable, Hashable {
    case clockwise
    case counterClockwise
}

// MARK: - SpinOptions

/// Configuration for a single spin.
public struct SpinOptions: Sendable, Equatable {

    // MARK: Duration Mode

    /// Determines how the spin duration is computed.
    public enum DurationMode: Sendable, Equatable {
        /// Duration grows with the number of turns: `base + turns * perTurn`.
        case byTurns(base: TimeInterval, perTurn: TimeInterval)
        /// A fixed duration regardless of turn count.
        case fixed(TimeInterval)
    }

    // MARK: Properties

    /// The range of full turns the wheel makes. A random value is sampled from this range. Default is `3...5`.
    public var turns: ClosedRange<Double>

    /// How the animation duration is computed. Default is `.byTurns(base: 3.2, perTurn: 0.35)`.
    public var duration: DurationMode

    /// The rotational direction. Default is `.clockwise`.
    public var direction: SpinDirection

    /// Fraction of a segment's span that the pointer may land away from centre. Default is `0.7`.
    public var spread: Double

    /// Minimum interval between consecutive `onSegmentPass` callbacks. Default is `0.045` seconds.
    public var minTickInterval: TimeInterval

    /// When `true` and the system Reduce Motion setting is active, the spin is shortened
    /// (1 turn, 0.8 s). Default is `true`.
    public var respectsReduceMotion: Bool

    // MARK: Init

    public init(
        turns: ClosedRange<Double> = 3...5,
        duration: DurationMode = .byTurns(base: 3.2, perTurn: 0.35),
        direction: SpinDirection = .clockwise,
        spread: Double = 0.7,
        minTickInterval: TimeInterval = 0.045,
        respectsReduceMotion: Bool = true
    ) {
        self.turns = turns
        self.duration = duration
        self.direction = direction
        self.spread = spread
        self.minTickInterval = minTickInterval
        self.respectsReduceMotion = respectsReduceMotion
    }

    // MARK: Internal helpers

    /// Returns the computed animation duration for the given number of turns.
    internal func durationForTurns(_ turns: Double) -> TimeInterval {
        switch duration {
        case .byTurns(let base, let perTurn):
            return base + turns * perTurn
        case .fixed(let t):
            return t
        }
    }

    /// A copy of the options adjusted for the Reduce Motion accessibility setting.
    internal var reduceMotionVariant: SpinOptions {
        var copy = self
        copy.turns = 1...1
        copy.duration = .fixed(0.8)
        return copy
    }
}
