import Basic
import Foundation
import TuistCore
import Yams

enum ManifestLoaderError: FatalError, Equatable {
    case projectDescriptionNotFound(AbsolutePath)
    case unexpectedOutput(AbsolutePath)
    case invalidYaml(AbsolutePath)
    case manifestNotFound(Manifest?, AbsolutePath)
    case missingFile(AbsolutePath)
    case setupNotFound(AbsolutePath)

    var description: String {
        switch self {
        case let .projectDescriptionNotFound(path):
            return "Couldn't find ProjectDescription.framework at path '\(path.asString)'"
        case let .unexpectedOutput(path):
            return "Unexpected output trying to parse the manifest at path '\(path.asString)'"
        case let .invalidYaml(path):
            return "Invalid yaml at path \(path.asString). The root element should be a dictionary"
        case let .manifestNotFound(manifest, path):
            return "\(manifest?.fileName.capitalized ?? "Manifest") not found at path '\(path.asString)'"
        case let .missingFile(path):
            return "Couldn't find file at path '\(path.asString)'"
        case let .setupNotFound(path):
            return "Setup.swift not found at path '\(path.asString)'"
        }
    }

    var type: ErrorType {
        switch self {
        case .unexpectedOutput:
            return .bug
        case .projectDescriptionNotFound:
            return .bug
        case .invalidYaml:
            return .abort
        case .manifestNotFound:
            return .abort
        case .missingFile:
            return .abort
        case .setupNotFound:
            return .abort
        }
    }

    // MARK: - Equatable

    static func == (lhs: ManifestLoaderError, rhs: ManifestLoaderError) -> Bool {
        switch (lhs, rhs) {
        case let (.projectDescriptionNotFound(lhsPath), .projectDescriptionNotFound(rhsPath)):
            return lhsPath == rhsPath
        case let (.unexpectedOutput(lhsPath), .unexpectedOutput(rhsPath)):
            return lhsPath == rhsPath
        case let (.invalidYaml(lhsPath), .invalidYaml(rhsPath)):
            return lhsPath == rhsPath
        case let (.manifestNotFound(lhsManifest, lhsPath), .manifestNotFound(rhsManifest, rhsPath)):
            return lhsManifest == rhsManifest && lhsPath == rhsPath
        case let (.missingFile(lhsPath), .missingFile(rhsPath)):
            return lhsPath == rhsPath
        case let (.setupNotFound(lhsPath), .setupNotFound(rhsPath)):
            return lhsPath == rhsPath
        default:
            return false
        }
    }
}

enum Manifest {
    case project
    case workspace

    var fileName: String {
        switch self {
        case .project:
            return "Project"
        case .workspace:
            return "Workspace"
        }
    }

    static var supportedExtensions: Set<String> = Set(arrayLiteral: "json", "swift", "yaml", "yml")
}
