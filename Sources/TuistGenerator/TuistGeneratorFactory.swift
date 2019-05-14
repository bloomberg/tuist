import Foundation
import TuistCore

public class TuistGeneratorFactory {

    let system: Systeming
    let printer: Printing
    let fileHandler: FileHandling

    // MARK: - Public

    public init(system: Systeming = System(),
                printer: Printing = Printer(),
                fileHandler: FileHandling = FileHandler()) {
        self.system = system
        self.printer = printer
        self.fileHandler = fileHandler
    }

    public func createGenerator(modelLoader: GeneratorModelLoading) -> Generating {
        return Generator(graphLoader: createGraphLoader(modelLoader: modelLoader),
                         workspaceGenerator: createWorkspaceGenerator())
    }

    // MARK: - Internal

    func createGraphLoader(modelLoader: GeneratorModelLoading) -> GraphLoading {
        return GraphLoader(linter: createGraphLinter(),
                           printer: printer,
                           fileHandler: fileHandler,
                           modelLoader: modelLoader)
    }

    func createGraphLinter() -> GraphLinting {
        return GraphLinter(projectLinter: createProjectLinter(),
                           fileHandler: fileHandler)
    }

    func createProjectLinter() -> ProjectLinting {
        return ProjectLinter(targetLinter: createTargetLinter(),
                             settingsLinter: createSettingsLinter())
    }

    func createTargetLinter() -> TargetLinting {
        return TargetLinter(settingsLinter: createSettingsLinter(),
                            fileHandler: fileHandler,
                            targetActionLinter: createTargetActionLinter())
    }

    func createSettingsLinter() -> SettingsLinting {
        return SettingsLinter(fileHandler: fileHandler)
    }

    func createTargetActionLinter() -> TargetActionLinting {
        return TargetActionLinter(system: system, fileHandler: fileHandler)
    }

    func createWorkspaceGenerator() -> WorkspaceGenerating {
        return WorkspaceGenerator(system: system,
                                  printer: printer,
                                  projectDirectoryHelper: createProjectDirectoryHelper(),
                                  projectGenerator: createProjectGenerator(),
                                  fileHandler: fileHandler,
                                  workspaceStructureGenerator: createWorkspaceStructureGenerator())
    }

    func createWorkspaceStructureGenerator() -> WorkspaceStructureGenerating {
        return  WorkspaceStructureGenerator(fileHandler: fileHandler)
    }

    func createProjectDirectoryHelper() -> ProjectDirectoryHelper {
        return ProjectDirectoryHelper(environmentController: createEnvironmentController(),
                                      fileHandler: fileHandler)
    }

    func createEnvironmentController() -> EnvironmentControlling {
        return EnvironmentController(directory: EnvironmentController.defaultDirectory,
                                     fileHandler: fileHandler)
    }

    func createProjectGenerator() -> ProjectGenerating {
        return ProjectGenerator(targetGenerator: createTargetGenerator(),
                                configGenerator: createConfigGenerator(),
                                schemesGenerator: createSchemasGenerator(),
                                printer: printer,
                                system: system,
                                fileHandler: fileHandler)
    }

    func createTargetGenerator() -> TargetGenerating {
        return TargetGenerator(configGenerator: createConfigGenerator(),
                               fileGenerator: createFileGenerator(),
                               buildPhaseGenerator: createBuildPhaseGenerator(),
                               linkGenerator: createLinkGenerator())
    }

    func createBuildPhaseGenerator() -> BuildPhaseGenerating {
        return BuildPhaseGenerator()
    }

    func createConfigGenerator() -> ConfigGenerating {
        return ConfigGenerator(fileGenerator: createFileGenerator())
    }

    func createFileGenerator() -> FileGenerating {
        return FileGenerator()
    }

    func createLinkGenerator() -> LinkGenerating {
        return LinkGenerator(binaryLocator: createBinaryLocator())
    }

    func createBinaryLocator() -> BinaryLocating {
        return BinaryLocator(fileHandler: fileHandler)
    }

    func createSchemasGenerator() -> SchemesGenerating {
        return SchemesGenerator(fileHandler: fileHandler)
    }
}
