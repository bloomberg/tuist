import Foundation
import Swinject
import TuistCore

public final class TuistGeneratorAssembly: Assembly {

    public init() {}

    public func assemble(container c: Container) {
        // Public
        c.register(Generating.self) { (r: Resolver, modelLoader: GeneratorModelLoading) in
            Generator(graphLoader: r.get(GraphLoading.self, argument: modelLoader),
                      workspaceGenerator: r.get(WorkspaceGenerating.self))
        }

        // Internals
        c.register(Systeming.self) { _ in System() }.inObjectScope(.container)
        c.register(Printing.self) { _ in Printer() }.inObjectScope(.container)
        c.register(FileHandling.self) { _ in FileHandler() }.inObjectScope(.container)
        c.register(GraphLinting.self) { r in
            GraphLinter(projectLinter: r.get(ProjectLinting.self),
                        fileHandler: r.getFileHandler())
        }
        c.register(ProjectLinting.self) { r in
            ProjectLinter(targetLinter: r.get(TargetLinting.self),
                          settingsLinter: r.get(SettingsLinting.self))
        }
        c.register(TargetLinting.self) { r in
            TargetLinter(settingsLinter: r.get(SettingsLinting.self),
                         fileHandler: r.getFileHandler(),
                         targetActionLinter: r.get(TargetActionLinting.self))
        }
        c.register(TargetActionLinting.self) { r in
            TargetActionLinter(system: r.getSystem(),
                               fileHandler: r.getFileHandler())
        }
        c.register(SettingsLinting.self) { r in
            SettingsLinter(fileHandler: r.getFileHandler())
        }
        c.register(GraphLoading.self) { (r: Resolver, modelLoader: GeneratorModelLoading) in
            GraphLoader(linter: r.get(GraphLinting.self),
                        printer: r.getPrinter(),
                        fileHandler: r.getFileHandler(),
                        modelLoader: modelLoader)
        }
        c.register(WorkspaceGenerating.self) { r in
            WorkspaceGenerator(system: r.getSystem(),
                               printer: r.getPrinter(),
                               projectDirectoryHelper: r.get(ProjectDirectoryHelping.self),
                               projectGenerator: r.get(ProjectGenerating.self),
                               fileHandler: r.getFileHandler(),
                               workspaceStructureGenerator: r.get(WorkspaceStructureGenerating.self))
        }
        c.register(ProjectDirectoryHelping.self) { r in
            ProjectDirectoryHelper(environmentController: r.get(EnvironmentControlling.self),
                                   fileHandler: r.getFileHandler())
        }
        c.register(EnvironmentControlling.self) { r in
            EnvironmentController(directory: EnvironmentController.defaultDirectory,
                                  fileHandler: r.getFileHandler())
        }
        c.register(ProjectGenerating.self) { r in
            ProjectGenerator(targetGenerator: r.get(TargetGenerating.self),
                             configGenerator: r.get(ConfigGenerating.self),
                             schemesGenerator: r.get(SchemesGenerating.self),
                             printer: r.getPrinter(),
                             system: r.getSystem(),
                             fileHandler: r.getFileHandler())
        }
        c.register(TargetGenerating.self) { r in
            TargetGenerator(configGenerator: r.get(ConfigGenerating.self),
                            fileGenerator: r.get(FileGenerating.self),
                            buildPhaseGenerator: r.get(BuildPhaseGenerating.self),
                            linkGenerator: r.get(LinkGenerating.self))
        }
        c.register(ConfigGenerating.self) { r in
            ConfigGenerator(fileGenerator: r.get(FileGenerating.self))
        }
        c.register(FileGenerating.self) { r in
            FileGenerator()
        }
        c.register(BuildPhaseGenerating.self) { _ in
            BuildPhaseGenerator()
        }
        c.register(LinkGenerating.self) { r in
            LinkGenerator(binaryLocator: r.get(BinaryLocating.self))
        }
        c.register(BinaryLocating.self) { r in
            BinaryLocator(fileHandler: r.getFileHandler())
        }
        c.register(SchemesGenerating.self) { r in
            SchemesGenerator(fileHandler: r.getFileHandler())
        }
        c.register(WorkspaceStructureGenerating.self) { r in
            WorkspaceStructureGenerator(fileHandler: r.getFileHandler())
        }
    }
}

private extension Resolver {

    func getFileHandler() -> FileHandling {
        return resolve(FileHandling.self)!
    }

    func getPrinter() -> Printing {
        return resolve(Printing.self)!
    }

    func getSystem() -> Systeming {
        return resolve(Systeming.self)!
    }
}

private extension Resolver {

    func get<Service>(_ serviceType: Service.Type) -> Service {
        guard let service = resolve(serviceType) else {
            fatalError("Service not found")
        }
        return service
    }

    func get<Service, Arg1>(_ serviceType: Service.Type, argument: Arg1) -> Service {
        guard let service = resolve(serviceType, argument: argument) else {
            fatalError("Service not found")
        }
        return service
    }
}
