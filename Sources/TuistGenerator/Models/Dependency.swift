import Basic
import Foundation

public struct Dependency: Equatable {

    let name: String?
    let type: String
    let target: String?
    let path: RelativePath?
    let publicHeaders: RelativePath?
    let swiftModuleMap: String?

    public init(name: String?,
                type: String,
                target: String?,
                path: RelativePath?,
                publicHeaders: RelativePath?,
                swiftModuleMap: String?) {
        self.name = name
        self.type = type
        self.target = target
        self.path = path
        self.publicHeaders = publicHeaders
        self.swiftModuleMap = swiftModuleMap
    }

    // MARK: - Equatable

    public static func == (lhs: Dependency, rhs: Dependency) -> Bool {
        return lhs.name == rhs.name &&
            lhs.type == rhs.type &&
            lhs.target == rhs.target &&
            lhs.path == rhs.path &&
            lhs.publicHeaders == rhs.publicHeaders &&
            lhs.swiftModuleMap == rhs.swiftModuleMap
    }
}
