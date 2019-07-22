import Foundation

// MARK: - Configuration

public struct Configuration: Equatable, Codable {
    public enum Variant: String, Codable {
        case debug
        case release
    }

    public let name: String
    public let variant: Variant
    public let settings: [String: String]
    public let xcconfig: String?

    public init(name: String, variant: Variant, settings: [String: String] = [:], xcconfig: String? = nil) {
        self.name = name
        self.variant = variant
        self.settings = settings
        self.xcconfig = xcconfig
    }

    public init(settings: [String: String] = [:], xcconfig: String? = nil) {
        name = ""
        variant = .debug
        self.settings = settings
        self.xcconfig = xcconfig
    }

    public static func settings(_ settings: [String: String], xcconfig: String? = nil) -> Configuration {
        return Configuration(settings: settings, xcconfig: xcconfig)
    }
}

public extension Configuration {
    static func debug(name: String = "Debug", settings: [String: String] = [:], xcconfig: String? = nil) -> Configuration {
        return Configuration(name: name, variant: .debug, settings: settings, xcconfig: xcconfig)
    }

    static func release(name: String = "Release", settings: [String: String] = [:], xcconfig: String? = nil) -> Configuration {
        return Configuration(name: name, variant: .release, settings: settings, xcconfig: xcconfig)
    }
}

// MARK: - DefaultSettings

/// Specifies the default set of settings applied to all the projects and targets.
/// The default settings can be overridden via `Settings base: [String: String]`
/// and `Configuration settings: [String: String]`.
///
/// - all: Essential settings plus all the recommended settings (including extra warnings)
/// - essential: Only essential settings to make the projects compile (i.e. `TARGETED_DEVICE_FAMILY`)
public enum DefaultSettings: String, Codable {
    case recommended
    case essential
}

// MARK: - Settings

public struct Settings: Equatable, Codable {
    public let base: [String: String]
    public let configurations: [Configuration]
    public let defaultSettings: DefaultSettings

    /// Creates settings with the default `Debug` and `Release` configurations.
    ///
    /// - Parameters:
    ///   - base: Base build settings to use
    ///   - debug: The debug configuration
    ///   - release: The release configuration
    ///   - defaultSettings: The default settings to apply during generation
    ///
    /// - Note: To specify additional custom configurations, you can use the alternate initializer `init(base:configurations:defaultSettings:)`.
    /// - Note: The build configuration name and variants passed to the `debug:` and `release:` parameters are ignored and replaced with
    ///              default Debug and Release name and variants.
    ///
    /// - seealso: Configuration
    /// - seealso: DefaultSettings
    public init(base: [String: String] = [:],
                debug: Configuration? = nil,
                release: Configuration? = nil,
                defaultSettings: DefaultSettings = .recommended) {
        configurations = [
            .debug(settings: debug?.settings ?? [:], xcconfig: debug?.xcconfig),
            .release(settings: release?.settings ?? [:], xcconfig: release?.xcconfig),
        ]
        self.base = base
        self.defaultSettings = defaultSettings
    }

    /// Creates settings with any number of custom configurations.
    ///
    /// - Parameters:
    ///   - base: Base build settings to use
    ///   - configurations: A list of custom configurations to use
    ///   - defaultSettings: The default settings to apply during generation
    ///
    /// - Note: Configurations shouldn't be empty, please use the alternate initializer `init(base:debug:release:defaultSettings:)`
    ///              to leverage the default configurations if you don't have any custom configurations.
    /// - Note: Configurations used here need to have both a valid name and variant specified, names can't be empty.
    ///              Please use the appropriate `.debug(name:)` and `.release(name:)` Configuration helpers to create your custom configurations.
    ///
    /// - seealso: Configuration
    /// - seealso: DefaultSettings
    public init(base: [String: String] = [:],
                configurations: [Configuration],
                defaultSettings: DefaultSettings = .recommended) {
        self.base = base
        self.configurations = configurations
        self.defaultSettings = defaultSettings
    }
}
