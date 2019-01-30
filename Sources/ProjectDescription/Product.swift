import Foundation

// MARK: - Product

public enum Product: String, Codable {
    case app
    case staticLibrary = "static_library"
    case dynamicLibrary = "dynamic_library"
    case framework
    case unitTests = "unit_tests"
    case uiTests = "ui_tests"

    public var caseValue: String {
        switch self {
        case .app:
            return "app"
        case .staticLibrary:
            return "staticLibrary"
        case .dynamicLibrary:
            return "dynamicLibrary"
        case .framework:
            return "framework"
        case .unitTests:
            return "unitTests"
        case .uiTests:
            return "uiTests"
        }
    }
    // Not supported yet
//    case appExtension
//    case watchApp
//    case watch2App
//    case watchExtension
//    case watch2Extension
//    case tvExtension
//    case messagesApplication
//    case messagesExtension
//    case stickerPack
}
