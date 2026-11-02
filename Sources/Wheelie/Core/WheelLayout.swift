import Foundation

// MARK: - SegmentLayout

/// Pre-computed angular layout for one wheel segment.
public struct SegmentLayout: Sendable, Equatable {
    /// Angular span of the wedge in degrees.
    public let span: Double
    /// Start angle (degrees, clockwise, 0° = 12 o'clock).
    public let start: Double
    /// Centre angle (degrees, clockwise, 0° = 12 o'clock).
    public let center: Double
}

// MARK: - Layout function

/// Computes the angular layout for each segment.
///
/// Angles are in degrees, clockwise, with 0° at 12 o'clock.
/// The first segment is centred on 0° (12 o'clock), so its start is at `-span_0 / 2`.
///
/// - Parameter segments: The wheel segments.
/// - Returns: One `SegmentLayout` per segment in the same order.
public func layout(segments: [WheelSegment]) -> [SegmentLayout] {
    guard !segments.isEmpty else { return [] }

    let totalSize = segments.reduce(0) { $0 + $1.size }
    guard totalSize > 0 else {
        // Degenerate: equal spans
        let span = totalSize == 0 ? 360.0 / Double(segments.count) : 0
        var results: [SegmentLayout] = []
        var cursor = -span / 2
        for _ in segments {
            results.append(SegmentLayout(span: span, start: cursor, center: cursor + span / 2))
            cursor += span
        }
        return results
    }

    var results: [SegmentLayout] = []
    // First segment centred at 0°
    let span0 = 360.0 * segments[0].size / totalSize
    var cursor = -span0 / 2

    for segment in segments {
        let span = 360.0 * segment.size / totalSize
        let center = cursor + span / 2
        results.append(SegmentLayout(span: span, start: cursor, center: center))
        cursor += span
    }

    return results
}
