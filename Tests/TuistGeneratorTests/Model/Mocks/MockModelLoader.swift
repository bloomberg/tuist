import Basic
@testable import TuistGenerator

class MockModelLoader: ModelLoading {

    var loadProjectStub: ((AbsolutePath) throws -> Project)?
    var loadWorkspaceStub: ((AbsolutePath) throws -> Workspace)?

    func loadProject(at path: AbsolutePath) throws -> Project {
        return try loadProjectStub!(path)
    }

    func loadWorkspace(at path: AbsolutePath) throws -> Workspace {
        return try loadWorkspaceStub!(path)
    }
}
