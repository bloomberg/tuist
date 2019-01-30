import Basic
import Foundation
import TuistCore

public class Workspace: Equatable {
    // MARK: - Attributes
    public let name: String
    public let projects: [AbsolutePath]

    // MARK: - Init
    public init(name: String, projects: [AbsolutePath]) {
        self.name = name
        self.projects = projects
    }

    // MARK: - Internal
    static func at(_ path: AbsolutePath, modelLoader: ModelLoading) throws -> Workspace {
        return try modelLoader.loadWorkspace(at: path) // TODO: Maybe not needed at all
    }

    // MARK: - Equatable
    public static func == (lhs: Workspace, rhs: Workspace) -> Bool {
        return lhs.projects == rhs.projects
    }
}