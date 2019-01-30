import Basic
import Foundation
import TuistCore

enum ModelLoaderError: FatalError, Equatable {
    case modelNotFound(AbsolutePath)
    case unknownError(AbsolutePath)

    var description: String {
        switch self {
        case let .modelNotFound(path):
            return "Model not found at \(path.asString)"
        case let .unknownError(path):
            return "Unknown error while loading \(path.asString)"
        }
    }

    var type: ErrorType {
        switch self {
        case .modelNotFound:
            return .abort
        case .unknownError:
            return .abort
        }
    }

    // MARK: - Equatable

    static func == (lhs: ModelLoaderError, rhs: ModelLoaderError) -> Bool {
        switch (lhs, rhs) {
        case let (.modelNotFound(lhsPath), .modelNotFound(rhsPath)):
            return lhsPath == rhsPath
        case let (.unknownError(lhsPath), .unknownError(rhsPath)):
            return lhsPath == rhsPath
        default:
            return false
        }
    }
}

public protocol ModelLoading {
    func loadProject(at path: AbsolutePath) throws -> Project
    func loadWorkspace(at path: AbsolutePath) throws -> Workspace
}
