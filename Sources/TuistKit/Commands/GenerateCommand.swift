import Basic
import Foundation
import TuistCore
import TuistGenerator
import Utility

class GenerateCommand: NSObject, Command {
    // MARK: - Static

    /// Command name that is used for the CLI.
    static let command = "generate"

    /// Command description that is shown when using help from the CLI.
    static let overview = "Generates an Xcode workspace to start working on the project."

    // MARK: - Attributes

    /// Generator instance handling generation process.
    fileprivate let generator: Generating

    /// Printer instance to output updates during the process.
    fileprivate let printer: Printing

    /// ManifestLoader instance to parse Project.swift or Workspace.swift files.
    fileprivate let manifestLoader: ManifestLoading

    let pathArgument: OptionArgument<String>

    // MARK: - Init

    required convenience init(parser: ArgumentParser) {
        let printer = Printer()
        let system = System()
        let fileHandler = FileHandler()
        let resourceLocator = ResourceLocator(fileHandler: fileHandler)
        let deprecator = Deprecator(printer: printer)
        let manifestLoader = ManifestLoader(fileHandler: fileHandler,
                                            system: system,
                                            resourceLocator: resourceLocator,
                                            deprecator: deprecator)
        let generator = GeneratorFactory.create(printer: printer,
                                                system: system,
                                                fileHandler: fileHandler)
        self.init(parser: parser,
                  printer: printer,
                  manifestLoader: manifestLoader,
                  generator: generator)
    }

    init(parser: ArgumentParser,
         printer: Printing,
         manifestLoader: ManifestLoading,
         generator: Generating) {
        let subParser = parser.add(subparser: GenerateCommand.command,
                                   overview: GenerateCommand.overview)
        self.printer = printer
        self.manifestLoader = manifestLoader
        self.generator = generator
        pathArgument = subParser.add(option: "--path",
                                     shortName: "-p",
                                     kind: String.self,
                                     usage: "The path where the project will be generated.",
                                     completion: .filename)
    }

    func run(with arguments: ArgumentParser.Result) throws {
        let path = self.path(arguments: arguments)
        let manifests = manifestLoader.manifests(at: path)
        if manifests.contains(.workspace) {
            try generator.generateWorkspace(at: path)
        } else if manifests.contains(.project) {
            try generator.generateProject(at: path)
        } else {
            throw ManifestLoaderError.manifestNotFound(nil, path)
        }
        printer.print(success: "Project generated.")
    }

    // MARK: - Fileprivate

    fileprivate func path(arguments: ArgumentParser.Result) -> AbsolutePath {
        if let path = arguments.get(pathArgument) {
            return AbsolutePath(path, relativeTo: AbsolutePath.current)
        } else {
            return AbsolutePath.current
        }
    }
}
