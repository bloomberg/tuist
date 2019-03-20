import Foundation

// MARK: - Project

public typealias SettingsLink = Link<Settings?>?

public class Project: Codable {
    public let name: String
    public let targets: [Target]
    public let settings: SettingsLink

    public enum CodingKeys: String, CodingKey {
        case name
        case targets
        case settings
    }

    public init(name: String,
                settings: SettingsLink = nil,
                targets: [Target] = []) {
        self.name = name
        self.targets = targets
        self.settings = settings
        dumpIfNeeded(self)
    }
}
