import Basic
import Foundation
import TuistCore
import TuistGenerator

public class TuistGeneratorModelLoader: ModelLoading {

    private let fileHandler: FileHandling
    private let manifestLoader: ManifestLoading

    init(fileHandler: FileHandling, manifestLoader: ManifestLoading) {
        self.fileHandler = fileHandler
        self.manifestLoader = manifestLoader
    }

    public func loadProject(at path: AbsolutePath) throws -> Project {
        let json = try manifestLoader.load(.project, path: path)
        let project = try TuistGenerator.Project.from(json: json, path: path, fileHandler: fileHandler)
        return project
    }

    public func loadWorkspace(at path: AbsolutePath) throws -> Workspace {
        let json = try manifestLoader.load(.workspace, path: path)
        let workspace = try TuistGenerator.Workspace.from(json: json, path: path)
        return workspace
    }
}

extension TuistGenerator.Workspace {

    static func from(json: JSON, path: AbsolutePath) throws -> TuistGenerator.Workspace {
        let projectsStrings: [String] = try json.get("projects")
        let name: String = try json.get("name")
        let projectsRelativePaths: [RelativePath] = projectsStrings.map { RelativePath($0) }
        let projects = projectsRelativePaths.map { path.appending($0) }
        return Workspace(name: name, projects: projects)
    }
}

extension TuistGenerator.Project {

    static func from(json: JSON, path: AbsolutePath, fileHandler: FileHandling) throws -> TuistGenerator.Project {
        let name: String = try json.get("name")
        let targetsJSONs: [JSON] = try json.get("targets")
        let targets = try targetsJSONs.map { try TuistGenerator.Target.from(json: $0, path: path, fileHandler: fileHandler) }
        let settingsJSON: JSON? = try? json.get("settings")
        let settings = try settingsJSON.map { try TuistGenerator.Settings.from(json: $0, path: path, fileHandler: fileHandler) }

        return Project(path: path,
                       name: name,
                       settings: settings,
                       targets: targets)
    }
}

extension TuistGenerator.Target {

    static func from(json: JSON, path: AbsolutePath, fileHandler: FileHandling) throws -> TuistGenerator.Target {
        let name: String = try json.get("name")
        let platform = TuistGenerator.Platform(rawValue: try json.get("platform"))!
        let product = TuistGenerator.Product(rawValue: try json.get("product"))!
        let bundleId: String = try json.get("bundle_id")
        let dependenciesJSON: [JSON] = try json.get("dependencies")
        let dependencies = try dependenciesJSON.map { try TuistGenerator.Dependency.from(json: $0, path: path, fileHandler: fileHandler) }

        // Info.plist
        let infoPlistPath: String = try json.get("info_plist")
        let infoPlist = path.appending(RelativePath(infoPlistPath))

        // Entitlements
        let entitlementsPath: String? = try? json.get("entitlements")
        let entitlements = entitlementsPath.map { path.appending(RelativePath($0)) }

        // Settings
        let settingsDictionary: [String: JSONSerializable]? = try? json.get("settings")
        let settings = try settingsDictionary.map { try TuistGenerator.Settings.from(json: JSON($0), path: path, fileHandler: fileHandler) }

        // Sources
        let sourcesString: String = try json.get("sources")
        let sources = try TuistGenerator.Target.sources(projectPath: path, sources: sourcesString, fileHandler: fileHandler)

        // Resources
        let resourcesString: String? = try? json.get("resources")
        let resources = try resourcesString.map {
            try TuistGenerator.Target.resources(projectPath: path, resources: $0, fileHandler: fileHandler) } ?? []

        // Headers
        let headersJSON: JSON? = try? json.get("headers")
        let headers = try headersJSON.map { try TuistGenerator.Headers.from(json: $0, path: path, fileHandler: fileHandler) }

        // Core Data Models
        let coreDataModelsJSON: [JSON] = (try? json.get("core_data_models")) ?? []
        let coreDataModels = try coreDataModelsJSON.map { try TuistGenerator.CoreDataModel.from(json: $0, path: path, fileHandler: fileHandler) }

        // Actions
        let actionsJSON: [JSON] = (try? json.get("actions")) ?? []
        let actions = try actionsJSON.map { try TuistGenerator.TargetAction.from(json: $0, path: path, fileHandler: fileHandler) }

        // Environment
        let environment: [String: String] = (try? json.get("environment")) ?? [:]

        return Target(name: name,
                      platform: platform,
                      product: product,
                      bundleId: bundleId,
                      infoPlist: infoPlist,
                      entitlements: entitlements,
                      settings: settings,
                      sources: sources,
                      resources: resources,
                      headers: headers,
                      coreDataModels: coreDataModels,
                      actions: actions,
                      environment: environment,
                      dependencies: dependencies)
    }
}

extension TuistGenerator.Settings {

    static func from(json: JSON, path: AbsolutePath, fileHandler: FileHandling) throws -> TuistGenerator.Settings {
        let base: [String: String] = try json.get("base")
        let debugJSON: JSON? = try? json.get("debug")
        let debug = try debugJSON.flatMap { try TuistGenerator.Configuration.from(json: $0, path: path, fileHandler: fileHandler) }
        let releaseJSON: JSON? = try? json.get("release")
        let release = try releaseJSON.flatMap { try TuistGenerator.Configuration.from(json: $0, path: path, fileHandler: fileHandler) }
        return Settings(base: base, debug: debug, release: release)
    }
}

extension TuistGenerator.Configuration {

    static func from(json: JSON, path: AbsolutePath, fileHandler: FileHandling) throws -> TuistGenerator.Configuration {
        let settings: [String: String] = try json.get("settings")
        let xcconfigString: String? = json.get("xcconfig")
        let xcconfig = xcconfigString.flatMap({ path.appending(RelativePath($0)) })
        return Configuration(settings: settings, xcconfig: xcconfig)
    }
}

extension TuistGenerator.TargetAction {

    static func from(json: JSON, path: AbsolutePath, fileHandler: FileHandling) throws -> TuistGenerator.TargetAction {
        let name: String = try json.get("name")
        let tool: String? = try? json.get("tool")
        let order = TuistGenerator.TargetAction.Order(rawValue: try json.get("order"))!
        let pathString: String? = try? json.get("path")
        let path = pathString.map { AbsolutePath($0, relativeTo: path) }
        let arguments: [String] = try json.get("arguments")
        return TargetAction(name: name, order: order, tool: tool, path: path, arguments: arguments)
    }
}

extension TuistGenerator.CoreDataModel {

    static func from(json: JSON, path: AbsolutePath, fileHandler: FileHandling) throws -> TuistGenerator.CoreDataModel {
        let pathString: String = try json.get("path")
        let modelPath = path.appending(RelativePath(pathString))
        if !fileHandler.exists(modelPath) {
            throw ManifestLoaderError.missingFile(modelPath)
        }
        let versions: [AbsolutePath] = path.glob("*.xcdatamodel")
        let currentVersion: String = try json.get("current_version")
        return CoreDataModel(path: modelPath, versions: versions, currentVersion: currentVersion)
    }
}

extension TuistGenerator.Headers {

    static func from(json: JSON, path: AbsolutePath, fileHandler: FileHandling) throws -> TuistGenerator.Headers {
        let publicString: String? = try? json.get("public")
        let `public` = publicString.map { path.glob($0) } ?? []
        let privateString: String? = try? json.get("private")
        let `private` = privateString.map { path.glob($0) } ?? []
        let projectString: String? = try? json.get("project")
        let project = projectString.map { path.glob($0) } ?? []
        return Headers(public: `public`, private: `private`, project: project)
    }
}

extension TuistGenerator.Dependency {

    static func from(json: JSON, path: AbsolutePath, fileHandler: FileHandling) throws -> TuistGenerator.Dependency {
        let name: String? = json.get("name")
        let type: String = try json.get("type")
        let target: String? = json.get("target")
        let path: RelativePath? = json.get("path").map { RelativePath($0) }
        let publicHeaders: RelativePath? = json.get("public_headers").map { RelativePath($0) }
        let swiftModuleMap: String? = json.get("swift_module_map")
        return Dependency(name: name, type: type, target: target, path: path, publicHeaders: publicHeaders, swiftModuleMap: swiftModuleMap)
    }
}
