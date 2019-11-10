import Basic
import Foundation

enum OpeningError: FatalError, Equatable {
    case notFound(AbsolutePath)

    var type: ErrorType {
        switch self {
        case .notFound:
            return .bug
        }
    }

    var description: String {
        switch self {
        case let .notFound(path):
            return "Couldn't open file at path \(path.pathString)"
        }
    }

    static func == (lhs: OpeningError, rhs: OpeningError) -> Bool {
        switch (lhs, rhs) {
        case let (.notFound(lhsPath), .notFound(rhsPath)):
            return lhsPath == rhsPath
        }
    }
}

public protocol Opening: AnyObject {
    func open(path: AbsolutePath) throws
    func open(path: AbsolutePath,
              newInstance: Bool,
              blocking: Bool) throws
}

public class Opener: Opening {
    public init() {}

    // MARK: - Opening

    public func open(path: AbsolutePath) throws {
        try open(path: path, newInstance: false, blocking: false)
    }

    public func open(path: AbsolutePath,
                     newInstance: Bool,
                     blocking: Bool) throws {
        if !FileHandler.shared.exists(path) {
            throw OpeningError.notFound(path)
        }
        var command = [
            "/usr/bin/open",
            path.pathString,
        ]
        if newInstance {
            command.append("-n")
        }
        if blocking {
            command.append("-W")
        }
        try System.shared.runAndPrint(command)
    }
}
