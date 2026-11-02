import Foundation

// MARK: - Angle normalisation

/// Normalises an angle in degrees to [0, 360).
@inline(__always)
public func norm(_ x: Double) -> Double {
    ((x.truncatingRemainder(dividingBy: 360)) + 360).truncatingRemainder(dividingBy: 360)
}

// MARK: - wedgeIndexAt

/// Returns the index of the segment that contains `localAngle`.
///
/// - Parameters:
///   - localAngle: The angle to test, in degrees (clockwise, 0° = 12 o'clock).
///   - segments: The wheel segments (used to compute their spans).
/// - Returns: The zero-based index of the hit segment.
public func wedgeIndexAt(_ localAngle: Double, segments: [WheelSegment]) -> Int {
    guard !segments.isEmpty else { return 0 }

    let layouts = layout(segments: segments)

    // Normalise the test angle relative to the start of the first segment.
    let start0 = layouts[0].start
    let s = norm(localAngle - start0)

    var cumulative = 0.0
    for (i, l) in layouts.enumerated() {
        cumulative += l.span
        if s < cumulative {
            return i
        }
    }
    // Boundary belongs to the clockwise wedge; fall back to last segment.
    return segments.count - 1
}
