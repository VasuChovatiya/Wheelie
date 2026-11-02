import Foundation

// MARK: - Easing

/// Returns the eased progress for a quartic ease-out curve.
///
/// - Parameter t: Normalised time in `[0, 1]`.
/// - Returns: Eased value in `[0, 1]`.
public func easeOutQuart(_ t: Double) -> Double {
    1 - pow(1 - t, 4)
}
