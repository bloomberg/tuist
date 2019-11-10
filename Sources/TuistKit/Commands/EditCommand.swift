import Basic
import Foundation
import SPMUtility
import TuistGenerator
import TuistSupport

class EditCommand: NSObject, Command {
    // MARK: - Static

    static let command = "edit"
    static let overview = "Opens manifests in Xcode for editting with autocomplete support."

    // MARK: - Attributes

    private let printer: Printing = Printer.shared
    private let fileHandler: FileHandling = FileHandler.shared
    private let generator: Generating
    private let manifestLoader: GraphManifestLoading
    private let opener: Opening
    let pathArgument: OptionArgument<String>

    // MARK: - Init

    required convenience init(parser: ArgumentParser) {
        let resourceLocator = ResourceLocator()
        let manifestLoader = GraphManifestLoader(resourceLocator: resourceLocator)
        let manifestTargetGenerator = ManifestTargetGenerator(manifestLoader: manifestLoader,
                                                              resourceLocator: resourceLocator)
        let modelLoader = ManifestModelLoader(manifestLoader: manifestLoader,
                                              manifestTargetGenerator: manifestTargetGenerator)
        let generator = Generator(modelLoader: modelLoader)
        let opener = Opener()
        self.init(parser: parser,
                  generator: generator,
                  manifestLoader: manifestLoader,
                  opener: opener)
    }

    init(parser: ArgumentParser,
         generator: Generating,
         manifestLoader: GraphManifestLoading,
         opener: Opening) {
        let subParser = parser.add(subparser: EditCommand.command, overview: EditCommand.overview)
        self.generator = generator
        self.manifestLoader = manifestLoader
        self.opener = opener

        pathArgument = subParser.add(option: "--path",
                                     shortName: "-p",
                                     kind: String.self,
                                     usage: "The path of the directory containing manifests.",
                                     completion: .filename)
    }

    func run(with arguments: ArgumentParser.Result) throws {
        let path = self.path(arguments: arguments)

        let manifestProject = try generator.generate(at: path,
                                                     manifestLoader: manifestLoader,
                                                     projectOnly: true)
        printer.print("Please quit Xcode to proceed.")
        try opener.open(path: manifestProject,
                        newInstance: true,
                        blocking: true)

        try fileHandler.delete(manifestProject)
    }

    // MARK: - Private

    private func path(arguments: ArgumentParser.Result) -> AbsolutePath {
        if let path = arguments.get(pathArgument) {
            return AbsolutePath(path, relativeTo: fileHandler.currentPath)
        } else {
            return fileHandler.currentPath
        }
    }
}
