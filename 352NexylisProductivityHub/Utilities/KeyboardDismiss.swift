import UIKit

enum BoardKeyboard {
    static func dismiss() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

final class KeyboardTapDismisser: NSObject, UIGestureRecognizerDelegate {
    static let shared = KeyboardTapDismisser()

    private weak var attachedWindow: UIWindow?
    private var recognizer: UITapGestureRecognizer?

    func attach(to window: UIWindow) {
        if attachedWindow === window, recognizer != nil { return }
        if let recognizer, let attachedWindow {
            attachedWindow.removeGestureRecognizer(recognizer)
        }
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        tap.cancelsTouchesInView = false
        tap.delegate = self
        window.addGestureRecognizer(tap)
        recognizer = tap
        attachedWindow = window
    }

    @objc private func handleTap() {
        attachedWindow?.endEditing(true)
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        var node = touch.view
        while let current = node {
            if current is UITextField || current is UITextView {
                return false
            }
            if current.isFirstResponder {
                return false
            }
            let name = NSStringFromClass(type(of: current))
            if name.contains("TextField") || name.contains("TextView") || name.contains("TextInput") {
                return false
            }
            node = current.superview
        }
        return true
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        true
    }
}
