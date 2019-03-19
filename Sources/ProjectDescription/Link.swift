import Foundation

public enum Link<T: Codable>: Codable {
    case value(_ value: T)
    case environment(_ value: EnvironmentIdentifier)

    enum CodingKeys: CodingKey {
        case value
        case environment
    }


    public var value: T? {
        switch self {
        case let .value(value):
            return value
        default:
            return nil
        }
    }

    // MARK: - Codable

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        do {
            let value =  try container.decode(T.self, forKey: .value)
            self = .value(value)
        } catch {
            let value =  try container.decode(EnvironmentIdentifier.self, forKey: .environment)
            self = .environment(value)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .value(let value):
            try container.encode(value, forKey: .value)
        case .environment(let value):
            try container.encode(value, forKey: .environment)
        }
    }
}
