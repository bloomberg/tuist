import Basic
import Foundation
import TuistCore

public class Project: Equatable {
    // MARK: - Attributes
    /// Path to the folder that contains the project manifest.
    public let path: AbsolutePath

    /// Project name.
    public let name: String

    /// Project targets.
    public let targets: [Target]

    /// Project settings.
    public let settings: Settings?

    // MARK: - Init
    /// Initializes the project with its attributes.
    ///
    /// - Parameters:
    ///   - path: Path to the folder that contains the project manifest.
    ///   - name: Project name.
    ///   - up: Up instances to configure the environment for the project.
    ///   - targets: Project settings.
    public init(path: AbsolutePath,
                name: String,
                settings: Settings? = nil,
                targets: [Target]) {
        self.path = path
        self.name = name
        self.targets = targets
        self.settings = settings
    }

    // MARK: - Internal
    /// Parses the project manifest at the given path and returns a Project instance with the representation.
    ///
    /// - Parameters:
    ///   - path: Path to the folder that contains the project manifest.
    ///   - cache: Cache instance to cache projects and dependencies.
    ///   - circularDetector: Utility to find circular dependencies between targets.
    /// - Returns: Initialized project.
    /// - Throws: An error if the project has an invalid format.
    static func at(_ path: AbsolutePath,
                   cache: GraphLoaderCaching,
                   circularDetector: GraphCircularDetecting,
                   modelLoader: ModelLoading) throws -> Project {
        if let project = cache.project(path) {
            return project
        } else {
            let project = try modelLoader.loadProject(at: path)
            cache.add(project: project)

            for target in project.targets {
                if cache.targetNode(path, name: target.name) != nil { continue }
                _ = try TargetNode.read(name: target.name,
                                        path: path,
                                        cache: cache,
                                        circularDetector: circularDetector,
                                        modelLoader: modelLoader)
            }

            return project
        }
    }

    // MARK: - Equatable
    public static func == (lhs: Project, rhs: Project) -> Bool {
        return lhs.path == rhs.path &&
            lhs.name == rhs.name &&
            lhs.targets == rhs.targets &&
            lhs.settings == rhs.settings
    }
}
