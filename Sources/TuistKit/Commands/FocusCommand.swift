import Basic
import Foundation
import TuistCore
import TuistGenerator
import Utility

/// The focus command generates the Xcode workspace and launches it on Xcode.
class FocusCommand: NSObject, Command {
    // MARK: - Static

    /// Command name that is used for the CLI.
    static let command = "focus"

    /// Command description that is shown when using help from the CLI.
    static let overview = "Opens Xcode ready to focus on the project in the current directory."

    // MARK: - Attributes

    /// Printer instance to output messages to the user.
    fileprivate let printer: Printing

    /// File handler instance to interact with the file system.
    fileprivate let fileHandler: FileHandling

    /// Opener instance to run open in the system.
    fileprivate let opener: Opening

    /// Config argument that allos specifying which configuration the Xcode project should be generated with.
    let configArgument: OptionArgument<String>

    fileprivate let generator: Generating

    // MARK: - Init

    /// Initializes the focus command with the argument parser where the command needs to register itself.
    ///
    /// - Parameter parser: Argument parser that parses the CLI arguments.
    required convenience init(parser: ArgumentParser) {
        let printer = Printer()
        let fileHandler = FileHandler()
        let generator = GeneratorFactory.create(printer: printer, system: System(), fileHandler: fileHandler)
        self.init(parser: parser,
                  printer: printer,
                  fileHandler: fileHandler,
                  generator: generator,
                  opener: Opener())
    }

    /// Initializes the focus command with its attributes.
    ///
    /// - Parameters:
    ///   - parser: Argument parser that parses the CLI arguments.
    ///   - graphLoader: Graph loader instance to load the dependency graph.
    ///   - workspaceGenerator: Workspace generator instance to generate the project workspace.
    ///   - printer: Printer instance to output messages to the user.
    ///   - system: System instance to run commands on the system.
    ///   - resourceLocator: Resource locator instance used to find files in the system.
    ///   - fileHandler: File handler instance to interact with the file system.
    ///   - opener: Opener instance to run open in the system.
    ///   - graphUp: Graph up instance to print a warning if the environment is not configured at all.
    init(parser: ArgumentParser,
         printer: Printing,
         fileHandler: FileHandling,
         generator: TuistGenerator.Generating,
         opener: Opening) {
        let subParser = parser.add(subparser: FocusCommand.command, overview: FocusCommand.overview)
        self.printer = printer
        self.fileHandler = fileHandler
        self.opener = opener
        self.generator = generator
        configArgument = subParser.add(option: "--config",
                                       shortName: "-c",
                                       kind: String.self,
                                       usage: "The configuration that will be generated.",
                                       completion: .filename)
    }

    func run(with _: ArgumentParser.Result) throws {
        let path = fileHandler.currentPath
        let workspacePath = try generator.generateWorkspace(at: path)
        try opener.open(path: workspacePath)
    }
}
