import Basic
import Foundation
import TuistGenerator

class MockGenerator: Generating {

    var generateProjectStub: ((AbsolutePath, GeneratorConfig) throws -> AbsolutePath)?
    private(set) var generateProjectCount: UInt = 0

    var generateWorkspaceStub: ((AbsolutePath, GeneratorConfig) throws -> AbsolutePath)?
    private(set) var generateWorkspaceCount: UInt = 0

    func generateProject(at path: AbsolutePath, config: GeneratorConfig) throws -> AbsolutePath {
        return try generateProjectStub?(path, config) ?? AbsolutePath("/")
    }

    func generateWorkspace(at path: AbsolutePath, config: GeneratorConfig) throws -> AbsolutePath {
        return try generateWorkspaceStub?(path, config) ?? AbsolutePath("/")
    }
}
