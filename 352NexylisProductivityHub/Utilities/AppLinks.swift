import StoreKit
import UIKit

enum AppLinks: String {
    case privacy = "https://nexylisproductivityhub352.site/privacy/464"
    case terms = "https://nexylisproductivityhub352.site/terms/464"

    static func rateApp() {
        let scenes = UIApplication.shared.connectedScenes.compactMap { scene in
            scene as? UIWindowScene
        }
        let windowScene = scenes.first(where: { scene in
            scene.activationState == .foregroundActive
        }) ?? scenes.first
        if let windowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }
}
