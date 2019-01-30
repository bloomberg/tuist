import Basic
import Foundation
import TuistCore
import Yams

protocol ManifestLoading {

    func load(_ manifest: Manifest, path: AbsolutePath) throws -> JSON
    func manifests(at path: AbsolutePath) -> Set<Manifest>
    func manifestPath(at path: AbsolutePath, manifest: Manifest) throws -> AbsolutePath
    func loadSetup(at path: AbsolutePath) throws -> [Upping]
}

class ManifestLoader: ManifestLoading {
    // MARK: - Attributes

    /// File handler to interact with the file system.
    let fileHandler: FileHandling

    /// Instance to run commands in the system.
    let system: Systeming

    /// Resource locator to look up Tuist-related resources.
    let resourceLocator: ResourceLocating

    /// Depreactor to notify about deprecations.
    let deprecator: Deprecating

    // MARK: - Init

    /// Initializes the manifest loader with its attributes.
    ///
    /// - Parameters:
    ///   - fileHandler: File handler to interact with the file system.
    ///   - system: Instance to run commands in the system.
    ///   - resourceLocator: Resource locator to look up Tuist-related resources.
    ///   - deprecator: Depreactor to notify about deprecations.
    init(fileHandler: FileHandling = FileHandler(),
         system: Systeming = System(),
         resourceLocator: ResourceLocating = ResourceLocator(),
         deprecator: Deprecating = Deprecator()) {
        self.fileHandler = fileHandler
        self.system = system
        self.resourceLocator = resourceLocator
        self.deprecator = deprecator
    }

    func load(_ manifest: Manifest, path: AbsolutePath) throws -> JSON {
        let manifestPath = try self.manifestPath(at: path, manifest: manifest)
        if manifestPath.extension == "swift" {
            return try loadSwiftManifest(path: manifestPath)
        } else if manifestPath.extension == "json" {
            deprecator.notify(deprecation: "JSON manifests", suggestion: "Swift manifests")
            return try loadJSONManifest(path: manifestPath)
        } else if manifestPath.extension == "yaml" || manifestPath.extension == "yml" {
            deprecator.notify(deprecation: "YAML manifests", suggestion: "Swift manifests")
            return try loadYamlManifest(path: manifestPath)
        } else {
            throw ManifestLoaderError.manifestNotFound(manifest, path)
        }
    }

    func manifestPath(at path: AbsolutePath, manifest: Manifest) throws -> AbsolutePath {
        let swiftPath = path.appending(component: "\(manifest.fileName).swift")
        let jsonPath = path.appending(component: "\(manifest.fileName).json")
        let yamlPath = path.appending(component: "\(manifest.fileName).yaml")
        let ymlPath = path.appending(component: "\(manifest.fileName).yml")

        if fileHandler.exists(swiftPath) {
            return swiftPath
        } else if fileHandler.exists(jsonPath) {
            return jsonPath
        } else if fileHandler.exists(yamlPath) {
            return yamlPath
        } else if fileHandler.exists(ymlPath) {
            return ymlPath
        } else {
            throw ManifestLoaderError.manifestNotFound(manifest, path)
        }
    }

    func manifests(at path: AbsolutePath) -> Set<Manifest> {
        let manifests: [Manifest] = [.project, .workspace].filter { manifest in
            let paths = Manifest.supportedExtensions.map {
                path.appending(component: "\(manifest.fileName).\($0)")
            }
            return paths.contains(where: { fileHandler.exists($0) })
        }
        return Set(manifests)
    }

    func loadSetup(at path: AbsolutePath) throws -> [Upping] {
        let setupPath = path.appending(component: "Setup.swift")
        guard fileHandler.exists(setupPath) else {
            throw ManifestLoaderError.setupNotFound(path)
        }

        let setup = try loadSwiftManifest(path: setupPath)
        let actionsJson: [JSON] = try setup.get("actions")
        return try actionsJson.compactMap {
            try Up.with(dictionary: $0,
                        projectPath: path,
                        fileHandler: fileHandler) }
    }

    // MARK: - Fileprivate

    fileprivate func loadYamlManifest(path: AbsolutePath) throws -> JSON {
        let content = try String(contentsOf: path.url)
        guard let object = try Yams.load(yaml: content) as? [String: Any] else {
            throw ManifestLoaderError.invalidYaml(path)
        }
        let data = try JSONSerialization.data(withJSONObject: object, options: [])
        let json = String(data: data, encoding: .utf8) ?? "{}"
        return try JSON(string: json)
    }

    fileprivate func loadJSONManifest(path: AbsolutePath) throws -> JSON {
        let content = try String(contentsOf: path.url)
        return try JSON(string: content)
    }

    fileprivate func loadSwiftManifest(path: AbsolutePath) throws -> JSON {
        let projectDescriptionPath = try resourceLocator.projectDescription()
        var arguments: [String] = [
            "/usr/bin/xcrun",
            "swiftc",
            "--driver-mode=swift",
            "-suppress-warnings",
            "-I", projectDescriptionPath.parentDirectory.asString,
            "-L", projectDescriptionPath.parentDirectory.asString,
            "-F", projectDescriptionPath.parentDirectory.asString,
            "-lProjectDescription",
            ]
        arguments.append(path.asString)
        arguments.append("--dump")

        guard let jsonString = try system.capture(arguments).spm_chuzzle() else {
            throw ManifestLoaderError.unexpectedOutput(path)
        }
        return try JSON(string: jsonString)
    }
}
