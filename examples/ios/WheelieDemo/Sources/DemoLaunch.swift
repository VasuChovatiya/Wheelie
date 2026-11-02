import SwiftUI
import Wheelie

// MARK: - DemoLaunch

/// Launch arguments used to capture the README screenshots and GIF:
/// `-screen prize|bottle|playground` opens that demo directly, and `-autospin YES` spins it once on open.
@MainActor
enum DemoLaunch {
    static var screen: String? { UserDefaults.standard.string(forKey: "screen") }
    static var autoSpin: Bool { UserDefaults.standard.bool(forKey: "autospin") }

    /// The screen to show at launch: the menu, or the demo named by `-screen`.
    @ViewBuilder
    static var root: some View {
        switch screen {
        case "prize": direct { PrizeWheelScreen() }
        case "bottle": direct { BottleScreen() }
        case "playground": direct { PlaygroundScreen() }
        default: ContentView()
        }
    }

    private static func direct<Screen: View>(@ViewBuilder _ screen: () -> Screen) -> some View {
        NavigationStack { screen() }
            .tint(Theme.ink)
            .preferredColorScheme(.light)
    }
}

// MARK: - Auto spin

extension View {
    /// Spins once, shortly after the screen appears, when launched with `-autospin YES`.
    func autoSpin(_ wheel: WheelController) -> some View {
        task {
            guard DemoLaunch.autoSpin else { return }
            try? await Task.sleep(nanoseconds: 800_000_000)
            _ = await wheel.spin()
        }
    }
}
