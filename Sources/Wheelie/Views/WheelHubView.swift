import SwiftUI

// MARK: - WheelHubView

/// The default hub displayed at the centre of the wheel.
public struct WheelHubView: View {
    public init() {}

    public var body: some View {
        Circle()
            .fill(Color.white)
            .frame(width: 32, height: 32)
            .shadow(radius: 2)
    }
}
