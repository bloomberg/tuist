import Basic
import Foundation
@testable import TuistGenerator

final class MockGraphLoader: GraphLoading {

    var loadProjectStub: ((AbsolutePath, ModelLoading) throws -> Graph)?
    var loadWorkspaceStub: ((AbsolutePath, ModelLoading) throws -> Graph)?

    func loadProject(path: AbsolutePath, modelLoader: ModelLoading) throws -> Graph {
        return try loadProjectStub!(path, modelLoader)
    }

    func loadWorkspace(path: AbsolutePath, modelLoader: ModelLoading) throws -> Graph {
        return try loadWorkspaceStub!(path, modelLoader)
    }
}
