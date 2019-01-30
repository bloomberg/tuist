import Basic
import Foundation
import TuistCore

public struct GeneratorConfig {

    public static let `default` =  GeneratorConfig()

    public var options: GenerationOptions
    public var directory: GenerationDirectory

    public init(options: GenerationOptions = GenerationOptions(),
                directory: GenerationDirectory = .manifest) {
        self.options = options
        self.directory = directory
    }
}

public protocol Generating {

    @discardableResult
    func generateProject(at path: AbsolutePath, config: GeneratorConfig) throws -> AbsolutePath

    @discardableResult
    func generateWorkspace(at path: AbsolutePath, config: GeneratorConfig) throws -> AbsolutePath
}

public extension Generating {

    @discardableResult
    func generateProject(at path: AbsolutePath) throws -> AbsolutePath {
        return try generateProject(at: path, config: GeneratorConfig.default)
    }

    @discardableResult
    func generateWorkspace(at path: AbsolutePath) throws -> AbsolutePath {
        return try generateWorkspace(at: path, config: GeneratorConfig.default)
    }
}

public class Generator: Generating {

    private let graphLoader: GraphLoading
    private let modelLoader: ModelLoading
    private let workspaceGenerator: WorkspaceGenerating

    public init(system: Systeming = System(),
                printer: Printing = Printer(),
                resourceLocator: ResourceLocating = ResourceLocator(),
                modelLoader: ModelLoading) {
        self.modelLoader = modelLoader
        self.graphLoader = GraphLoader(printer: printer)
        self.workspaceGenerator = WorkspaceGenerator(system: system,
                                                     printer: printer,
                                                     resourceLocator: resourceLocator,
                                                     modelLoader: modelLoader)
    }

    public func generateProject(at path: AbsolutePath, config: GeneratorConfig) throws -> AbsolutePath {
        let graph = try graphLoader.loadProject(path: path, modelLoader: modelLoader)

        return try workspaceGenerator.generate(path: path,
                                               graph: graph,
                                               options: config.options,
                                               directory: config.directory)
    }

    public func generateWorkspace(at path: AbsolutePath, config: GeneratorConfig) throws -> AbsolutePath {
        let graph = try graphLoader.loadWorkspace(path: path, modelLoader: modelLoader)

        return try workspaceGenerator.generate(path: path,
                                               graph: graph,
                                               options: config.options,
                                               directory: config.directory)
    }
}
