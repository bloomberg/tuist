import Basic
import Foundation
import TuistCore

public class Target: Equatable {
    // MARK: - Static
    static let validSourceExtensions: [String] = ["m", "swift", "mm", "cpp", "c"]
    static let validFolderExtensions: [String] = ["framework", "bundle", "app", "appiconset"]

    // MARK: - Attributes
    public let name: String
    public let platform: Platform
    public let product: Product
    public let bundleId: String
    public let infoPlist: AbsolutePath
    public let entitlements: AbsolutePath?
    public let settings: Settings?
    public let sources: [AbsolutePath]
    public let resources: [AbsolutePath]
    public let headers: Headers?
    public let coreDataModels: [CoreDataModel]
    public let actions: [TargetAction]
    public let environment: [String: String]
    public let dependencies: [Dependency]

    // MARK: - Init
    public init(name: String,
                platform: Platform,
                product: Product,
                bundleId: String,
                infoPlist: AbsolutePath,
                entitlements: AbsolutePath? = nil,
                settings: Settings? = nil,
                sources: [AbsolutePath] = [],
                resources: [AbsolutePath] = [],
                headers: Headers? = nil,
                coreDataModels: [CoreDataModel] = [],
                actions: [TargetAction] = [],
                environment: [String: String] = [:],
                dependencies: [Dependency] = []) {
        self.name = name
        self.product = product
        self.platform = platform
        self.bundleId = bundleId
        self.infoPlist = infoPlist
        self.entitlements = entitlements
        self.settings = settings
        self.sources = sources
        self.resources = resources
        self.headers = headers
        self.coreDataModels = coreDataModels
        self.actions = actions
        self.environment = environment
        self.dependencies = dependencies
    }

    // MARK: - Public

    public static func sources(projectPath: AbsolutePath, sources: String, fileHandler _: FileHandling) throws -> [AbsolutePath] {
        return projectPath.glob(sources).filter { path in
            if let `extension` = path.extension, Target.validSourceExtensions.contains(`extension`) {
                return true
            }
            return false
        }
    }

    public static func resources(projectPath: AbsolutePath, resources: String, fileHandler: FileHandling) throws -> [AbsolutePath] {
        return projectPath.glob(resources).filter { path in
            if !fileHandler.isFolder(path) {
                return true
                // We filter out folders that are not Xcode supported bundles such as .app or .framework.
            } else if let `extension` = path.extension, Target.validFolderExtensions.contains(`extension`) {
                return true
            } else {
                return false
            }
        }
    }

    // MARK: - Internal

    func isLinkable() -> Bool {
        return product == .dynamicLibrary || product == .staticLibrary || product == .framework
    }

    var productName: String {
        switch product {
        case .staticLibrary, .dynamicLibrary:
            return "lib\(name).\(product.xcodeValue.fileExtension!)"
        case _:
            return "\(name).\(product.xcodeValue.fileExtension!)"
        }
    }

    // MARK: - Equatable
    public static func == (lhs: Target, rhs: Target) -> Bool {
        return lhs.name == rhs.name &&
            lhs.platform == rhs.platform &&
            lhs.product == rhs.product &&
            lhs.bundleId == rhs.bundleId &&
            lhs.infoPlist == rhs.infoPlist &&
            lhs.entitlements == rhs.entitlements &&
            lhs.settings == rhs.settings &&
            lhs.sources == rhs.sources &&
            lhs.resources == rhs.resources &&
            lhs.headers == rhs.headers &&
            lhs.coreDataModels == rhs.coreDataModels &&
            lhs.environment == rhs.environment &&
            lhs.dependencies == rhs.dependencies
    }
}
