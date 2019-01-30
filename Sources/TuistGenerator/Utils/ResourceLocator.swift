import Basic
import Foundation
import TuistCore

public protocol ResourceLocating: AnyObject {
    func productsDirectoryPath() throws -> AbsolutePath
}

enum ResourceLocatingError: FatalError {
    case notFound(String)

    var description: String {
        switch self {
        case let .notFound(name):
            return "Couldn't find \(name)"
        }
    }

    var type: ErrorType {
        switch self {
        default:
            return .bug
        }
    }

    static func == (lhs: ResourceLocatingError, rhs: ResourceLocatingError) -> Bool {
        switch (lhs, rhs) {
        case let (.notFound(lhsPath), .notFound(rhsPath)):
            return lhsPath == rhsPath
        }
    }
}

final public class ResourceLocator: ResourceLocating {
    private let fileHandler: FileHandling

    // MARK: - Init

    public init(fileHandler: FileHandling = FileHandler()) {
        self.fileHandler = fileHandler
    }

    // MARK: - ResourceLocating

    public func productsDirectoryPath() throws -> AbsolutePath {
        return try projectDescription().parentDirectory
    }

    // MARK: - Fileprivate

    fileprivate func projectDescription() throws -> AbsolutePath {
        return try frameworkPath("ProjectDescription")
    }

    fileprivate func frameworkPath(_ name: String) throws -> AbsolutePath {
        let frameworkNames = ["\(name).framework", "lib\(name).dylib"]
        let bundlePath = AbsolutePath(Bundle(for: ResourceLocator.self).bundleURL.path)
        let paths = [bundlePath, bundlePath.parentDirectory]
        let candidates = paths.flatMap { path in
            frameworkNames.map({ path.appending(component: $0) })
        }
        guard let frameworkPath = candidates.first(where: { fileHandler.exists($0) }) else {
            throw ResourceLocatingError.notFound(name)
        }
        return frameworkPath
    }

    fileprivate func toolPath(_ name: String) throws -> AbsolutePath {
        let bundlePath = AbsolutePath(Bundle(for: ResourceLocator.self).bundleURL.path)
        let paths = [bundlePath, bundlePath.parentDirectory]
        let candidates = paths.map { $0.appending(component: name) }
        guard let path = candidates.first(where: { fileHandler.exists($0) }) else {
            throw ResourceLocatingError.notFound(name)
        }
        return path
    }
}
