import UIKit

enum Haptics {
    private static let light = UIImpactFeedbackGenerator(style: .light)
    private static let medium = UIImpactFeedbackGenerator(style: .medium)
    private static let notification = UINotificationFeedbackGenerator()

    static func swipeThreshold() {
        light.prepare()
        light.impactOccurred()
    }

    static func undo() {
        medium.prepare()
        medium.impactOccurred()
    }

    static func commitSuccess() {
        notification.prepare()
        notification.notificationOccurred(.success)
    }

    static func noMorePhotos() {
        notification.prepare()
        notification.notificationOccurred(.warning)
    }
}
