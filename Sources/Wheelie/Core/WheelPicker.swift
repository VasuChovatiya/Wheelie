import Foundation

// MARK: - pickIndex

/// Selects a winning segment index using weighted random selection.
///
/// Segments with `weight == 0` are excluded. If all weights are zero, returns `nil`.
///
/// - Parameters:
///   - weights: The weight of each segment (parallel to the segments array).
///   - r: A random value in `[0, 1)`.
/// - Returns: The selected segment index, or `nil` if no segment is eligible.
public func pickIndex(weights: [Double], r: Double) -> Int? {
    let total = weights.reduce(0, +)
    guard total > 0 else { return nil }

    let x = r * total
    var running = 0.0
    var lastPositive: Int?

    for (i, weight) in weights.enumerated() {
        guard weight > 0 else { continue }
        lastPositive = i
        running += weight
        if x < running {
            return i
        }
    }

    return lastPositive
}
