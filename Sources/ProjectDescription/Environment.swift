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

public class Environment: Codable {

    public enum VariableType {
        case settings(_ name: EnvironmentIdentifier.ResourceIdentifier, _ value: Settings)
    }

    public typealias Identifier = String

    public let settings: [EnvironmentIdentifier.ResourceIdentifier: Settings]

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
        dumpIfNeeded(self)
    }
}
