import SwiftUI

// MARK: - Environment Keys

// --- WheelStyle ---

struct WheelStyleKey: EnvironmentKey {
    static let defaultValue = WheelStyle()
}

// --- Pointer ---

struct WheelPointerKey: EnvironmentKey {
    static var defaultValue: AnyView? { nil }
}

// --- Pointer angle ---

struct WheelPointerAngleKey: EnvironmentKey {
    static let defaultValue: Double = 0
}

// --- Hub ---

struct WheelHubKey: EnvironmentKey {
    static var defaultValue: ((Int) -> AnyView)? { nil }
}

// --- Highlights ---

struct WheelHighlightKey: EnvironmentKey {
    static let defaultValue: [WheelHighlight] = []
}

// --- Callbacks ---

struct WheelOnSpinStartKey: EnvironmentKey {
    static var defaultValue: ((WheelSpinStart) -> Void)? { nil }
}

struct WheelOnSegmentPassKey: EnvironmentKey {
    static var defaultValue: ((Int) -> Void)? { nil }
}

struct WheelOnLandKey: EnvironmentKey {
    static var defaultValue: ((WheelResult) -> Void)? { nil }
}

// MARK: - EnvironmentValues extension

extension EnvironmentValues {
    var wheelStyle: WheelStyle {
        get { self[WheelStyleKey.self] }
        set { self[WheelStyleKey.self] = newValue }
    }

    var wheelPointer: AnyView? {
        get { self[WheelPointerKey.self] }
        set { self[WheelPointerKey.self] = newValue }
    }

    var wheelPointerAngle: Double {
        get { self[WheelPointerAngleKey.self] }
        set { self[WheelPointerAngleKey.self] = newValue }
    }

    var wheelHub: ((Int) -> AnyView)? {
        get { self[WheelHubKey.self] }
        set { self[WheelHubKey.self] = newValue }
    }

    var wheelHighlights: [WheelHighlight] {
        get { self[WheelHighlightKey.self] }
        set { self[WheelHighlightKey.self] = newValue }
    }

    var wheelOnSpinStart: ((WheelSpinStart) -> Void)? {
        get { self[WheelOnSpinStartKey.self] }
        set { self[WheelOnSpinStartKey.self] = newValue }
    }

    var wheelOnSegmentPass: ((Int) -> Void)? {
        get { self[WheelOnSegmentPassKey.self] }
        set { self[WheelOnSegmentPassKey.self] = newValue }
    }

    var wheelOnLand: ((WheelResult) -> Void)? {
        get { self[WheelOnLandKey.self] }
        set { self[WheelOnLandKey.self] = newValue }
    }
}

// MARK: - View modifiers

extension View {

    /// Applies a `WheelStyle` to the wheel.
    public func wheelStyle(_ style: WheelStyle) -> some View {
        environment(\.wheelStyle, style)
    }

    /// Sets a custom pointer view for the wheel.
    public func wheelPointer<P: View>(@ViewBuilder _ pointer: @escaping () -> P) -> some View {
        environment(\.wheelPointer, AnyView(pointer()))
    }

    /// Sets the angle at which the pointer is positioned (degrees, clockwise, 0° = 12 o'clock).
    public func wheelPointerAngle(_ degrees: Double) -> some View {
        environment(\.wheelPointerAngle, degrees)
    }

    /// Sets a custom hub view for the centre of the wheel.
    ///
    /// - Parameter hub: A closure that receives the currently landed segment index (or 0 before
    ///   any spin) and returns the hub view.
    public func wheelHub<H: View>(@ViewBuilder _ hub: @escaping (Int) -> H) -> some View {
        environment(\.wheelHub, { AnyView(hub($0)) })
    }

    /// Configures the highlights shown after the wheel lands.
    public func wheelHighlight(_ highlights: [WheelHighlight]) -> some View {
        environment(\.wheelHighlights, highlights)
    }

    /// Registers a callback that fires when a spin animation begins.
    public func onSpinStart(_ action: @escaping (WheelSpinStart) -> Void) -> some View {
        environment(\.wheelOnSpinStart, action)
    }

    /// Registers a callback that fires each time the pointer crosses a new segment boundary.
    public func onSegmentPass(_ action: @escaping (Int) -> Void) -> some View {
        environment(\.wheelOnSegmentPass, action)
    }

    /// Registers a callback that fires when the wheel comes to rest.
    public func onLand(_ action: @escaping (WheelResult) -> Void) -> some View {
        environment(\.wheelOnLand, action)
    }
}
