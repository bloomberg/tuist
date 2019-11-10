import Basic
import Foundation
import TuistGenerator
import TuistSupport

class ManifestModelLoader: GeneratorModelLoading {
    enum Error: FatalError {
        case notSupported(String)
        var type: ErrorType {
            switch self {
            case .notSupported:
                return .bug
            }
        }

        var description: String {
            switch self {
            case let .notSupported(message):
                return message
            }
        }
    }

    private let manifestLoader: GraphManifestLoading
    private let manifestTargetGenerator: ManifestTargetGenerating
    init(manifestLoader: GraphManifestLoading,
         manifestTargetGenerator: ManifestTargetGenerating) {
        self.manifestLoader = manifestLoader
        self.manifestTargetGenerator = manifestTargetGenerator
    }

    func loadProject(at path: AbsolutePath) throws -> Project {
        let manifestName: String
        if manifestLoader.manifests(at: path).contains(.workspace) {
            let manifest = try manifestLoader.loadWorkspace(at: path)
            manifestName = manifest.name
        } else {
            let manifest = try manifestLoader.loadProject(at: path)
            manifestName = manifest.name
        }

        return try manifestProject(manifestName: manifestName, path: path)
    }

    func loadWorkspace(at _: AbsolutePath) throws -> Workspace {
        throw Error.notSupported("Generating manifest workspaces is currently not supported.")
    }

    func loadTuistConfig(at _: AbsolutePath) throws -> TuistConfig {
        return .default
    }

    // MARK: -

    private func manifestProject(manifestName: String, path: AbsolutePath) throws -> Project {
        let manifestTarget = try manifestTargetGenerator.generateManifestTarget(for: manifestName,
                                                                                at: path)
        let name = "\(manifestName)_Manifest"
        return Project(path: path,
                       name: name,
                       settings: .default,
                       filesGroup: .group(name: "Manifest"),
                       targets: [manifestTarget],
                       packages: [],
                       schemes: [])
    }
}
