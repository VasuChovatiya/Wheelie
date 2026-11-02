import Foundation

// MARK: - SpinPlan

/// All data needed to animate a single spin to a specific segment.
public struct SpinPlan: Sendable, Equatable {
    /// The segment index the wheel will land on.
    public let targetIndex: Int
    /// The angle (degrees) within the target segment where the pointer lands.
    public let landingAngle: Double
    /// The normalised rest angle that maps the landing position to the pointer.
    public let restAngle: Double
    /// The final `rotation` value that the animation drives to (not normalised, may exceed 360).
    public let targetRotation: Double
    /// Total animation duration in seconds.
    public let duration: TimeInterval
}

// MARK: - SpinPlanner

/// Computes a `SpinPlan` for a spin that lands on `targetIndex`.
///
/// All angles are in degrees, clockwise, 0° = 12 o'clock.
public enum SpinPlanner {

    /// Builds a spin plan.
    ///
    /// - Parameters:
    ///   - targetIndex: The segment the wheel should land on.
    ///   - segments: All wheel segments (used for layout).
    ///   - currentRotation: The current accumulated rotation of the wheel (not normalised).
    ///   - options: Spin configuration.
    ///   - mode: Whether the wheel or the pointer rotates.
    ///   - pointerAngle: The fixed pointer angle (degrees). Default is 0° (12 o'clock).
    ///   - offset: Landing offset within the target segment, in `[-1, 1]`. 0 = centre.
    ///   - turns: Number of full rotations to perform.
    /// - Returns: A `SpinPlan`, or `nil` if `targetIndex` is out of range.
    public static func plan( // swiftlint:disable:this function_parameter_count - one per input in docs/spec.md
        targetIndex: Int,
        segments: [WheelSegment],
        currentRotation: Double,
        options: SpinOptions,
        mode: WheelMode,
        pointerAngle: Double = 0,
        offset: Double = 0,
        turns: Double
    ) -> SpinPlan? {
        let layouts = layout(segments: segments)
        guard targetIndex >= 0, targetIndex < layouts.count else { return nil }

        let l = layouts[targetIndex]

        // Where within the target segment the pointer should land
        let clampedOffset = max(-1, min(1, offset))
        let spread = options.spread
        let landingAngle = l.center + clampedOffset * spread * l.span / 2

        // restAngle: the wheel rotation (normalised) needed so that
        // the landing angle coincides with the pointer.
        let restAngle: Double
        switch mode {
        case .wheel:
            restAngle = norm(pointerAngle - landingAngle)
        case .pointer:
            restAngle = norm(landingAngle - pointerAngle)
        }

        let targetRotation: Double
        switch options.direction {
        case .clockwise:
            let base = currentRotation + turns * 360
            targetRotation = base + norm(restAngle - base)
        case .counterClockwise:
            let base = currentRotation - turns * 360
            targetRotation = base - norm(base - restAngle)
        }

        let duration = options.durationForTurns(turns)

        return SpinPlan(
            targetIndex: targetIndex,
            landingAngle: landingAngle,
            restAngle: restAngle,
            targetRotation: targetRotation,
            duration: duration
        )
    }
}
