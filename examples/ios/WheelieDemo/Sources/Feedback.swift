import AudioToolbox
import UIKit

// MARK: - Feedback

/// The app's own haptics and sound. Wheelie only emits events; the app decides what to play.
@MainActor
enum Feedback {
    private static let impact = UIImpactFeedbackGenerator(style: .light)
    private static let selection = UISelectionFeedbackGenerator()
    private static let notification = UINotificationFeedbackGenerator()

    /// System "tock" click, the same sound as the keyboard.
    private static let tickSound: SystemSoundID = 1104

    static func prepare() {
        selection.prepare()
        notification.prepare()
    }

    static func tap() {
        impact.impactOccurred()
    }

    static func tick(sound: Bool) {
        selection.selectionChanged()
        if sound {
            AudioServicesPlaySystemSound(tickSound)
        }
    }

    static func land() {
        notification.notificationOccurred(.success)
    }
}
