import Foundation

// MARK: - Platform

public enum Platform: String, Codable {
    case iOS = "ios"
    case macOS = "macos"
    case watchOS = "watchos"
    case tvOS = "tvos"

    public var caseValue: String {
        switch self {
        case .iOS: return "iOS"
        case .macOS: return "macOS"
        case .watchOS: return "watchOS"
        case .tvOS: return "tvOS"
        }
    }
}
