import Foundation

public struct EnvironmentIdentifier: Codable {

    public typealias ResourceIdentifier = String

    /// Path to the environment file
    public let path: String?

    /// Resource identifier
    public let identifier: ResourceIdentifier

    init(path: String? = nil, resourceIdentifier: ResourceIdentifier) {
        self.path = path
        self.identifier = resourceIdentifier
    }

    public func asLink<T>() -> Link<T> {
        return .environment(self)
    }
}

public enum EnvironmentError: Error {
    case variableNotFound(identifier: EnvironmentIdentifier.ResourceIdentifier)
}

public class Environment: Codable {

    public enum VariableType {
        case settings(_ name: EnvironmentIdentifier.ResourceIdentifier, _ value: Settings)
    }

    enum ContainerType {
        case real
        case link
    }

    public typealias Identifier = String

    public let settings: [EnvironmentIdentifier.ResourceIdentifier: Settings]
    private let path: String?

    public convenience init(_ variables: VariableType...) {
        let settingsKeyValues = variables.compactMap { (variable: VariableType) -> (String, Settings)? in
            switch variable {
            case let .settings(name, value):
                return (name, value)
            }
        }
        let settings: [EnvironmentIdentifier.ResourceIdentifier: Settings] = Dictionary(uniqueKeysWithValues: settingsKeyValues)
        self.init(settings: settings)
    }

    public init(settings: [EnvironmentIdentifier.ResourceIdentifier: Settings]) {
        self.settings = settings
        self.path = nil
        dumpIfNeeded(self)
    }

    /// That makes the public interface very confusing, in the manifest files we need to use
    /// this method to get the link but in the model loader, settings should be accessed directly...
    /// We should unify this...
    public func settings(_ identifier: EnvironmentIdentifier.ResourceIdentifier) -> Link<Settings> {
        if let path = path {
            return .environment(EnvironmentIdentifier(path: path, resourceIdentifier: identifier))
        }

        /// Would need to be changed
        fatalError("Invalid state")
    }

    private init(path: String) {
        self.settings = [:]
        self.path = path
    }

    public static func at(path: String) -> Environment {
        return Environment(path: path)
    }
}
