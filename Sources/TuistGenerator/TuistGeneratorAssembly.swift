import Foundation
import Swinject
import TuistCore

public final class TuistGeneratorAssembly: Assembly {

    public init() {}

    public func assemble(container c: Container) {
        // Public
        c.register(Generating.self) { (r: Resolver, modelLoader: GeneratorModelLoading) in
            Generator(graphLoader: r.resolve(GraphLoading.self, argument: modelLoader)!,
                      workspaceGenerator: r.resolve(WorkspaceGenerating.self)!)
        }

        // Internals
        c.register(Systeming.self) { _ in System() }.inObjectScope(.container)
        c.register(Printing.self) { _ in Printer() }.inObjectScope(.container)
        c.register(FileHandling.self) { _ in FileHandler() }.inObjectScope(.container)
        c.register(GraphLinting.self) { r in
            GraphLinter(projectLinter: r.resolve(ProjectLinting.self)!,
                        fileHandler: r.resolveFileHandler())
        }
        c.register(ProjectLinting.self) { r in
            ProjectLinter(targetLinter: r.resolve(TargetLinting.self)!,
                          settingsLinter: r.resolve(SettingsLinting.self)!)
        }
        c.register(TargetLinting.self) { r in
            TargetLinter(settingsLinter: r.resolve(SettingsLinting.self)!,
                         fileHandler: r.resolveFileHandler(),
                         targetActionLinter: r.resolve(TargetActionLinting.self)!)
        }
        c.register(TargetActionLinting.self) { r in
            TargetActionLinter(system: r.resolveSystem(),
                               fileHandler: r.resolveFileHandler())
        }
        c.register(SettingsLinting.self) { r in
            SettingsLinter(fileHandler: r.resolveFileHandler())
        }
        c.register(GraphLoading.self) { (r: Resolver, modelLoader: GeneratorModelLoading) in
            GraphLoader(linter: r.resolve(GraphLinting.self)!,
                        printer: r.resolvePrinter(),
                        fileHandler: r.resolveFileHandler(),
                        modelLoader: modelLoader)
        }
        c.register(WorkspaceGenerating.self) { r in
            WorkspaceGenerator(system: r.resolveSystem(),
                               printer: r.resolvePrinter(),
                               projectDirectoryHelper: r.resolve(ProjectDirectoryHelping.self)!,
                               projectGenerator: r.resolve(ProjectGenerating.self)!,
                               fileHandler: r.resolveFileHandler(),
                               workspaceStructureGenerator: r.resolve(WorkspaceStructureGenerating.self)!)
        }
        c.register(ProjectDirectoryHelping.self) { r in
            ProjectDirectoryHelper(environmentController: r.resolve(EnvironmentControlling.self)!,
                                   fileHandler: r.resolveFileHandler())
        }
        c.register(EnvironmentControlling.self) { r in
            EnvironmentController(directory: EnvironmentController.defaultDirectory,
                                  fileHandler: r.resolveFileHandler())
        }
        c.register(ProjectGenerating.self) { r in
            ProjectGenerator(targetGenerator: r.resolve(TargetGenerating.self)!,
                             configGenerator: r.resolve(ConfigGenerating.self)!,
                             schemesGenerator: r.resolve(SchemesGenerating.self)!,
                             printer: r.resolvePrinter(),
                             system: r.resolveSystem(),
                             fileHandler: r.resolveFileHandler())
        }
        c.register(TargetGenerating.self) { r in
            TargetGenerator(configGenerator: r.resolve(ConfigGenerating.self)!,
                            fileGenerator: r.resolve(FileGenerating.self)!,
                            buildPhaseGenerator: r.resolve(BuildPhaseGenerating.self)!,
                            linkGenerator: r.resolve(LinkGenerating.self)!)
        }
        c.register(ConfigGenerating.self) { r in
            ConfigGenerator(fileGenerator: r.resolve(FileGenerating.self)!)
        }
        c.register(FileGenerating.self) { r in
            FileGenerator()
        }
        c.register(BuildPhaseGenerating.self) { _ in
            BuildPhaseGenerator()
        }
        c.register(LinkGenerating.self) { r in
            LinkGenerator(binaryLocator: r.resolve(BinaryLocating.self)!)
        }
        c.register(BinaryLocating.self) { r in
            BinaryLocator(fileHandler: r.resolveFileHandler())
        }
        c.register(SchemesGenerating.self) { r in
            SchemesGenerator(fileHandler: r.resolveFileHandler())
        }
        c.register(WorkspaceStructureGenerating.self) { r in
            WorkspaceStructureGenerator(fileHandler: r.resolveFileHandler())
        }
    }
}

private extension Resolver {

    func resolveFileHandler() -> FileHandling {
        return resolve(FileHandling.self)!
    }

    func resolvePrinter() -> Printing {
        return resolve(Printing.self)!
    }

    func resolveSystem() -> Systeming {
        return resolve(Systeming.self)!
    }
}
