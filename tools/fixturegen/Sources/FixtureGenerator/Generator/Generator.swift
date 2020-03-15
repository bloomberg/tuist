import Foundation
import TSCBasic

class Generator {
    private let fileSystem: FileSystem
    private let config: GeneratorConfig
    private let sourceTemplate: SourceTemplate
    private let manifestTemplate: ManifestTemplate

    init(fileSystem: FileSystem, config: GeneratorConfig) {
        self.fileSystem = fileSystem
        self.config = config

        sourceTemplate = SourceTemplate()
        manifestTemplate = ManifestTemplate(generateDependencies: config.dependencies)
    }

    func generate(at path: AbsolutePath) throws {
        let rootPath = path.appending(component: "Fixture")
        let projects = (1 ... config.projects).map { "Project\($0)" }

        try fileSystem.createDirectory(rootPath)
        try initWorkspaceManifest(at: rootPath,
                                  name: "Workspace",
                                  projects: projects)

        try projects.enumerated().forEach {
            try initProject(at: rootPath,
                            name: $0.element,
                            projectIndex: ProjectIndex(index: $0.offset, total: projects.count))
        }
    }

    private func initWorkspaceManifest(at path: AbsolutePath,
                                       name: String,
                                       projects: [String]) throws {
        let manifestPath = path.appending(component: "Workspace.swift")

        let manifest = manifestTemplate.generate(workspaceName: name,
                                                 projects: projects)
        try fileSystem.writeFileContents(manifestPath,
                                         bytes: ByteString(encodingAsUTF8: manifest))
    }

    private func initProject(at path: AbsolutePath,
                             name: String,
                             projectIndex: ProjectIndex) throws {
        let projectPath = path.appending(component: name)
        let appTargets = ["\(name)App"]
        let targets = (1 ... config.targets).map { "Target\($0)" }
        let testTargets = ["\(name)Tests"]

        try fileSystem.createDirectory(projectPath)
        try initProjectManifest(at: projectPath, name: name,
                                projectIndex: projectIndex,
                                appTargets: appTargets,
                                targets: targets,
                                testTargets: testTargets)

        try (appTargets + targets + testTargets).forEach {
            try initTarget(at: projectPath, name: $0)
        }
    }

    private func initProjectManifest(at path: AbsolutePath,
                                     name: String,
                                     projectIndex: ProjectIndex,
                                     appTargets: [String],
                                     targets: [String],
                                     testTargets: [String]) throws {
        let manifestPath = path.appending(component: "Project.swift")

        let manifest = manifestTemplate.generate(projectName: name,
                                                 appTargets: appTargets,
                                                 targets: targets,
                                                 testTargets: testTargets,
                                                 projectIndex: projectIndex,
                                                 additionalGlobs: config.additionalGlobs)
        try fileSystem.writeFileContents(manifestPath,
                                         bytes: ByteString(encodingAsUTF8: manifest))
    }

    private func initTarget(at path: AbsolutePath, name: String) throws {
        let targetPath = path.appending(component: name)
        try fileSystem.createDirectory(targetPath)

        try initSources(at: targetPath, targetName: name)
        try initHeaders(at: targetPath)
        try initResources(at: targetPath)
    }

    private func initSources(at path: AbsolutePath, targetName: String) throws {
        let sourcesPath = path.appending(component: "Sources")
        try fileSystem.createDirectory(sourcesPath)

        try (1 ... config.sources).forEach {
            let sourceName = "Source\($0).swift"
            let source = sourceTemplate.generate(frameworkName: targetName, number: $0)
            try fileSystem.writeFileContents(sourcesPath.appending(component: sourceName),
                                             bytes: ByteString(encodingAsUTF8: source))
        }
    }

    private func initHeaders(at path: AbsolutePath) throws {
        let publicHeadersPath = path.appending(components: "Sources", "Public")
        let privateHeadersPath = path.appending(components: "Sources", "Private")
        let projectHeadersPath = path.appending(components: "Sources", "Project")

        try [publicHeadersPath, privateHeadersPath, projectHeadersPath].forEach { headersPath in
            let headers = (1 ... config.headers).map { "Header\($0).h" }
            try generateEmptyFiles(at: headersPath, names: headers)
        }
    }

    private func initResources(at path: AbsolutePath) throws {
        let resourcesPath = path.appending(component: "Resources")
        let resources = (1 ... config.resources).map { "Resource\($0).txt" }
        try generateEmptyFiles(at: resourcesPath, names: resources)
    }

    private func generateEmptyFiles(at path: AbsolutePath, names: [String]) throws {
        try fileSystem.createDirectory(path)
        try names.forEach { name in
            let contents = ""
            try fileSystem.writeFileContents(path.appending(component: name),
                                             bytes: ByteString(encodingAsUTF8: contents))
        }
    }
}
