import Foundation

enum FormatHelper {
    private static let gbThreshold: Int64 = 1024 * 1024 * 1024

    static func fileSize(_ bytes: Int64) -> String {
        guard bytes > 0 else { return "0 MB" }
        if bytes < gbThreshold {
            let mb = bytes / (1024 * 1024)
            return "\(mb) MB"
        } else {
            let gb = Double(bytes) / Double(gbThreshold)
            return String(format: "%.2f GB", gb)
        }
    }

    static func count(_ n: Int) -> String {
        n == 1 ? String(localized: "1 photo") : String(localized: "\(n) photos")
    }

    static func countAndSize(_ n: Int, bytes: Int64) -> String {
        "\(count(n)) · ~\(fileSize(bytes))"
    }

    static func duration(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds))
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, s) : String(format: "%d:%02d", m, s)
    }
}
