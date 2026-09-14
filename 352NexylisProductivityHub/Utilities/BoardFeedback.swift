import AudioToolbox
import UIKit

enum BoardFeedback {
    static func pulseEnded(sound: Bool, haptic: Bool) {
        if haptic {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
        if sound {
            AudioServicesPlaySystemSound(1007)
        }
    }

    static func tap(haptic: Bool) {
        guard haptic else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}
