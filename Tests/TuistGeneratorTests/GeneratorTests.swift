import Basic
import XCTest
import TuistCore
@testable import TuistCoreTesting
@testable import TuistGenerator

class GeneratorTests: XCTestCase {
    var workspaceGenerator: MockWorkspaceGenerator!
    var graphLoader: MockGraphLoader!
    var subject: Generator!

    override func setUp() {
        graphLoader = MockGraphLoader()
        workspaceGenerator = MockWorkspaceGenerator()

        subject = Generator(graphLoader: graphLoader,
                            workspaceGenerator: workspaceGenerator)
    }

    // MARK: - Tests

    func test_generateWorkspace_mergeGraphProjects() throws {
        // Given
        let workpsace = Workspace.test(projects: [
            "/path/to/A",
            "/path/to/B",
        ])
        let graph = createGraph(with: [
            Project.test(path: "/path/to/A"),
            Project.test(path: "/path/to/B"),
            Project.test(path: "/path/to/C"),
        ])
        graphLoader.loadWorkspaceStub = { _ in
            (graph, workpsace)
        }

        // When
        _ = try subject.generateWorkspace(at: "/path/to", workspaceFiles: [])

        // Then
        let projectPaths = workspaceGenerator.generateWorkspaces.flatMap {
            $0.projects
        }
        XCTAssertEqual(Set(projectPaths), Set([
            "/path/to/A",
            "/path/to/B",
            "/path/to/C",
        ]))
    }

    func test_generateProject_workspaceIncludesDependencies() throws {
        // Given
        let project = Project.test(path: "/path/to/A")
        let graph = createGraph(with: [
            Project.test(path: "/path/to/A"),
            Project.test(path: "/path/to/B"),
            Project.test(path: "/path/to/C"),
        ])
        graphLoader.loadProjectStub = { _ in
            (graph, project)
        }

        // When
        _ = try subject.generateProject(at: "/path/to", workspaceFiles: [])

        // Then
        let projectPaths = workspaceGenerator.generateWorkspaces.flatMap {
            $0.projects
        }
        XCTAssertEqual(Set(projectPaths), Set([
            "/path/to/A",
            "/path/to/B",
            "/path/to/C",
        ]))
    }

    func test_generateProject_workspaceFiles() throws {
        // Given
        let project = Project.test(path: "/path/to/A")

        let workspaceFiles: [AbsolutePath] = [
            "/path/to/D",
            "/path/to/E",
        ]

        let graph = createGraph(with: [])
        graphLoader.loadProjectStub = { _ in
            (graph, project)
        }

        // When
        _ = try subject.generateProject(at: "/path/to", workspaceFiles: workspaceFiles)

        // Then
        let additionalFiles = workspaceGenerator.generateWorkspaces.flatMap {
            $0.additionalFiles
        }
        XCTAssertEqual(additionalFiles, [
            .file(path: "/path/to/D"),
            .file(path: "/path/to/E"),
        ])
    }

    func test_generateProject_withFrameworks() throws {
        // Given
        let fileHandler = FH(currentPath: AbsolutePath("/path/to"))
        let modelLoadler = MockGeneratorModelLoader(basePath: AbsolutePath("/path/to"))
        let projectLinter = ProjectLinter(targetLinter: TargetLinter(fileHandler: fileHandler),
                                          settingsLinter: SettingsLinter())
        let settings = Settings.test(base: [:],
                                     debug: Configuration(settings: [:], xcconfig: nil),
                                     release: Configuration(settings: [:], xcconfig: nil))
        let graphLoader = GraphLoader(linter: GraphLinter(projectLinter: projectLinter,
                                                          fileHandler: fileHandler),
                                      printer: MockPrinter(),
                                      fileHandler: fileHandler,
                                      modelLoader: modelLoadler)
        subject = Generator(graphLoader: graphLoader, workspaceGenerator: workspaceGenerator)
        let pAt1 = Target.test(name: "pAt1",
                               product: .framework,
                               bundleId: "com.test.bundle",
                               dependencies: [
                                    .project(target: "pBt1", path: RelativePath("../B"))
        ])
        let pAt2 = Target.test(name: "pAt2",
                               product: .framework,
                               bundleId: "com.test.bundle",
                               dependencies: [
                                    .target(name: "pAt1")
        ])
        let pA = Project.test(path: "/path/to/A",
                              settings: settings,
                              targets: [pAt1, pAt2])

        let pBt1 = Target.test(name: "pBt1",
                               product: .framework,
                               bundleId: "com.test.bundle",
                               dependencies: [
                                    .project(target: "pAt1", path: RelativePath("../A"))
        ])
        let pBt2 = Target.test(name: "pBt2",
                               product: .framework,
                               bundleId: "com.test.bundle",
                               dependencies: [
                                    .target(name: "pBt1"),
                                    .project(target: "pAt1", path: RelativePath("../A"))
        ])
        let pB = Project.test(path: "/path/to/B",
                              settings: settings,
                              targets: [pBt1, pBt2])

        modelLoadler.mockProject("A", loadClosure: { _ in pA })
        modelLoadler.mockProject("B", loadClosure: { _ in pB })
        modelLoadler.mockTuistConfig("A", loadClosure: { _ in TuistConfig(generationOptions: []) })

        // When
        _ = try subject.generateProject(at: "/path/to/A", workspaceFiles: [])
    }

    func test_generateWorkspace_workspaceFiles() throws {
        // Given
        let workpsace = Workspace.test(projects: [],
                                       additionalFiles: [
                                           .file(path: "/path/to/a"),
                                           .file(path: "/path/to/b"),
                                           .file(path: "/path/to//c"),
                                       ])
        let graph = createGraph(with: [])
        graphLoader.loadWorkspaceStub = { _ in
            (graph, workpsace)
        }

        // When
        _ = try subject.generateWorkspace(at: "/path/to",
                                          workspaceFiles: [
                                              "/path/to/D",
                                              "/path/to/E",
                                          ])

        // Then
        let additionalFiles = workspaceGenerator.generateWorkspaces.flatMap {
            $0.additionalFiles
        }
        XCTAssertEqual(additionalFiles, [
            .file(path: "/path/to/a"),
            .file(path: "/path/to/b"),
            .file(path: "/path/to/c"),
            .file(path: "/path/to/D"),
            .file(path: "/path/to/E"),
        ])
    }

    // MARK: - Helpers

    func createGraph(with projects: [Project]) -> Graph {
        let cache = GraphLoaderCache()
        projects.forEach { cache.add(project: $0) }

        let graph = Graph.test(cache: cache)
        return graph
    }
}

class MockGeneratorModelLoader: GeneratorModelLoading {
    private var projects = [String: (AbsolutePath) throws -> Project]()
    private var workspaces = [String: (AbsolutePath) throws -> Workspace]()
    private var tuistConfigs = [String: (AbsolutePath) throws -> TuistConfig]()

    private let basePath: AbsolutePath

    init(basePath: AbsolutePath) {
        self.basePath = basePath
    }

    // MARK: - GeneratorModelLoading

    func loadProject(at path: AbsolutePath) throws -> Project {
        return try projects[path.pathString]!(path)
    }

    func loadWorkspace(at path: AbsolutePath) throws -> Workspace {
        return try workspaces[path.pathString]!(path)
    }

    func loadTuistConfig(at path: AbsolutePath) throws -> TuistConfig {
        return try tuistConfigs[path.pathString]!(path)
    }

    // MARK: - Mock

    func mockProject(_ path: String, loadClosure: @escaping (AbsolutePath) throws -> Project) {
        projects[basePath.appending(component: path).pathString] = loadClosure
    }

    func mockWorkspace(_ path: String = "", loadClosure: @escaping (AbsolutePath) throws -> Workspace) {
        workspaces[basePath.appending(component: path).pathString] = loadClosure
    }

    func mockTuistConfig(_ path: String = "", loadClosure: @escaping (AbsolutePath) throws -> TuistConfig) {
        tuistConfigs[basePath.appending(component: path).pathString] = loadClosure
    }
}

class FH: FileHandling {

    var currentPath: AbsolutePath

    init(currentPath: AbsolutePath) {
        self.currentPath = currentPath
    }

    func replace(_ to: AbsolutePath, with: AbsolutePath) throws {

    }

    func exists(_ path: AbsolutePath) -> Bool {
        return true
    }

    func copy(from: AbsolutePath, to: AbsolutePath) throws {

    }

    func readTextFile(_ at: AbsolutePath) throws -> String {
        return ""
    }

    func inTemporaryDirectory(_ closure: (AbsolutePath) throws -> Void) throws {

    }

    func write(_ content: String, path: AbsolutePath, atomically: Bool) throws {

    }

    func glob(_ path: AbsolutePath, glob: String) -> [AbsolutePath] {
        return []
    }

    func createFolder(_ path: AbsolutePath) throws {

    }

    func delete(_ path: AbsolutePath) throws {

    }

    func isFolder(_ path: AbsolutePath) -> Bool {
        return false
    }

    func touch(_ path: AbsolutePath) throws {

    }
}
