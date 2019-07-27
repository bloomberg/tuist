import Foundation

/// This model allows to configure Tuist.
public class TuistConfig: Codable {
    /// Contains options related to the project generation.
    ///
    /// - generateManifestElement: When passed, Tuist generates the projects, targets and schemes to compile the project manifest.
    public enum GenerationOption: String, Codable {
        case generateManifest
    }

    /// Generation options.
    public let generationOptions: [GenerationOption]
    public let sharedConfigurations: [CustomConfiguration]?

    /// Initializes the tuist cofiguration.
    ///
    /// - Parameter generationOptions: Generation options.
    /// - Parameter sharedConfigurations: Configurations to apply to all projects that use this configuration.
    public init(generationOptions: [GenerationOption],
                sharedConfigurations: [CustomConfiguration]? = nil) {
        self.generationOptions = generationOptions
        self.sharedConfigurations = sharedConfigurations
        dumpIfNeeded(self)
    }
}

public extension TuistConfig {
    static var `default`: TuistConfig {
        return TuistConfig(generationOptions: [.generateManifest])
    }
}
