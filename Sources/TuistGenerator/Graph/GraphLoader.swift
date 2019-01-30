import Basic
import Foundation
import TuistCore

protocol GraphLoading: AnyObject {

    func loadProject(path: AbsolutePath, modelLoader: ModelLoading) throws -> Graph

    func loadWorkspace(path: AbsolutePath, modelLoader: ModelLoading) throws -> Graph
}

class GraphLoader: GraphLoading {
    // MARK: - Attributes

    let linter: GraphLinting
    let printer: Printing
    let fileHandler: FileHandling

    // MARK: - Init

    init(linter: GraphLinting = GraphLinter(),
         printer: Printing = Printer(),
         fileHandler: FileHandling = FileHandler()) {
        self.linter = linter
        self.printer = printer
        self.fileHandler = fileHandler
    }

    func loadProject(path: AbsolutePath, modelLoader: ModelLoading) throws -> Graph {
        let cache = GraphLoaderCache()
        let circularDetector = GraphCircularDetector()
        let project = try Project.at(path,
                                     cache: cache,
                                     circularDetector: circularDetector,
                                     modelLoader: modelLoader)
        let entryNodes: [GraphNode] = try project.targets
            .map { $0.name }
            .map { targetName in try TargetNode.read(name: targetName,
                                                     path: path,
                                                     cache: cache,
                                                     circularDetector: circularDetector,
                                                     modelLoader: modelLoader) }
        let graph = Graph(name: project.name,
                          entryPath: path,
                          cache: cache,
                          entryNodes: entryNodes)
        try lintGraph(graph)
        return graph
    }

    func loadWorkspace(path: AbsolutePath, modelLoader: ModelLoading) throws -> Graph {
        let cache = GraphLoaderCache()
        let circularDetector = GraphCircularDetector()
        let workspace = try Workspace.at(path, modelLoader: modelLoader)
        let projects = try workspace.projects.map { (projectPath) -> (AbsolutePath, Project) in
            return try (projectPath, Project.at(projectPath,
                                                cache: cache,
                                                circularDetector: circularDetector,
                                                modelLoader: modelLoader))
        }
        let entryNodes = try projects.flatMap { (project) -> [TargetNode] in
            return try project.1.targets
                .map { $0.name }
                .map { targetName in try TargetNode.read(name: targetName,
                                                         path: project.0,
                                                         cache: cache,
                                                         circularDetector: circularDetector,
                                                         modelLoader: modelLoader) }
        }
        let graph = Graph(name: workspace.name,
                          entryPath: path,
                          cache: cache,
                          entryNodes: entryNodes)
        try lintGraph(graph)
        return graph
    }

    // MARK: - Private

    private func lintGraph(_ graph: Graph) throws {
        try linter.lint(graph: graph).printAndThrowIfNeeded(printer: printer)
    }
}
